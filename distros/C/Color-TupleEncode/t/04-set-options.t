#!perl -T

use Test::More qw(no_plan);

BEGIN {
    use_ok( 'Color::TupleEncode' ) || print "Bail out!";
}

my $tway = Color::TupleEncode->new();

eval {
  $tway->set_options();
};

is($@,"","set_options()");

eval {
  $tway->set_options(-xxx=>1);
};

like($@,qr/does not support option/i,"set_options(-xxx=>1)");

is({$tway->get_options()}->{-method},"Color::TupleEncode::Baran","get_options()");

eval {
  $tway->set_options(-method=>"Color::TupleEncode::Bad");
};

like($@,qr/does not support/i,"method=>Color::TupleEncode::Bad");

