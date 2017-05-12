package # hide from PAUSE
    My::TestSchema::Author;
use warnings;
use strict;
use base qw/DBIx::Class/;
use File::Temp qw/tempdir/;

__PACKAGE__->load_components(qw/InflateColumn::FS Core/);
__PACKAGE__->table('author');
__PACKAGE__->add_columns(
    id => {
        data_type => 'INT',
        is_auto_increment => 1,
    },
    name => {
        data_type => 'VARCHAR',
        size => 60,
    },
    photo => {
        data_type => 'TEXT',
        is_nullable => 1,
        is_fs_column => 1,
        fs_column_path => tempdir(CLEANUP => 1),
    },
);
__PACKAGE__->set_primary_key(qw/id/);
__PACKAGE__->has_many(books => 'My::TestSchema::Book', 'author_id');

1;
