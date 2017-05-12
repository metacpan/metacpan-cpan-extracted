use Test::More qw(no_plan);

ok(!eval { 'foo'.undef }, 'fatal warnings on');
