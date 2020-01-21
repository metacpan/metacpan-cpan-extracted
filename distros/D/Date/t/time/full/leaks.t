use 5.012;
use warnings;
use Test::More;
use lib 't/lib'; use MyTest;

plan skip_all => 'set TEST_FULL=1 to enable leaks test' unless $ENV{TEST_FULL};
plan skip_all => 'BSD::Resource required to test for leaks' unless eval { require BSD::Resource; 1 };

my $measure = 200;
my $i = 0;

while (++$i < 100000) {
    tzset('Europe/Moscow');
    tzget('America/New_York');
    tzset('America/New_York');
}
continue {
    $measure = BSD::Resource::getrusage()->{"maxrss"} if $i == 10000;
}

my $leak = BSD::Resource::getrusage()->{"maxrss"} - $measure;
my $leak_ok = $leak < 100;
warn("LEAK DETECTED: ${leak}Kb") unless $leak_ok;
ok($leak_ok);

done_testing();
