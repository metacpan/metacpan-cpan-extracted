#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 9;
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
    my $mutex = mutex;

    my ($counter, $total) = (0, 0);

    my $cv = condvar AnyEvent;

    my ($timer1, $timer2, $timer3);
    $timer1 = AE::timer 0, 0.2 => sub {
        $total++;
        if ($mutex->is_locked) {
            $counter++;
        }
    };

    $timer2 = AE::timer 1, 0 => sub {
        $mutex->lock(sub {
            my ($g) = @_;
            undef $timer2;
            my $timer;
            $timer = AE::timer 2, 0 => sub {
                undef $g;
                undef $timer;
            };
        });
        return;
    };

    $timer3 = AE::timer 5, 0 => sub {
        $cv->send;
    };

    $cv->recv;

    ok $counter < 13 && $counter > 8,
        "Mutex was locked correct time ($counter/$total)";
}

{
    my $cv = condvar AnyEvent;
    my $mutex = mutex;
    my $idle;
    my %res;

    $mutex->lock(sub {
        my $start_time = time;
        my $mutex_guard = shift;
        my $timer;
        $timer = AE::timer 0.1, 0 => sub {
            $res{1} = { start => $start_time, stop => time};
            undef $timer;
            undef $mutex_guard;
        };
    });
    $mutex->lock(sub {
        my $start_time = time;
        my $mutex_guard = shift;
        my $timer;
        $timer = AE::timer 0.1, 0 => sub {
            $res{2} = { start => $start_time, stop => time};
            undef $timer;
            undef $mutex_guard;
        };
    });
    $mutex->lock(sub {
        my $start_time = time;
        my $mutex_guard = shift;
        my $timer;
        $timer = AE::timer 0.1, 0 => sub {
            $res{3} = { start => $start_time, stop => time};
            undef $timer;
            undef $mutex_guard;
        };
    });

    $idle = AE::timer 0, 0.05 => sub {
        return unless 3 == keys %res;
        undef $idle;
        $cv->send;
    };

    $cv->recv;

    ok abs($res{1}{start} - $res{2}{start}) > 0.09,
        "First and second processes followed sequentially";
    ok $res{1}{stop} < $res{2}{start},
        "Second process was started after first had finished";
    ok abs($res{2}{start} - $res{3}{start}) > 0.09,
        "Second and third processes followed sequentially";
    ok $res{2}{stop} < $res{3}{start},
        "Third process was started after second had finished";
}

{
    my $cv = condvar AnyEvent;
    my $error;

    my $mutex = mutex;
    my $counter = 0;

    $mutex->lock(sub {
        my ($guard) = @_;
        my $timer;
        $timer = AE::timer .1, 0 => sub {
            undef $guard;
            undef $timer;
            $counter++;
        };
    });

    my $mguard = $mutex->lock(sub {
        $error = 1;
    });

    $mutex->lock(sub {
        $counter++;
    });

    my $timer;
    $timer = AE::timer .05, 0 => sub {
        undef $timer;
        undef $mguard;
    };

    my $timer2 = AE::timer 0.5, 0 => sub {
        $cv->send;
    };

    $cv->recv;

    ok !$error, "Cancel lock request";
    ok $counter == 2, "All lock requests were handled";
}
