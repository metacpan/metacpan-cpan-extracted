package App::DrivePlayer::Scanner;

use App::DrivePlayer::Setup;

my $FOLDER_MIME  = 'application/vnd.google-apps.folder';
my $DRIVE_FIELDS = 'files(id,name,mimeType,size,modifiedTime,parents,videoMediaMetadata)';

Readonly my $LARGE_DELETION_THRESHOLD => 10;

has drive => (
    is       => 'ro',
    isa      => HasMethods['list'],
    required => 1,
);

has db => (
    is       => 'ro',
    isa      => HasMethods['upsert_scan_folder', 'upsert_folder', 'upsert_track'],
    required => 1,
);

has on_progress => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has on_track_found => (
    is        => 'ro',
    isa       => CodeRef,
    predicate => 1,
);

has on_large_deletion => (
    is        => 'ro',
    isa       => Maybe[CodeRef],
    default   => sub { undef },
);

has _stop => (
    is      => 'rw',
    isa     => Bool,
    default => 0,
);

has _seen_track_ids  => ( is => 'rw', isa => HashRef, default => sub { {} } );
has _seen_folder_ids => ( is => 'rw', isa => HashRef, default => sub { {} } );

sub stop { $_[0]->_stop(1) }

sub scan_folder {
    my ($self, $drive_id, $name) = @_;

    $self->_stop(0);
    $self->_seen_track_ids({});
    $self->_seen_folder_ids({});

    my $scan_folder = $self->db->upsert_scan_folder($drive_id, $name);

    $self->_scan_dir(
        folder_drive_id => $drive_id,
        folder_name     => $name,
        parent_drive_id => undef,
        path            => $name,
        scan_folder_id  => $scan_folder->{id},
    );

    my ($removed_tracks, $removed_folders) = (0, 0);
    unless ($self->_stop) {
        my $pending = $self->db->count_unseen_tracks($scan_folder->{id}, $self->_seen_track_ids);
        my $confirmed = $pending <= $LARGE_DELETION_THRESHOLD
                     || !$self->on_large_deletion
                     || $self->on_large_deletion->($pending, $name);
        if ($confirmed) {
            $removed_tracks  = $self->db->remove_unseen_tracks($scan_folder->{id}, $self->_seen_track_ids);
            $removed_folders = $self->db->remove_unseen_folders($scan_folder->{id}, $self->_seen_folder_ids);
        }
    }

    return { removed_tracks => $removed_tracks, removed_folders => $removed_folders };
}

sub _progress {
    my ($self, $msg) = @_;
    $self->on_progress->($msg) if $self->has_on_progress;
}

sub _scan_dir {
    my ($self, %args) = @_;
    return if $self->_stop;

    my $drive_id       = $args{folder_drive_id};
    my $folder_name    = $args{folder_name};
    my $path           = $args{path};
    my $scan_folder_id = $args{scan_folder_id};

    $self->_progress("Scanning: $path");
    return if $self->_stop;

    $self->_seen_folder_ids->{$drive_id} = 1;

    my $folder = $self->db->upsert_folder(
        drive_id        => $drive_id,
        name            => $folder_name,
        parent_drive_id => $args{parent_drive_id},
        path            => $path,
        scan_folder_id  => $scan_folder_id,
    );

    my @items = eval {
        $self->drive->list(
            filter => "'$drive_id' in parents and trashed=false",
            params => { fields => $DRIVE_FIELDS, pageSize => 1000 },
        );
    };
    if ($@) {
        $self->_progress("Error scanning $path: $@");
        return;
    }

    my (@subfolders, @audio_files);
    for my $item (@items) {
        if ($item->{mimeType} eq $FOLDER_MIME) {
            push @subfolders, $item;
        } elsif ($item->{mimeType} =~ m{^audio/}i) {
            push @audio_files, $item;
        }
    }

    for my $file (@audio_files) {
        return if $self->_stop;
        $self->_store_track($file, $folder, $path);
    }

    for my $subfolder (@subfolders) {
        return if $self->_stop;
        $self->_scan_dir(
            folder_drive_id => $subfolder->{id},
            folder_name     => $subfolder->{name},
            parent_drive_id => $drive_id,
            path            => "$path/$subfolder->{name}",
            scan_folder_id  => $scan_folder_id,
        );
    }
}

