package # hide from PAUSE 
    FrozenTest::Schema::Source;

use base 'DBIx::Class';

__PACKAGE__->load_components(qw/FrozenColumns Core/);
__PACKAGE__->table('test');
__PACKAGE__->add_columns(
    id   => {
        data_type         => 'int',
        is_nullable       => 0,
    },
    frozen => {
        data_type   => 'blob',
        is_nullable => 0,
    },
    dumped => {
        data_type   => 'blob',
        is_nullable => 0,
    },
);

__PACKAGE__->set_primary_key('id');

__PACKAGE__->add_frozen_columns(frozen => qw/a_frozen b_frozen c_frozen/);
__PACKAGE__->add_dumped_columns(dumped => qw/a_dumped b_dumped c_dumped/);

#Recursive
__PACKAGE__->add_frozen_columns(c_frozen  => qw/cc_frozen/);
__PACKAGE__->add_frozen_columns(cc_frozen => qw/ccc_frozen/);

__PACKAGE__->add_dumped_columns(c_dumped  => qw/cc_dumped/);
__PACKAGE__->add_dumped_columns(cc_dumped => qw/ccc_dumped/);

1;
