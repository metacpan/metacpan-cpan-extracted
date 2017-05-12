use Test::More tests => 33;
$ENV{CAL_SIMPLE_NO_DT} = 1;
use_ok('Calendar::Simple');
use Config;

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

SKIP: {
  skip 'Not a problem since perl 5.11.0', 1
    if $] >= 5.011;
  skip 'Not a problem on 64-bit systems', 1
    if defined $Config{use64bitint};

  eval { @month = calendar(2, 2100) };
  ok($@);
}

eval { @month = calendar(2, 1500) };
ok($@);

@month = calendar(2, 2004);
ok(@month);

my $month = calendar();
is(ref $month, 'ARRAY');

