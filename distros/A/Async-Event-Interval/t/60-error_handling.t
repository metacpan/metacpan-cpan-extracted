use strict;
use warnings;

use lib 't/lib';
use TestHelper;
use IPC::Shareable;
use Test::More;

use Async::Event::Interval;

my $mod = 'Async::Event::Interval';

{
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

    my $waited = 0;
    until ($e->error || $waited >= 10) {
        select(undef, undef, undef, 0.1);
        $waited += 0.1;
    }

    cmp_ok $e->events->{$e->id}{runs}, '>=', 6, "events() has correct count of runs ok";
    cmp_ok $e->info->{runs}, '>=', 6, "...so does info()";
    cmp_ok $e->runs, '>=', 6, "...so does runs()";

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

    $waited = 0;
    until ($e->error || $waited >= 10) {
        select(undef, undef, undef, 0.1);
        $waited += 0.1;
    }

    cmp_ok $e->events->{$e->id}{runs}, '>=', 14, "events() has correct count of runs after restart ok";
    cmp_ok $e->info->{runs}, '>=', 14, "...so does info()";
    cmp_ok $e->runs, '>=', 14, "...so does runs()";

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
}