#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 8;
use Encode qw(decode encode);
use Time::HiRes qw(time);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent';
    use_ok 'AnyEvent::Tools', ':mutex';
}

{
    my $mutex = rw_mutex;
    my $cv = condvar AnyEvent;

    my $counter = 0;
    my $done_counter = 0;
    my $timer;

    $timer = AE::timer 0.13, 0 => sub { $cv->send };

    $mutex->rlock(sub {
        my ($g) = @_;
        my $t;
        my $mcounter = 0;

        $t = AE::timer 0.01, 0.01 => sub {
            $mcounter++;
            if ($mcounter++ >= 10) {
                undef $t;
                undef $g;
                $done_counter++;
                $cv->send if $done_counter == 2;
                return;
            }
            $counter++;
        };
    });

    $mutex->rlock(sub {
        my ($g) = @_;
        my $t;
        my $mcounter = 0;

        $t = AE::timer 0.01, 0.01 => sub {
            $mcounter++;
            if ($mcounter++ >= 10) {
                undef $t;
                undef $g;
                $done_counter++;
                $cv->send if $done_counter == 2;
                return;
            }
            $counter++;
        };
    });


    $cv->recv;

    ok $counter == 10, "Two rlock work properly";
}

{
    my $mutex = rw_mutex;
    my $cv = condvar AnyEvent;
    my %res;

    my $time = time;
    $mutex->rlock(sub {
        my ($g) = @_;
        $res{'first-start'} = time - $time;
        my $t;
        $t = AE::timer 0.3, 0 => sub {
            $res{'first-stop'} = time - $time;
            undef $g;
            undef $t;
        };
    });
    $mutex->rlock(sub {
        $res{'second'} = time - $time;
    });

    $mutex->wlock(sub {
        my ($g) = @_;
        $res{'third-start'} = time - $time;
        my $t;
        $t = AE::timer 0.2, 0 => sub {
            $res{'third-stop'} = time - $time;
            undef $g;
            undef $t;
        };
    });
    $mutex->rlock(sub {
        my ($g) = @_;
        $res{'fourth-start'} = time - $time;
        my $t;
        $t = AE::timer 0.2, 0 => sub {
            $res{'fourth-stop'} = time - $time;
            undef $g;
            undef $t;
            $cv->send;
        };
    });
    $mutex->rlock(sub {
        $res{'fifth'} = time - $time;
    });

    $cv->recv;


    ok abs($res{'first-start'} - $res{second}) < .001,
        "First and second started simultaneously";

    ok $res{'third-start'} > $res{'first-stop'},
        "Write lock was after all rlock were freed";
    ok $res{'fourth-start'} > $res{'third-stop'},
        "Read lock waited until write lock is done";
    ok abs($res{fifth} - $res{'fourth-start'}) < .001,
        "Waited rlocks sarted simultaneously";
}


{
    my $cv = condvar AnyEvent;
    my $mutex = rw_mutex;
    $mutex->rlock_limit(2);
    my @res;

    for my $step (1 .. 20) {
        $mutex->rlock(sub {
            my ($g) = @_;
            my $t;
            $t = AE::timer .1, 0, sub {
                push @res, time;
                undef $t;
                undef $g;

                $cv->send if $step == 20;
            };
        });
    }

    $cv->recv;

    my $ok = 1;
    for (my $i = 0; $i < @res - 2; $i += 2) {
        $ok = $res[$i + 2] - $res[$i] >= .095;
        last unless $ok;
    }

    ok $ok, "rlock_limit works fine";
}