sub _store_track {
    my ($self, $file, $folder, $folder_path) = @_;

    $self->_seen_track_ids->{$file->{id}} = 1;

    my ($title, $artist, $album, $track_num, $year) = _parse_filename($file->{name});

    # Infer artist/album from folder path depth: Root/Artist/Album/track
    my @parts = split m{/}, $folder_path;
    if (!$artist && @parts >= 3) {
        $artist = $parts[-2];
        $album  = $parts[-1];
    } elsif (!$album && @parts >= 2) {
        $album = $parts[-1];
    }

    # "YYYY-AlbumName" folder convention: strip the year prefix and use the
    # captured year as the track's year when one wasn't parsed from the file.
    if ($album && $album =~ s{
        ^
        ( (?: 19 | 20) \d{2} )   # 4-digit year, 19xx or 20xx
        -
    }{}x) {
        $year //= $1;
    }

    my $duration_ms;
    if (my $meta = $file->{videoMediaMetadata}) {
        $duration_ms = $meta->{durationMillis};
    }

    my %track = (
        drive_id      => $file->{id},
        title         => $title,
        artist        => $artist,
        album         => $album,
        track_number  => $track_num,
        year          => $year,
        duration_ms   => $duration_ms,
        size          => $file->{size},
        mime_type     => $file->{mimeType},
        modified_time => $file->{modifiedTime},
        folder_id     => $folder->{id},
        folder_path   => $folder_path,
    );

    $self->db->upsert_track(%track);
    $self->on_track_found->(\%track) if $self->has_on_track_found;
}

# Parse filename into (title, artist, album, track_number, year).
# Handles: "NN - Artist - Title", "Artist - Title", "NN - Title", "Title"
sub _parse_filename {
    my ($filename) = @_;
    (my $base = $filename) =~ s/\.[^.]+$//;

    my ($title, $artist, $album, $track_num, $year);

    # "YYYY-..." prefix: capture the year and strip it before running the
    # track-number patterns below (otherwise 2001 would match \d+ as track#).
    if ($base =~ s{
        ^
        ( (?: 19 | 20) \d{2} )   # 4-digit year, 19xx or 20xx
        -
    }{}x) {
        $year = $1;
    }

    if ($base =~ /^(\d+)[\s.\-]+(.+?)\s+[-–]\s+(.+)$/) {
        ($track_num, $artist, $title) = ($1 + 0, $2, $3);
    } elsif ($base =~ /^(\d+)[\s.\-]+(.+)$/) {
        ($track_num, $title) = ($1 + 0, $2);
    } elsif ($base =~ /^(.+?)\s+[-–]\s+(.+)$/) {
        ($artist, $title) = ($1, $2);
    } else {
        $title = $base;
    }

    if (!$year && $title && $title =~ s{
        \s*
        [ \( \[ ]                # opening paren or bracket
        ( (?: 19 | 20) \d{2} )   # 4-digit year
        [ \) \] ]                # closing paren or bracket
        \s*
        $
    }{}x) {
        $year = $1;
    }

    return ($title // $base, $artist, $album, $track_num, $year);
}

1;

__END__

=head1 NAME

App::DrivePlayer::Scanner - Recursively scan a Google Drive folder and store tracks

=head1 SYNOPSIS

  use App::DrivePlayer::Scanner;

  my $scanner = App::DrivePlayer::Scanner->new(
      drive          => $drive_api,       # Google::RestApi::DriveApi3
      db             => $db,              # App::DrivePlayer::DB
      on_progress    => sub { say $_[0] },
      on_track_found => sub { my $track = shift; ... },
  );

  $scanner->scan_folder($root_folder_id, 'My Music');

  # From within an on_progress callback:
  $scanner->stop;

=head1 DESCRIPTION

Walks a Google Drive folder hierarchy depth-first, recording every audio
file it finds into the DrivePlayer database.  Non-audio files and Google
Docs are silently ignored.

Metadata (title, artist, album, track number, year) is extracted from the
filename using common naming conventions, and supplemented by inferring
artist and album from the folder path when the filename alone is ambiguous.

Supported filename patterns:

  NN - Artist - Title.ext
  Artist - Title.ext          (en-dash also accepted)
  NN - Title.ext
  Title.ext

Year is extracted from a trailing C<(YYYY)> or C<[YYYY]> suffix.

A rescan of an existing folder replaces all previous data for that folder.

=head1 ATTRIBUTES

=head2 drive

  is: ro, required: 1

A L<Google::RestApi::DriveApi3> instance (or any object with a C<list>
method matching that interface).

=head2 db

  is: ro, required: 1

A L<App::DrivePlayer::DB> instance used to persist scan results.

=head2 on_progress

  is: ro, isa: CodeRef, optional

Called with a single string message as each folder is entered or when a
Drive API error occurs.  Calling L</stop> from within this callback will
prevent the current folder's Drive listing from being fetched.

=head2 on_track_found

  is: ro, isa: CodeRef, optional

Called with a track hashref each time an audio file is successfully stored.

=head1 METHODS

=head2 new

  my $scanner = App::DrivePlayer::Scanner->new(%args);

Constructor.  C<drive> and C<db> are required.

=head2 scan_folder

  $scanner->scan_folder($drive_folder_id, $folder_name);

Starts a recursive scan of the given Drive folder.  Clears any previously
stored data for that folder before scanning.  Blocks until the scan
completes or L</stop> is called.

=head2 stop

  $scanner->stop;

Signals the running scan to halt.  Safe to call from within an
C<on_progress> callback; the current folder's Drive listing will not be
fetched if stop is set before it is requested.

=cut
