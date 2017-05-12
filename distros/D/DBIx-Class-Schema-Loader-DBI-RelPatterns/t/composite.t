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
        ['Bars', qr/^foosnum$/i] => ['quuxs', qr/^foo_num$/],
        'Bars.foosreal' => ['quuxs', qr/^foo_real$/],
        ['foos', qr/(.*?)s?(int|real|num)$/] => ['Bars', qr/(.*?)s?(int|real|num)$/i],
    ],
    test_rels => [
        'Bars.quuxref' => 'quuxs.quuxid', # foreign key
        'Bars.foosnum,foosreal' => 'quuxs.foo_num,foo_real',
        '?foos.fooint,foonum,fooreal' => 'Bars.foosint,foosnum,foosreal',
    ],
);

done_testing();
