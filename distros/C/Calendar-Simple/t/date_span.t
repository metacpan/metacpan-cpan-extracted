use Test::More tests => 14;
use_ok('Calendar::Simple', 'date_span');

my @span = date_span(year  => 2006,
		     mon   => 10,
		     begin => 15,
		     end   => 28);

is(@span, 2);
is($span[0][0], 15);
is($span[1][6], 28);

@span = date_span(year => 2006,
                  mon  => 10,
                  begin => 17,
                  end   => 24);
is(@span, 2);
ok(!defined $span[0][0]);
is($span[0][2], 17);
ok(!defined $span[1][6]);
is($span[1][2], 24);

@span = date_span(year => 2006,
                  mon  => 10);

is(@span, 5);
is(defined $span[0][0], 1);
is($span[2][2], 17);
ok(!defined $span[-1][6]);
is($span[-1][2], 31);
