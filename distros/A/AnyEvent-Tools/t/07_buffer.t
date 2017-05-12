#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 25;
use Encode qw(decode encode);
use Time::HiRes qw(time);
use AnyEvent;

BEGIN {
    # Подготовка объекта тестирования для работы с utf8
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent::AggressiveIdle', 'aggressive_idle';
    use_ok 'AnyEvent::Tools', 'buffer';
}

{
    my @res;
    my $cv = condvar AnyEvent;
    my $number = 1;
    my $b = buffer
        size => 5,
        on_flush => sub {
            my ($g, $a) = @_;
            push @res, $a;
        };

    my $idle;
    $idle = aggressive_idle sub {
        $b->push($number++);
        if ($number > 100) {
            $b->flush;
            undef $idle;
            $cv->send;
        }
    };

    $cv->recv;

    ok @res == grep({@$_ == 5} @res), "Flush buffer after overflow";
}

{
    my @res;
    my $cv = condvar AnyEvent;
    my $number = 1;
    my $count = 0;
    my $b;
    my $idle;
    $b = buffer
        size => 5,
        on_flush => sub {
            my ($g, $a) = @_;
            if ($count++ == 3) {
                my $timer;
                $timer = AE::timer 0.0005, 0 => sub {
                    $b->unshift_back($a);
                    undef $g;
                    undef $timer;
                };
                return;
            }
            push @res, $a;
            if (@res == 5) {
                undef $idle;
                $cv->send;
            }
        };

    $idle = aggressive_idle sub {
        $b->push($number++);
    };

    $cv->recv;

    ok @res == grep({@$_ >= 5} @res), "Flush buffer after overflow";
    ok @{ $res[3] } > 5, "unshift_back works properly";
    my $i = 1;
    my $ok;
    for (map { @$_ } @res) {
        $ok = $_ == $i++;
        last unless $ok;
    }
#     note explain [ $i, \@res ];

    ok $ok, "Sequence order is right";
}

{
    my @res;
    my $cv = condvar AnyEvent;
    my $number = 1;
    my $count = 0;
    my $start_time = time;
    my $idle;
    my $b = buffer
        interval => 0.2,
        on_flush => sub {
            my ($g, $a) = @_;
            push @res, { time => time, obj => $a };

            return if $count++ < 3;
            undef $idle;
            $cv->send;
        };

    $idle = aggressive_idle sub {  $b->unshift($number++); };

    $cv->recv;

    ok @res == 4, "Flush buffer after overflow";
    my @time = (0.18, .38, .58, .78, .98);
    for my $i (0 .. 3) {
        my $delay = $res[$i]{time} - $start_time;
        my $count = @{ $res[$i]{obj} };
        ok $delay >= $time[$i], "$i flush was in time (count: $count)";
        ok $delay <  $time[$i + 1], "$i flush was in time (count: $count)";
        ok $count > 100, "A lot iterations were done";
        my $ok;
        for (0 .. $#{ $res[$i]{obj} } - 1) {
            $ok = $res[$i]{obj}[$_] > $res[$i]{obj}[$_ + 1];
            last unless $ok;
        }

        ok $ok, "$i sequence order is right (count: $count)";
    }
}

{
    my @res;
    my $cv = condvar AnyEvent;
    my $idle;

    my $count =  0;
    my $b = buffer
        unique_cb   => sub { $_[0][0] },
        interval    => 0.05,
        on_flush    => sub {
            push @res, $_[1];
            $count = 0;
            $cv->send if @res >= 100
        };

    $idle = aggressive_idle sub { $b->push([int rand 10, ++$count ]) };

    $cv->recv;

    ok !grep({ @$_ > 10 } @res), "Unique elements were extract";
    ok 10 < grep({ 0 < grep { $_->[1] > 10 } @$_ } @res), "A lot of pushes";
}
