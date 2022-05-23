#!perl

use strict;
use warnings;

use Test::More;
use Test::Deep;
use Test::Fatal;
require DateTime;
require JSON::MaybeXS;

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


my @this_hour = calculate_start_end({ show => 'this hour' });
cmp_deeply(\@this_hour, $two_integers, '"this hour" is also 2 integers');
cmp_ok($default_se[0], '<=', $this_hour[0], 'this hour starts no earlier than midnight gone');
cmp_ok($this_hour[1], '<=', $default_se[1], 'this hour ends no later than midnight next');
$duration = $this_hour[1] - $this_hour[0];
# Leap seconds!
cmp_ok($duration, '<=', 3602, 'duration is no than 3600 seconds');
# Negtive leap seconds‼
cmp_ok($duration, '>=', 3599, 'duration is at least 3599 seconds');

my $duration_sum = $duration;

my @last_hour = calculate_start_end({ show => 'last hour' });
cmp_deeply(\@last_hour, $two_integers, '"last hour" is also 2 integers');
is($last_hour[1], $this_hour[0], '"last hour" ends where "this hour" starts');
$duration = $last_hour[1] - $last_hour[0];
cmp_ok($duration, '<=', 3602, 'duration is no than 3600 seconds');
cmp_ok($duration, '>=', 3599, 'duration is at least 3599 seconds');

$duration_sum += $duration;

my @next_hour = calculate_start_end({ show => 'next hour' });
cmp_deeply(\@next_hour, $two_integers, '"next hour" is also 2 integers');
is($next_hour[0], $this_hour[1], '"next hour" starts where "this hour" end');
cmp_ok($duration, '<=', 3602, 'duration is no than 3600 seconds');
cmp_ok($duration, '>=', 3599, 'duration is at least 3599 seconds');

$duration_sum += $duration;

cmp_ok($duration_sum, '>=', 3600 * 3 - 1, 'at most 1 negative leap second');
cmp_ok($duration_sum, '<=', 3600 * 3 + 2, 'at most 2 leap seconds');

for (['this day', 'today'],
     ['next day', 'tomorrow'],
     ['last day', 'yesterday'],
 ) {
    my ($alias, $target) = @$_;

    cmp_deeply([calculate_start_end({ show => $alias })],
           [calculate_start_end({ show => $target })],
               "'$alias' is the same as '$target'");
}

for my $when (qw (last this next)) {
    my @minutes = calculate_start_end({ show => "$when minute" });
    cmp_deeply(\@minutes, $two_integers, '"$when minutes" is also 2 integers');
}

my @minutes = calculate_start_end({ show => 'last 5 minutes' });
cmp_deeply(\@minutes, $two_integers, '"last 5 minutes" is also 2 integers');
is($minutes[1], $nowish, 'last 5 minutes ends now');
$duration = $minutes[1] - $minutes[0];
cmp_ok($duration, '>=', 299, 'at most 1 leap second short');
cmp_ok($duration, '<=', 302, 'at most 2 leap seconds long');

my @hours = calculate_start_end({ show => 'next 11 hours' });
cmp_deeply(\@hours, $two_integers, '"next 11 hours" is also 2 integers');
is($hours[0], $nowish, 'next 3 hours starts now');
$duration = $hours[1] - $hours[0];
cmp_ok($duration, '>=', 3600 * 11 - 1, 'at most 1 negative leap second');
cmp_ok($duration, '<=', 3600 * 11 + 2, 'at most 2 leap seconds');

my @days = calculate_start_end({ show => 'last 3 days' });
cmp_deeply(\@days, $two_integers, '"last 3 days" is also 2 integers');
is($days[1], $nowish, 'last 3 days ends now');
$duration = $days[1] - $days[0];
cmp_ok($duration, '>=', 3600 * (22 + 24 + 24), 'at most 2 hours short');
cmp_ok($duration, '<=', 3600 * (26 + 24 + 24), 'at most 2 hours long');

my @weeks = calculate_start_end({ show => 'next 1 weeks' });
cmp_deeply(\@weeks, $two_integers, '"next 1 weeks" is also 2 integers');
is($weeks[0], $nowish, 'next 1 weeks starts now');
$duration = $weeks[1] - $weeks[0];
cmp_ok($duration, '>=', 3600 * 166, 'at most 2 hours short');
cmp_ok($duration, '<=', 3600 * 170, 'at most 2 hours long');

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

my $json = JSON::MaybeXS->new({ space_after => 1, canonical => 1, });

for ([qr/: Can't use --show with --from or --to\n\z/,
      { from => '+0', show => 'today' }],
     [qr/: Can't use --show with --from or --to\n\z/,
      { to => '+0', show => 'today' }],
     [qr/: Can't parse 'woof' for --from\n\z/,
      { from => 'woof' }],
     [qr/: Can't parse 'woof' for --to\n\z/,
      { to => 'woof' }],
     [qr/: Unknown time period 'woof' for --show\n\z/,
      { show => 'woof' }],
     [qr/: End 42 must be after start 54 \(--from=54 --to=42\)\n\z/,
      { from => 54, to => 42 }],
 ) {
    my ($want, $args) = @$_;
    my $desc = $json->encode($args);
    like(exception { calculate_start_end($args) }, $want, "exception for $desc");
}

for my $word (qw(last this next)) {
    like(exception { calculate_start_end({show => $word}) },
         qr/: Unknown time period '$word' for --show \(did you forget to escape the space after it\?\)\n\z/,
         "exception for --show $word");
}

done_testing();
