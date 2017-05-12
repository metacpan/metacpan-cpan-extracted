#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 6;
use Encode qw(decode encode);


BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

#     use_ok 'AnyEvent::Impl::EV';
    use_ok 'AnyEvent';
    use_ok 'AnyEvent::AggressiveIdle';
}


{
    my $cv = condvar AnyEvent;
    my ($common_counter, $aggressive_counter) = (0, 0);

    my $common_idle;
    my $aggressive_idle;
    my $timer;

    $common_idle = AE::idle sub { $common_counter++ };
    $aggressive_idle = aggressive_idle { $aggressive_counter++ };
    $timer = AE::timer 0.5, 0 => sub { $cv->send };

    $cv->recv;

    diag explain [ $aggressive_counter, $common_counter ]
        unless ok $aggressive_counter > $common_counter,
            "aggressive_idle works fine";
    diag explain [ $aggressive_counter, $common_counter ]
        unless ok $common_counter < 3, "aggressive_idle blocks AE::idle";
}
{
    my $cv = condvar AnyEvent;
    my $counter = 0;
    my $counter2 = 0;
    my $idle;
    $idle = aggressive_idle { undef $idle if ++$counter >= 1000 };

    my $t0 = AE::timer 0.5, 0 => sub {
        aggressive_idle { ++$counter2 };
        return;
    };
    my $timer = AE::timer 1, 0 => sub { $cv->send };
    $cv->recv;

    diag $counter unless ok $counter == 1000, "Breaking idle process";
    diag explain [ $counter2, $counter ]
        unless ok $counter2 > $counter, "Breaknig inside idle process";
}
