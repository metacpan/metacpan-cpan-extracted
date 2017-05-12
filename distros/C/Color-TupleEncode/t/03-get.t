#!perl -T

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Color::TupleEncode' ) || print "Bail out!";
}

my $tway = Color::TupleEncode->new();

is($tway->get_tuple,undef,"new()->get_tuple");

$tway->set_tuple([1,2,3]);
is(join(",",$tway->get_tuple),"1,2,3","set_tuple([1,2,3])");
$tway = Color::TupleEncode->new(tuple=>[1,2,3]);
is(join(",",$tway->get_tuple),"1,2,3","new(tuple=>[1,2,3])");

$tway->set_tuple(1,2,3);
is(join(",",$tway->get_tuple),"1,2,3","set_tuple(1,2,3)");

