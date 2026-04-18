package App::DrivePlayer::SheetDB;

use App::DrivePlayer::Setup;
use Google::RestApi::DriveApi3;
use Google::RestApi::SheetsApi4;

my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };

my %SHEET_PROPERTIES = (
    folders => {
        cols => [ qw( drive_id name ) ],
    },
    tracks => {
        cols => [ qw( drive_id title artist album track_number year duration_ms genre comment ) ],
    },
);

# ------------------------------------------------------------------
# Attributes
# ------------------------------------------------------------------

has api => (
    is       => 'ro',
    required => 1,
);

has spreadsheet_id => (
    is      => 'rw',
    default => sub { undef },
);

# ------------------------------------------------------------------
# Create
# ------------------------------------------------------------------

# Create a new spreadsheet and return its ID (also stored in $self).
# The default "Sheet1" is renamed to "folders"; folder worksheets
# are created on first push.
sub create {
    my ($self) = @_;
    my $ss = $self->_sheets_api->create_spreadsheet(title => 'DrivePlayer Library');
    $self->spreadsheet_id($ss->spreadsheet_id());

    my $ws0 = $ss->open_worksheet(id => 0);
    $ws0->ws_rename('folders')->submit_requests();

    return $self->spreadsheet_id;
}

# ------------------------------------------------------------------
# Push  (SQLite → Sheet)
# ------------------------------------------------------------------

# Write all scan folders and their tracks to the spreadsheet, merging with
# any existing sheet content so that:
#   - Local non-blank values overwrite the sheet.
#   - Local blank/undef values preserve whatever is currently on the sheet.
#   - Rows on the sheet whose drive_id is not present locally are kept intact
#     (they may belong to another device that has scanned different tracks).
# Returns { scan_folders => N, tracks => N } counting local records written.
sub push_to_sheet {
    my ($self, $db) = @_;
    my $ss = $self->_open();

    # --- Folders index: merge local + sheet, preserving sheet-only folders.
    my @scan_folders       = $db->all_scan_folders();
    my $sheet_folders      = $self->_read_worksheet($ss, 'folders');
    my %local_folder_by_id = map { $_->{drive_id} => $_ } @scan_folders;
    my %sheet_folder_by_id = map { $_->{drive_id} => $_ } @$sheet_folders;

    my @folder_ids   = _union_ids(\@scan_folders, $sheet_folders);
    my @folder_rows  = map {
        my $id = $_;
        [$id, _merge_field('name', $local_folder_by_id{$id}, $sheet_folder_by_id{$id})]
    } @folder_ids;
    $self->_write_worksheet($ss, 'folders', 'folders', \@folder_rows);

    # --- Per-folder track tabs: merge rows, preserve sheet-only drive_ids.
    my $cols         = $SHEET_PROPERTIES{tracks}{cols};
    my $total_tracks = 0;
    for my $sf (@scan_folders) {
        my $tab_name        = _ws_name($sf->{name});
        my @tracks          = $db->tracks_by_scan_folder($sf->{id});
        my $sheet_rows      = $self->_read_worksheet($ss, $tab_name);
        my %local_by_id     = map { $_->{drive_id} => $_ } @tracks;
        my %sheet_by_id     = map { $_->{drive_id} => $_ } @$sheet_rows;

        my @drive_ids = _union_ids(\@tracks, $sheet_rows);
        my @rows = map {
            my $id    = $_;
            my $local = $local_by_id{$id};
            my $sheet = $sheet_by_id{$id};
            [map { _merge_field($_, $local, $sheet) } @$cols];
        } @drive_ids;

        $self->_write_worksheet($ss, $tab_name, 'tracks', \@rows);
        $total_tracks += scalar @tracks;
    }

    return { scan_folders => scalar @scan_folders, tracks => $total_tracks };
}

# Return drive_ids from both lists in order (local first), with no duplicates.
sub _union_ids {
    my ($local, $sheet) = @_;
    my %seen;
    return grep { length $_ && !$seen{$_}++ }
        (map { $_->{drive_id} } @$local),
        (map { $_->{drive_id} } @$sheet);
}

