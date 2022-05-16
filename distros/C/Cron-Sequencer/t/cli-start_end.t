#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
require DateTime;

use Cron::Sequencer::CLI qw(calculate_start_end);

my $nowish = time;

{
    no warnings 'redefine';
    *DateTime::_core_time = sub { return $nowish };
}

my $two_integers = [re(qr/\A[1-9][0-9]*\z/), re(qr/\A[1-9][0-9]*\z/)];

my @default_se = calculate_start_end({});

cmp_deeply(\@default_se, $two_integers, 'calculate_start_end returns 2 integers');

cmp_ok($default_se[0], '<=', $nowish, 'start time is no later than now');
cmp_ok($nowish, '<=', $default_se[1], 'end time is no earlier than now');
my $duration = $default_se[1] - $default_se[0];
cmp_ok($duration, '>=', 22 * 3600, 'duration is at least 22 hours');
cmp_ok($duration, '<=', 26 * 3600, 'duration is  no more than 26 hours');

my @today = calculate_start_end({ show => 'today' });

cmp_deeply(\@today, \@default_se, '"today" is the default from calculate_start_end');

my @yesterday = calculate_start_end({ show => 'yesterday' });
cmp_deeply(\@yesterday, $two_integers, '"yesterday" is also 2 integers');

is($yesterday[1], $today[0], '"yesterday" ends where "today" starts');
$duration = $yesterday[1] - $yesterday[0];
cmp_ok($duration, '>=', 22 * 3600, '"yesterday" duration is at least 22 hours');
cmp_ok($duration, '<=', 26 * 3600, '"yesterday" duration is  no more than 26 hours');

my @tomorrow = calculate_start_end({ show => 'tomorrow' });
cmp_deeply(\@tomorrow, $two_integers, '"tomorrow" is also 2 integers');

is($tomorrow[0], $today[1], '"tomorrow" starts where "today" ends');
$duration = $tomorrow[1] - $tomorrow[0];
cmp_ok($duration, '>=', 22 * 3600, '"tomorrow" duration is at least 22 hours');
cmp_ok($duration, '<=', 26 * 3600, '"tomorrow" duration is  no more than 26 hours');

my @this_week = calculate_start_end({ show => 'this week' });
cmp_deeply(\@this_week, $two_integers, '"this week" is also 2 integers');
cmp_ok($this_week[0], '<=', $default_se[0], 'this week starts no later than midnight gone');
cmp_ok($default_se[1], '<=', $this_week[1], 'this week ends no later than midnight next');
$duration = $this_week[1] - $this_week[0];
cmp_ok($duration, '>=', 166 * 3600, 'duration is at least 166 hours');
cmp_ok($duration, '<=', 170 * 3600, 'duration is  no more than 170 hours');

my @last_week = calculate_start_end({ show => 'last week' });
cmp_deeply(\@last_week, $two_integers, '"last week" is also 2 integers');
is($last_week[1], $this_week[0], '"last week" ends where "this week" starts');
$duration = $last_week[1] - $last_week[0];
cmp_ok($duration, '>=', 166 * 3600, 'duration is at least 166 hours');
cmp_ok($duration, '<=', 170 * 3600, 'duration is  no more than 170 hours');

my @next_week = calculate_start_end({ show => 'next week' });
cmp_deeply(\@next_week, $two_integers, '"next week" is also 2 integers');
is($next_week[0], $this_week[1], '"next week" starts where "this week" end');
$duration = $next_week[1] - $next_week[0];
cmp_ok($duration, '>=', 166 * 3600, 'duration is at least 166 hours');
cmp_ok($duration, '<=', 170 * 3600, 'duration is  no more than 170 hours');

# Let's arrive at midnight via a slightly different route, which doesn't
# assume the redefinition of _core_time worked.
my $midnight
    = DateTime->from_epoch(epoch => $nowish)->truncate(to => 'day')->epoch();

my $midnight_p5 = $midnight + 5;
my $midnight_p10 = $midnight + 10;

for (['{from => 42}', [42, 3642]],
     ['{from => 42, to => 54}', [42, 54]],
     ['{from => 42, to => "+12"}', [42, 54]],

     ['{from => "+0"}', [$midnight, $midnight + 3600]],
     ['{from => "-0"}', [$midnight, $midnight + 3600]],
     ['{from => "+5"}', [$midnight + 5, $midnight + 3605]],
     ['{from => "-5"}', [$midnight - 5, $midnight + 3595]],

     ['{to => "+5"}', [$midnight, $midnight + 5]],
     ['{to => $midnight_p5}', [$midnight, $midnight + 5]],

     ['{from => "+0", to => "+5"}', [$midnight, $midnight + 5]],
     ['{from => "+0", to => $midnight_p5}', [$midnight, $midnight + 5]],

     ['{from => "-5", to => "+5"}', [$midnight - 5, $midnight]],
     ['{from => "-5", to => $midnight_p5}', [$midnight - 5, $midnight + 5]],
 ) {
    my ($raw, $want) = @$_;
    my $input = eval $raw;
    # These are not going to get forgiven:
    is($@, "")
        or BAIL_OUT("The author left a syntax error in the test source '$raw'");
    is(ref $input, "HASH")
        or BAIL_OUT("The author's test source '$raw' is not a HASH reference");

    cmp_deeply([calculate_start_end($input)], $want, "calculate_start_end($raw)");
}

done_testing();
