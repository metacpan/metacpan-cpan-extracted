use strict;
use warnings;

use Async::Event::Interval;
use Data::Dumper;
use Test::More;

if (! $ENV{CI_TESTING}) {
    plan skip_all => "Not on a valid CI testing platform..."
}

my $mod = 'Async::Event::Interval';

tie my $num, 'IPC::Shareable', { destroy => 1 };

$num = 1;

my $e = $mod->new(
    0.1,
    sub {
        die("critical") if $num == 8;
        $num++;
    }
);

# Start

$e->start;

select(undef, undef, undef, 1);

is $e->events->{$e->id}{runs}, 8, "events() has proper count of runs ok";
is $e->info->{runs}, 8, "...so does info()";
is $e->runs, 8, "...so does runs()";

is $e->events->{$e->id}{errors}, 1, "events() has proper count of errors ok";
is $e->info->{errors}, 1, "...so does info()";
is $e->errors, 1, "...so does errors()";

like
    $e->events->{$e->id}{error_message},
    qr/critical/,
    "events() has proper error message ok";
like
    $e->info->{error_message},
    qr/critical/,
    "...so does info()";
like
    $e->error_message,
    qr/critical/,
    "...so does error_message";

is $e->status, 0, "status() is waiting on error ok";
is $e->error, 1, "error() is set on error ok";
is $e->waiting, 1, "waiting() is set on error ok";

# Restart

$num = 1;
$e->restart if $e->waiting;

select(undef, undef, undef, 1);

is $e->events->{$e->id}{runs}, 16, "events() has proper count of runs after restart ok";
is $e->info->{runs}, 16, "...so does info()";
is $e->runs, 16, "...so does runs()";

is $e->events->{$e->id}{errors}, 2, "events() has proper count of errors after restart ok";
is $e->info->{errors}, 2, "...so does info()";
is $e->errors, 2, "...so does errors()";

like
    $e->events->{$e->id}{error_message},
    qr/critical/,
    "events() has proper error message after restart ok";
like
    $e->info->{error_message},
    qr/critical/,
    "...so does info()";
like
    $e->error_message,
    qr/critical/,
    "...so does error_message";

is $e->status, 0, "status() is waiting on error after restart ok";
is $e->error, 1, "error() is set on error after restart ok";
is $e->waiting, 1, "waiting() is set on error after restart ok";

$e->stop;

print Dumper $e->events;

done_testing();
