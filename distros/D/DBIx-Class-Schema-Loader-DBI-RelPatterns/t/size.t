use strict;
use warnings;
use Test::More;
use lib qw(t/lib);
use dbixcsl_relpat_common qw/make_schema/;

if ($DBIx::Class::Schema::Loader::VERSION < 0.07000) {
    plan skip_all => "DBIx::Class::Schema::Loader at least 0.07000 is required";
}

my $relpat_test_size_map = {
    'foos.barid'    => '5',
    'Bars.barid'    => '5',
    'foos.foonum'   => '8',
    $DBIx::Class::Schema::Loader::VERSION < 0.07003 ? (
        'Bars.foosnum'  => '9',
        'foos.fooreal'  => '10',
        'Bars.foosreal' => '10',
        'quuxs.id'      => '11',
    ) : (
        'Bars.foosnum'  => [8,4],
        'foos.fooreal'  => [10,2],
        'Bars.foosreal' => [10,2],
        'quuxs.id'      => [11,3],    
    ),
};

make_schema(
    loader_class => '::DBI::RelPatterns::Test',
    relpat_test_size_map => $relpat_test_size_map,
    check_statinfo => 1,
    rel_constraint => [
        # everything at once
        qr/(.*?)s?_?(?:id|int|real|num|ref)$/i => qr/(.*?)s?$/i,
        'foos.barid' => 'Bars.',
        '' => {type=>'similar'},
        'quuxs.id' => 'quuxs.quuxid',
    ],
    test_rels => [
        '?foos.quuxid' => 'quuxs.quuxid',
        'foos.barid' => 'Bars.barid',
        'Bars.quuxref' => 'quuxs.quuxid',
        '?Bars.foosint,foosreal' => 'foos.fooint,fooreal',
        '?quuxs.barID' => 'Bars.foosint', # Bars.barid has different size
        'quuxs.id' => 'quuxs.quuxid',
    ],
);

done_testing();