# Return the local value for $field if it's defined and non-empty, otherwise
# fall back to the sheet value (or '' if neither side has it).
sub _merge_field {
    my ($field, $local, $sheet) = @_;
    my $lv = $local ? $local->{$field} : undef;
    return $lv if defined $lv && $lv ne '';
    my $sv = $sheet ? $sheet->{$field} : undef;
    return defined $sv ? $sv : '';
}

# ------------------------------------------------------------------
# Pull  (Sheet → SQLite)
# ------------------------------------------------------------------

# Read the spreadsheet and apply it to the local SQLite DB.
# Scan folders are upserted; track metadata is only applied to tracks
# that already exist in SQLite (i.e. have been scanned locally).
# Returns { scan_folders => N, tracks => N }.
sub pull_from_sheet {
    my ($self, $db) = @_;
    my $ss = $self->_open();

    # Pull folders index
    my $folder_rows  = $self->_read_worksheet($ss, 'folders');
    my $folder_count = 0;
    for my $row (@$folder_rows) {
        next unless $row->{drive_id} && $row->{name};
        $db->upsert_scan_folder($row->{drive_id}, $row->{name});
        $folder_count++;
    }

    # Pull tracks from each folder worksheet
    my $track_count = 0;
    for my $folder_row (@$folder_rows) {
        next unless $folder_row->{drive_id} && $folder_row->{name};

        # Ensure a root folder record exists for this scan folder so that
        # skeleton tracks have a valid folder_id and tracks_by_scan_folder
        # can find them before a Drive scan has been run.
        my $sf = $db->get_scan_folder_by_drive_id($folder_row->{drive_id});
        next unless $sf;
        my $folder = $db->upsert_folder(
            drive_id        => $folder_row->{drive_id},
            name            => $folder_row->{name},
            parent_drive_id => undef,
            path            => $folder_row->{name},
            scan_folder_id  => $sf->{id},
        );

        my $rows = $self->_read_worksheet($ss, _ws_name($folder_row->{name}));
        for my $row (@$rows) {
            next unless $row->{drive_id};
            my %meta = map  { $_ => $row->{$_} }
                       grep { defined $row->{$_} && $row->{$_} ne '' }
                       $SHEET_PROPERTIES{tracks}->{cols}->@*;
            my $track = $db->get_track_by_drive_id($row->{drive_id});
            if ($track) {
                $db->update_track_metadata($track->{id}, %meta);
            } else {
                $db->upsert_track_from_metadata(%meta, folder_id => $folder->{id});
            }
            $track_count++;
        }
    }

    return { scan_folders => $folder_count, tracks => $track_count };
}

# ------------------------------------------------------------------
# Private helpers
# ------------------------------------------------------------------

sub _sheets_api {
    my ($self) = @_;
    return Google::RestApi::SheetsApi4->new(api => $self->api);
}

sub _open {
    my ($self) = @_;
    die "No spreadsheet_id configured\n" unless $self->spreadsheet_id;

    # Use Drive API to verify the file exists and is not trashed before
    # opening via Sheets API (which happily operates on trashed files).
    my $drive = Google::RestApi::DriveApi3->new(api => $self->api);
    my $meta  = eval { $drive->file(id => $self->spreadsheet_id)->get(fields => 'id,trashed') };
    if ($@) {
        die "SHEET_NOT_FOUND: $@" if $@ =~ /404|not.?found/i;
        die $@;
    }
    die "SHEET_NOT_FOUND: spreadsheet has been trashed\n" if $meta->{trashed};

    return $self->_sheets_api->open_spreadsheet(id => $self->spreadsheet_id);
}

# Write a header row then all data rows to a named worksheet (full replace).
sub _write_worksheet {
    my ($self, $ss, $name, $properties, $rows) = @_;
    my $cols = $SHEET_PROPERTIES{$properties}{cols};

    my $n  = scalar @$rows;
    my $ws = $self->_ensure_worksheet($ss, $name, $n + 1);
    $ws->clear_values()->submit_requests();
    $ws->row(1, $cols);
    $ws->rows([2 .. $n + 1], $rows) if $n;
}

