use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

if ($DBIx::Class::Schema::Loader::VERSION < 0.06000) {
    # older versions do not handle multiple foo_num unique indexes well
    plan skip_all => "DBIx::Class::Schema::Loader at least 0.06000 is required";
}

make_schema(
    loader_class => 1,
    check_statinfo => 1,
    rel_constraint => [
        # all of these trigger "matched but not leftmost"
        ['quuxs', qr/^foo_num$/] => ['foos', qr/^foonum$/],
        ['foos', qr/^foonum$/] => ['quuxs', qr/^foo_num$/],
        ['foos', qr/^fooreal$/] => ['quuxs', qr/^foo_real$/],
        # but not the following ones
        {index=>'optional'} => {},
        ['Bars', qr/^foosnum$/i] => ['quuxs', qr/^foo_num$/],
        {index=>'any'} => {},
        ['Bars', qr/^foosreal$/i] => ['quuxs', qr/^foo_real$/],
    ],
    test_rels => [
        '?Bars.foosnum,foosreal' => 'quuxs.foo_num,foo_real',
        '#Bars.foosnum' => 'quuxs.foo_num',
        'Bars.quuxref' => 'quuxs.quuxid', # foreign key
    ],
);

done_testing();
