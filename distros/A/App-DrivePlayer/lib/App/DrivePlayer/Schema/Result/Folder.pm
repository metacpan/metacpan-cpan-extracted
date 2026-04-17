package App::DrivePlayer::Schema::Result::Folder;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('folders');

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
    parent_drive_id => {
        data_type   => 'text',
        is_nullable => 1,
    },
    path => {
        data_type   => 'text',
        is_nullable => 0,
    },
    scan_folder_id => {
        data_type      => 'integer',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( unique_drive_id => ['drive_id'] );

__PACKAGE__->belongs_to(
    scan_folder => 'App::DrivePlayer::Schema::Result::ScanFolder',
    'scan_folder_id',
);

__PACKAGE__->has_many(
    tracks => 'App::DrivePlayer::Schema::Result::Track',
    'folder_id',
    { cascade_delete => 1 },
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index( name => 'idx_folders_scan_folder', fields => ['scan_folder_id'] );
}

1;

__END__

=head1 NAME

App::DrivePlayer::Schema::Result::Folder - DBIx::Class result for the folders table

=head1 DESCRIPTION

Represents a Drive folder (root or subfolder) encountered during a scan.
Belongs to a L<App::DrivePlayer::Schema::Result::ScanFolder> and has many
L<App::DrivePlayer::Schema::Result::Track> children (cascade-deleted with the
folder).

Columns: C<id>, C<drive_id>, C<name>, C<parent_drive_id>, C<path>,
C<scan_folder_id>.

=cut
