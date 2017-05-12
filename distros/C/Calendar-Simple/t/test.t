use Test::More tests => 34;
use_ok('Calendar::Simple');

my @month = calendar(9, 2002);

is(@month, 5);
is(@{$month[0]}, 7);
is($month[0][0], 1);
ok(not defined $month[-1][-1]);
is($#{$month[-1]}, 6);

@month = calendar(2, 2009);
is(@month, 4);
is($month[0][0], 1);
is($month[3][6], 28);
ok(defined $month[-1][-1]);
is($#{$month[-1]}, 6);

@month = calendar(1, 2002);
ok(not defined $month[0][0]);
is($month[0][2], 1);
is($month[4][4], 31);
ok(not defined $month[4][6]);
ok(not defined $month[-1][-1]);
is($#{$month[-1]}, 6);

@month = calendar(1, 2002, 1);
ok(not defined $month[0][0]);
is($month[0][1], 1);
is($month[4][3], 31);
ok(not defined $month[4][4]);
ok(not defined $month[-1][-1]);
is($#{$month[-1]}, 6);

@month = calendar(2, 2004, 3);
ok(@month);

@month = calendar();
ok(@month);

eval { @month = calendar(-1) };
ok($@);

eval { @month = calendar(13) };
ok($@);

eval { @month = calendar(1, 2000, -1) };
ok($@);

eval { @month = calendar(1, 2000, 7) };
ok($@);

@month = calendar(2, 2000);
ok(@month);

@month = calendar(2, 2004);
ok(@month);

my $month = calendar();
is(ref $month, 'ARRAY');

SKIP: {
  eval { require DateTime };
  skip "DateTime not installed", 2, if $@ || $ENV{CAL_SIMPLE_NO_DT};
  @month = calendar(1,1500);
  ok(@month);

  @month = calendar(2, 2100);
  ok(@month);
}
