use Action::Retry;

use strict;
use warnings;

use Test::More;

use Time::HiRes qw(gettimeofday usleep);

sub now {
    my ($s, $m) = gettimeofday;
    my $now = $s * 1000 + int($m / 1000);
}

my $var = 0;
# cosntant 10 millisecond sleep
my $action = Action::Retry->new(
    attempt_code => sub { $var++; die "plop" },
    non_blocking => 1,
    strategy => { Linear => { initial_sleep_time => 100,
                              multiplicator => 1,
                            } },
);

$action->run();
$action->run();
$action->run();
is($var, 1);
usleep 201 * 1000;
$action->run();
is($var, 2);

done_testing;
