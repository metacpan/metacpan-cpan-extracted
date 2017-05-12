#!perl -T

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Color::TupleEncode' ) || print "Bail out!";
}

my $tway = Color::TupleEncode->new();

$tway->set_tuple(1,2,3);
is(join(",",$tway->get_tuple),"1,2,3","set_tuple(1,2,3)");

$tway->set_tuple([4,5,6]);
is(join(",",$tway->get_tuple),"4,5,6","set_tuple(4,5,6)");

eval {
  $tway->set_tuple(1,undef,3);
};

like($@,qr/value at index .* is not defined/i,"set_tuple(1,undef,3)");

eval {
  $tway->set_tuple([1,undef,3]);
};

like($@,qr/value at index .* is not defined/i,"set_tuple(1,undef,3)");

eval {
  $tway->set_tuple({});
};

like($@,qr/list or array reference/i,"set_tuple(1,undef,3)");

eval {
  $tway->set_tuple(1..4);
};

like($@,qr/wrong number of values in tuple/i,"set_tuple(1..4)");

eval {
  $tway->set_tuple();
};

like($@,qr/wrong number of values in tuple/i,"set_tuple()");

eval {
  $tway->set_tuple([]);
};

like($@,qr/wrong number of values in tuple/i,"set([])");


eval {
  $tway->set_tuple([1],2,3);
};

like($@,qr/value at index .* cannot be a reference/i,"set([1],2,3)");

eval {
  $tway->set_tuple(1,2,[3]);
};

like($@,qr/value at index .* cannot be a reference/i,"set(1,2,[3])");

eval {
  $tway->set_tuple(1,2,\3);
};

like($@,qr/value at index .* cannot be a reference/i,"set(1,2,\\3)");
