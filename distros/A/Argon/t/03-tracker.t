use strict;
use warnings;
use Carp;
use Sub::Override;
use Time::HiRes qw/sleep/;
use Test::More;

use_ok('Argon::Tracker') or BAIL_OUT;

my $tracker = new_ok('Argon::Tracker', [
    tracking => 4,
    workers  => 4,
]) or BAIL_OUT('cannot continue without Tracker');

ok(!defined $tracker->age('foo'), 'age (invalid msgid)');

my @overrides = (
    Sub::Override->new('Argon::Tracker::time', sub () { 100 }),
    Sub::Override->new('Argon::Tracker::get_pending', sub { 58 }),
);

for my $i (1 .. 4) {
    $tracker->start_request($i);
    ok($tracker->capacity == (4 - $i), "capacity ($i)");
    is($tracker->age($i), 42, "age ($i)");
}

$tracker->end_request($_) for (1 .. 4);

my $avg = $tracker->avg_proc_time;
is($avg, 42, 'avg_proc_time');

my $est = 0;
for my $i (1 .. 4) {
    $tracker->start_request($i);
    ok($tracker->est_proc_time >= $est, "est_proc_time ($i)");
    is($tracker->age($i), 42, "age ($i)");
    $est = $tracker->est_proc_time;
}

done_testing;
