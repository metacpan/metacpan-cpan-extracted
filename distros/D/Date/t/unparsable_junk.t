use 5.012;
use warnings;
use Test::More;
use Test::Deep;
use lib 't/lib'; use MyTest;

tzset('Europe/Moscow');

my $a = date("unparsable_string");
ok($a->error);
is($a->epoch, 0);
is($a->iso, "1970-01-01 03:00:00");

$a = date("2017-07-HELLO");
ok($a->error);
is($a->epoch, 0);
is($a->iso, "1970-01-01 03:00:00");

done_testing();
