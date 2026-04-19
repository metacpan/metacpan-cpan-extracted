package App::DrivePlayer::GUI::SheetSync;

# Moo role: Google Sheet synchronisation.

use strict;
use warnings;
use utf8;
use Moo::Role;

use Glib qw( FALSE );
use Gtk3  '-init';

use App::DrivePlayer::SheetDB;

sub _sheet_db {
    my ($self) = @_;
    my $sid = $self->config->sheet_id() or do {
        $self->_show_error(
            "No spreadsheet configured.\n\n" .
            "Open File → Settings, enter or create a Spreadsheet ID."
        );
        return;
    };
    return unless $self->_init_api();
    return App::DrivePlayer::SheetDB->new(
        api            => $self->rest_api,
        spreadsheet_id => $sid,
    );
}

sub _clear_sheet_id {
    my ($self) = @_;
    $self->config->_data->{sheet_id} = '';
    $self->config->save();

    my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };
    $log->warn('Spreadsheet not found (deleted?); sheet ID cleared from config') if $log;
    return;
}

sub _auto_sync_to_sheet {
    my ($self) = @_;
    return unless $self->config->sheet_id();
    $self->_set_status('Auto-syncing to Sheet…');
    Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();
    my $sheet  = $self->_sheet_db() or return;
    my $counts = eval { $sheet->push_to_sheet($self->db) };
    if ($@) {
        if ($@ =~ /^SHEET_NOT_FOUND:/) {
            $self->_clear_sheet_id();
            $self->_set_status('Spreadsheet not found (deleted?); sheet ID cleared.');
        } else {
            $self->_set_status("Sheet sync failed: $@");
        }
    } else {
        $self->_set_status(
            "Sheet synced: $counts->{scan_folders} folders, $counts->{tracks} tracks."
        );
    }
    return;
}

sub _sync_with_sheet {
    my ($self) = @_;
    my $sheet = $self->_sheet_db() or return;
    $self->_set_status('Syncing with Sheet…');
    Gtk3::main_iteration_do(FALSE) while Gtk3::events_pending();

    my $drive   = $self->drive;
    my $summary = eval {
        $sheet->sync_with_db(
            $self->db,
            drive_exists => sub {
                my ($id) = @_;
                my $meta = $drive->file(id => $id)->get(fields => 'id,trashed');
                return $meta && !$meta->{trashed};
            },
        );
    };
    if ($@) {
        if ($@ =~ /^SHEET_NOT_FOUND:/) {
            $self->_clear_sheet_id();
            $self->_show_error("Spreadsheet not found (deleted?).\n\nThe sheet ID has been cleared. Use File → Settings to create or enter a new one.");
        } else {
            $self->_show_error("Sync with Sheet failed:\n$@");
        }
        $self->_set_status('Sync failed.');
        return;
    }

    $self->_set_status(sprintf(
        'Synced: %d tracks merged, %d added locally, %d added to sheet, %d removed from sheet.',
        $summary->{tracks_merged},
        $summary->{tracks_added_local},
        $summary->{tracks_added_sheet},
        $summary->{tracks_deleted_sheet},
    ));
    $self->_load_library();
    return;
}

sub _auto_sync_from_sheet_on_new_db {
    my ($self) = @_;

    my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };

    # Skip silently if OAuth credentials aren't configured on this device yet
    my $auth = $self->config->auth_config();
    return unless $auth->{client_id} && $auth->{client_secret};
    return unless -f ($auth->{token_file} // '');

    my $api = $self->_init_api() or return;

    my $sheet_id = $self->config->sheet_id();

    unless ($sheet_id) {
        # Search Drive for the spreadsheet by name
        my @found = eval {
            $self->drive->list(
                filter => "name='DrivePlayer Library' and mimeType='application/vnd.google-apps.spreadsheet' and trashed=false",
                params => { fields => 'files(id,name)', pageSize => 1 },
            );
        };
        if ($@) {
            $log->warn("New-device sheet restore: Drive search failed: $@") if $log;
            return;
        }
        unless (@found) {
            $log->info('New-device sheet restore: no DrivePlayer Library spreadsheet found') if $log;
            return;
        }

        $sheet_id = $found[0]{id};
        $self->config->_data->{sheet_id} = $sheet_id;
        $self->config->save();
        $log->info("New-device sheet restore: found spreadsheet $sheet_id") if $log;
    }

    my $sheet = App::DrivePlayer::SheetDB->new(
        api            => $api,
        spreadsheet_id => $sheet_id,
    );
    my $counts = eval { $sheet->pull_from_sheet($self->db) };
    if ($@) {
        if ($@ =~ /^SHEET_NOT_FOUND:/) {
            $self->_clear_sheet_id();
        } else {
            $log->warn("New-device sheet restore: pull_from_sheet failed: $@") if $log;
        }
    } else {
        $log->info("New-device sheet restore: pulled $counts->{scan_folders} folders, $counts->{tracks} tracks") if $log;
    }
    return;
}

sub _prune_removed_folders {
    my ($self) = @_;

    my $log = do { eval { require Log::Log4perl; Log::Log4perl->get_logger(__PACKAGE__) } };

    my @config_ids = map { $_->{id} } @{ $self->config->music_folders() };
    return unless @config_ids;   # no folders configured yet — nothing to prune

    my %keep = map { $_ => 1 } @config_ids;
    for my $sf ($self->db->all_scan_folders()) {
        next if $keep{ $sf->{drive_id} };
        $log->info("Pruning removed folder '$sf->{name}' from database") if $log;
        $self->db->delete_scan_folder($sf->{drive_id});
    }
    return;
}

1;

__END__

=head1 NAME

App::DrivePlayer::GUI::SheetSync - Role for Google Sheet synchronisation

=head1 DESCRIPTION

A L<Moo::Role> consumed by L<App::DrivePlayer::GUI> that handles syncing the
local library to and from a Google Sheets spreadsheet.

=cut
