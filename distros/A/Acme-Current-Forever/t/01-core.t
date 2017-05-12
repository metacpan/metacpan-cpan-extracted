use Test::More qw(no_plan);
BEGIN { use_ok('Acme::Current'); }
my @now = gmtime;
is($Acme::Current::YEAR, $now[5]+1900, 'year');
is($Acme::Current::MONTH, $now[4]+1, 'month');
is($Acme::Current::DAY, $now[3], 'day');