# Read a worksheet and return arrayref of hashrefs keyed by header row.
# Returns [] if the worksheet doesn't exist or is empty.
sub _read_worksheet {
    my ($self, $ss, $name) = @_;
    my $ws = eval { $ss->open_worksheet(name => $name) };
    if ($@) { $log->warn("Could not open worksheet '$name': $@") if $log; return [] }
    return [] unless $ws;

    $ws->enable_header_row();
    my $cols = $ws->tie_cols;
    tied(%$cols)->values();      # prefetch the columns.

    my @result;
    my $i = tied(%$cols)->iterator(from => 0);
    while (my $row = $i->iterate()) {
        tied(%$row)->values();
        last unless $row->{drive_id};
        push(@result, $row);
    }
    return \@result;
}

# Open a worksheet by name, creating it with enough rows if absent, or
# expand it if it already exists but the grid is too small for the data.
sub _ensure_worksheet {
    my ($self, $ss, $name, $needed_rows) = @_;
    # Default Google Sheets grid is 1000 rows; honour that for small data.
    $needed_rows = 1000 if !$needed_rows || $needed_rows < 1000;

    # Try to create; silently ignore the error if it already exists.
    # If the API call fails (e.g. sheet already exists), the failed addSheet
    # request is left in $ss's internal batch queue.  Clear it so that
    # subsequent submit_requests() calls don't re-send the stale request.
    eval { $ss->add_worksheet(
        name            => $name,
        grid_properties => { rows => $needed_rows },
    )->submit_requests() };
    delete $ss->{requests} if $@;

    my $ws = $ss->open_worksheet(name => $name);

    # Expand an existing sheet that may have been created with fewer rows.
    if ($needed_rows > 1000) {
        $ws->update_worksheet_properties(
            properties => { gridProperties => { rowCount => $needed_rows } },
            fields     => 'gridProperties.rowCount',
        )->submit_requests();
    }

    return $ws;
}

# Sanitise a folder name for use as a worksheet tab name.
# Google Sheets forbids [ ] * / \ ? : and limits names to 100 chars.
sub _ws_name {
    my ($name) = @_;
    $name =~ s{[\[\]*\/\\?:]}{}g;
    $name =~ s/^\s+|\s+$//g;
    $name = 'Folder' unless length $name;
    return substr($name, 0, 100);
}

1;

__END__

=head1 NAME

App::DrivePlayer::SheetDB - Sync the DrivePlayer library to/from a Google Sheet

=head1 SYNOPSIS

  use App::DrivePlayer::SheetDB;

  my $sheet = App::DrivePlayer::SheetDB->new(
      api            => $google_rest_api,
      spreadsheet_id => $id,             # omit when calling create()
  );

  my $id     = $sheet->create();             # create spreadsheet, returns ID
  my $counts = $sheet->push_to_sheet($db);  # { scan_folders => N, tracks => N }
  my $counts = $sheet->pull_from_sheet($db);

=head1 DESCRIPTION

Maintains a Google Spreadsheet with one worksheet per scan folder, plus a
C<folders> index tab:

=over 4

=item folders

C<drive_id> and C<name> for every top-level folder in the library.

=item One tab per folder (named after the folder)

Track metadata columns: C<drive_id title artist album track_number year
duration_ms genre comment>.  Structural fields (folder_id, etc.)
are re-derived from Drive scanning and are not stored in the sheet.

=back

The local SQLite database remains the working store for all runtime queries.
The Sheet is a portable sync target accessible from any device with Drive access.

=head1 NEW DEVICE WORKFLOW

  1. File -> Sync from Sheet   # pulls scan_folders into SQLite
  2. Library -> Sync           # discovers audio files on Drive
  3. File -> Sync from Sheet   # applies saved metadata to the scanned tracks

=head1 METHODS

=head2 new(%args)

C<api> (L<Google::RestApi> instance) is required.
C<spreadsheet_id> is optional (omit before calling C<create()>).

=head2 create()

Creates a new "DrivePlayer Library" spreadsheet with a C<folders> tab.
Returns and stores the new spreadsheet ID.

=head2 push_to_sheet($db)

Writes the C<folders> index and one worksheet of track metadata per folder.
The existing sheet content is merged with the local DB: local non-blank
values overwrite the sheet, local blanks preserve whatever is on the sheet,
and rows whose C<drive_id> is not known locally are kept intact (so a
device that has only scanned a subset of the library does not wipe data
pushed from another device).

=head2 pull_from_sheet($db)

Upserts scan folders into SQLite and applies track metadata to any tracks
already present (keyed by C<drive_id>).  Tracks not yet scanned locally
are silently skipped.

=cut
