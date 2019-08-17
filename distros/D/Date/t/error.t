use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

# OK
my $date = new Date("2010-01-01");
my $ok;
$ok = 1 if $date;
ok($ok);
ok($date);
is($date->error, E_OK);

# UNPARSABLE
$date = new Date("pizdets");
$ok = 0;
$ok = 1 if $date;
ok(!$ok);
ok(!$date);
is($date->error, E_UNPARSABLE);
ok($date->errstr);
is(int($date), 0);

done_testing();
