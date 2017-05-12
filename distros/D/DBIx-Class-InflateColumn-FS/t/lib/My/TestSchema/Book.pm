package # hide from PAUSE
    My::TestSchema::Book;
use warnings;
use strict;
use base qw/DBIx::Class/;
use File::Temp qw/tempdir/;

__PACKAGE__->load_components(qw/InflateColumn::FS Core/);
__PACKAGE__->table('book');
__PACKAGE__->add_columns(
    id => {
        data_type => 'INT',
        is_auto_increment => 1,
    },
    author_id => {
        data_type      => 'INT',
        is_foreign_key => 1,
        is_nullable    => 1,
    },
    name => {
        data_type => 'VARCHAR',
        size => 60,
    },
    cover_image => {
        data_type => 'TEXT',
        is_nullable => 1,
        is_fs_column => 1,
        fs_column_path => tempdir(CLEANUP => 1),
    },
    cover_image_2 => {
        data_type => 'TEXT',
        is_nullable => 1,
        is_fs_column => 1,
        fs_column_path => tempdir(CLEANUP => 1),
        fs_new_on_update => 1
    },
);
__PACKAGE__->set_primary_key(qw/id/);
__PACKAGE__->belongs_to(author => 'My::TestSchema::Author', 'author_id');

1;
