package App::DrivePlayer::Schema::Result::Track;

use strict;
use warnings;
use base 'DBIx::Class::Core';

__PACKAGE__->table('tracks');

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
    title => {
        data_type   => 'text',
        is_nullable => 0,
    },
    artist => {
        data_type   => 'text',
        is_nullable => 1,
    },
    album => {
        data_type   => 'text',
        is_nullable => 1,
    },
    track_number => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    year => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    duration_ms => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    size => {
        data_type   => 'integer',
        is_nullable => 1,
    },
    mime_type => {
        data_type   => 'text',
        is_nullable => 0,
    },
    modified_time => {
        data_type   => 'text',
        is_nullable => 1,
    },
    folder_id => {
        data_type      => 'integer',
        is_nullable    => 1,
        is_foreign_key => 1,
    },
    folder_path => {
        data_type   => 'text',
        is_nullable => 1,
    },
    genre => {
        data_type   => 'text',
        is_nullable => 1,
    },
    comment => {
        data_type   => 'text',
        is_nullable => 1,
    },
    metadata_fetched => {
        data_type     => 'integer',
        is_nullable   => 0,
        default_value => 0,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint( unique_drive_id => ['drive_id'] );

__PACKAGE__->belongs_to(
    folder => 'App::DrivePlayer::Schema::Result::Folder',
    'folder_id',
);

sub sqlt_deploy_hook {
    my ($self, $sqlt_table) = @_;
    $sqlt_table->add_index( name => 'idx_tracks_artist', fields => ['artist'] );
    $sqlt_table->add_index( name => 'idx_tracks_album',  fields => ['album'] );
    $sqlt_table->add_index( name => 'idx_tracks_folder', fields => ['folder_id'] );
    $sqlt_table->add_index( name => 'idx_tracks_title',  fields => ['title'] );
}

1;

__END__

=head1 NAME

App::DrivePlayer::Schema::Result::Track - DBIx::Class result for the tracks table

=head1 DESCRIPTION

Represents a single audio file discovered during a Drive scan.  Belongs to
a L<App::DrivePlayer::Schema::Result::Folder>.

Columns: C<id>, C<drive_id>, C<title>, C<artist>, C<album>,
C<track_number>, C<year>, C<duration_ms>, C<size>, C<mime_type>,
C<modified_time>, C<folder_id>, C<folder_path>, C<genre>, C<comment>,
C<metadata_fetched>.

=cut
