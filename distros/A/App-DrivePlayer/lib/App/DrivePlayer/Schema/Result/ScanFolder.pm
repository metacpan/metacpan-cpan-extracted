package App::DrivePlayer::Schema::Result::ScanFolder;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('scan_folders');

__PACKAGE__->add_columns(
    id => {
        data_type         => 'integer',
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    drive_id => {
        data_type   => 'text',
        is_nullable => 0,
    },
    name => {
        data_type   => 'text',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( unique_drive_id => ['drive_id'] );

__PACKAGE__->has_many(
    folders => 'App::DrivePlayer::Schema::Result::Folder',
    'scan_folder_id',
    { cascade_delete => 1 },
);

1;

__END__

=head1 NAME

App::DrivePlayer::Schema::Result::ScanFolder - DBIx::Class result for the scan_folders table

=head1 DESCRIPTION

Represents a top-level Google Drive folder that the user has configured for
scanning.  Has many L<App::DrivePlayer::Schema::Result::Folder> children
(cascade-deleted when the scan folder is removed).

Columns: C<id>, C<drive_id>, C<name>.

=cut
