#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Time::HiRes qw(time);
use Test::More tests    => 16;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent';
    use_ok 'AnyEvent::Tools', ':foreach';
}

{
    my $cv = condvar AnyEvent;
    my $count = 0;
    async_repeat 0, sub { $count++ }, sub { $cv->send };
    $cv->recv;

    ok $count == 0, "Repeat 0 times";
}


{
    my $cv = condvar AnyEvent;
    my $count = 0;
    async_repeat 0, sub { $count++ };
    my $timer_end;
    $timer_end = AE::timer 0.5, 0 => sub {
        undef $timer_end;
        $cv->send;
    };
    $cv->recv;
    ok $count == 0, "Repeat 0 times without endfucntion";
}

{
    my $cv = condvar AnyEvent;
    my $count = 0;
    async_repeat 10, sub { $count++ }, sub { $cv->send };
    $cv->recv;

   diag $count unless ok $count == 10, "Repeat 10 times";
}

{
    my $cv = condvar AnyEvent;
    my $count = 0;
    async_repeat 10, sub {
        $count++;
        my ($g, $no, $first, $last) = @_;
        $cv->send if $last;

    };
    $cv->recv;

    ok $count == 10, "Repeat 10 times without endfucntion";
}

{
    my $cv = condvar AnyEvent;
    my $count = 0;
    async_repeat 10, sub {
        my ($g, $no, $first, $last) = @_;
        my $timer;
        $timer = AE::timer 0.05, 0 => sub {
            undef $g;
            undef $timer;
            $count++;
            $cv->send if $last;
        };

    };
    $cv->recv;

    ok $count == 10,
        "Repeat 10 times with catching guards and without endfucntion";
}

{
    my %res;
    my $cv = condvar AnyEvent;
    my $count = 0;
    my $repeat_guard;
    $repeat_guard = async_repeat 10, sub {
        my ($g, $no, $first, $last) = @_;
        my $timer;
        my $time = time;
        $timer = AE::timer 0.05, 0 => sub {
            $res{$count} = {
                time       => time - $time,
                start_time => $time,
                no         => $count
            };

            $count++;
            undef $g;
            undef $timer;
            $cv->send if $last;
        };
    };

    $cv->recv;


    ok 9 == grep({ $res{$_}{start_time} - $res{$_ - 1}{start_time} > 0.045  }
        1 .. 9), "Hold guard test";

    ok 10 == grep({ $res{$_}{time} >= .045 } 0 .. 9),
        "All timers have done";

}

{
    my $cv = condvar AnyEvent;
    my $end_called = 0;
    my $count = 0;
    my $repeat_guard;
    $repeat_guard = async_repeat 15, sub {
        undef $repeat_guard if $count == 9;
        $count++;
    }, sub {
        $end_called = 1;
    };

    my $timer = AE::timer 0.5, 0 => sub { $cv->send };
    $cv->recv;

    ok $count == 10, "Main guard is undefined before local guard";
    ok $end_called == 0,
        "Finish callback won't be called if repeating is canceled";
}

{
    my $cv = condvar AnyEvent;
    my $count = 0;
    my $repeat_guard;
    $repeat_guard = async_repeat 15, sub {
        my ($g) = @_;
        undef $g;
        undef $repeat_guard if $count == 9;
        $count++;
    };

    my $timer = AE::timer 0.5, 0 => sub { $cv->send };
    $cv->recv;

    ok $count == 10, "Main guard is undefined after local guard";
}

{
    my $cv = condvar AnyEvent;
    my $repeat_guard;
    my $end_called = 0;
    $repeat_guard = async_repeat 15,
        sub {
            my ($g, $idx, $first, $last) = @_;
            undef $repeat_guard if $last;
            undef $g;
        },
        sub {
            $end_called = 1
        };

    my $timer = AE::timer 0.5, 0 => sub { $cv->send };
    $cv->recv;

    ok $end_called == 0, "Cancel repeating inside the last iteration";
}


{
    my $cv = condvar AnyEvent;
    my $count = 0;
    my $repeat_guard;
    $repeat_guard = async_repeat 15, sub {
        my ($g, $no, $first, $last) = @_;
        my $timer;
        my $time = time;
        $timer = AE::timer 0.05, 0 => sub {
            undef $repeat_guard if $count == 9;
            $count++;
            undef $g;
            undef $timer;

        };
    };

    my $timer = AE::timer 0.05 * 16, 0 => sub { $cv->send };
    $cv->recv;

    diag $count unless ok $count == 10,
                            "Cancel repeating with catching guards";
}

{
    my $cv = condvar AnyEvent;
    my $count = 0;
    my $repeat_guard;
    $repeat_guard = async_repeat 15, sub {
        my ($g, $no, $first, $last) = @_;
        my $timer;
        my $time = time;
        $timer = AE::timer 0.05, 0 => sub {
            undef $g;
            undef $timer;
            undef $repeat_guard if $count == 9;
            $count++;

        };
    };

    my $timer = AE::timer 0.05 * 16, 0 => sub { $cv->send };
    $cv->recv;


    diag $count unless  ok $count == 10,
                "Cancel repeating with catching guards, after freeing guard";
}


{
    my $cv = condvar AnyEvent;
    my %res;
    async_repeat 4,
        sub {
            my ($g, $no, $first, $last) = @_;
            my $timer;
            my $time = time;
            $res{$no}{start} = $time;

            $timer = AE::timer 0.05, 0 => sub {
                $res{$no}{finish} = time;
                $res{$no}{time} = $res{$no}{finish} - $time;
                undef $timer;
                undef $g;

            };
        },
        sub {
            $res{finish} = time;
            $cv->send;
        };

    $cv->recv;

    ok $res{finish} - $res{3}{start} >= 0.045,
        "Finish callback is called after last is done";
}
