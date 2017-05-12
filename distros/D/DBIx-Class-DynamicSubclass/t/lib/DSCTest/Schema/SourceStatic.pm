package # hide from PAUSE
    DSCTest::Schema::SourceStatic;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/DynamicSubclass Core/);
__PACKAGE__->table('test');
__PACKAGE__->add_columns(
    id   => {
        data_type   => 'int',
        is_nullable => 0,
    },
    type => {
        data_type   => 'smallint',
        is_nullable => 1,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->typecast_map(type => {
    1 => 'DSCTest::Schema::SourceStatic::Type1',
    2 => 'DSCTest::Schema::SourceStatic::Type2',
});

1;
