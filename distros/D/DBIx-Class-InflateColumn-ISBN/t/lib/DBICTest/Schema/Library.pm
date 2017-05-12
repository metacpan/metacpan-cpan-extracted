package # hide from PAUSE
    DBICTest::Schema::Library;

use base qw/DBIx::Class/;

__PACKAGE__->load_components(qw/InflateColumn::ISBN Core/);
__PACKAGE__->table('library');

__PACKAGE__->add_columns(
    id => {
        data_type   => 'integer',
        is_nullable => 0,
    },
    book => {
        data_type   => 'text',
        is_nullable => 0,
    },
    isbn => {
        data_type   => 'varchar',
        size        => 13,
        is_nullable => 0,
        is_isbn     => 1,
    },
    full_isbn => {
        data_type   => 'varchar',
        size        => 16,
        is_nullable => 1,
        is_isbn     => 1,
        as_string   => 1,
    },
);

__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(isbn => [ qw/isbn/ ]);

1;
