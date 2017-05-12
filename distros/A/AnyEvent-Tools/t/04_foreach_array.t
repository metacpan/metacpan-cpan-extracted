#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 23;
use Encode qw(decode encode);
use Time::HiRes qw(time);


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

    async_for [], sub { $count++ }, sub { $cv->send };
    $cv->recv;

    ok $count == 0, "async_for with empty array";
}

{
    my $cv = condvar AnyEvent;
    my $count = 0;

    async_for [], sub { $count++ };
    my $t = AE::timer 0.5, 0 => sub { $cv->send };
    $cv->recv;

    ok $count == 0, "async_for with empty array, without endfucntion";
}

{
    my $cv = condvar AnyEvent;
    my %res;
    my $number = 0;

    async_for [ 0 .. 9 ],
        sub {
            my ($g, $value, $index, $first, $last) = @_;
            $res{$index} = {
                value   => $value,
                first   => $first,
                last    => $last,
                called  => $number++,
                time    => time,
            };
        },
        sub {
            $cv->send;
        };


    $cv->recv;

    ok keys(%res) == 10, "All array elements were processed";
    ok grep({ $res{$_}{called} == $res{$_}{value} } keys %res) == 10,
        "The sequence order is right";

    ok $res{0}{first}, "First element was detected properly";
    ok $res{9}{last}, "Last element was detected properly";
    ok grep({ $res{$_}{first} } keys %res) == 1,
        "Only one element was detected as first";
    ok grep({ $res{$_}{last} } keys %res) == 1,
        "Only one element was detected as last";
}

# catch guard tests
{
    my $cv = condvar AnyEvent;
    my %res;
    my $number = 0;

    async_for [ 0 .. 9 ],
        sub {
            my ($g, $value, $index, $first, $last) = @_;
            $res{$index} = {
                value   => $value,
                first   => $first,
                last    => $last,
                called  => $number++,
                time    => time,
            };

            my $timer;

            $timer = AE::timer .05, 0 => sub {
                undef $timer;
                undef $g;
            };
        },
        sub {
            $cv->send;
        };


    $cv->recv;


#     note explain \%res;
#     exit;
    ok keys(%res) == 10, "All array elements were processed";
    ok grep({ $res{$_}{called} == $res{$_}{value} } keys %res) == 10,
        "The sequence order is right";

    ok $res{0}{first}, "First element was detected properly";
    ok $res{9}{last}, "Last element was detected properly";
    ok grep({ $res{$_}{first} } keys %res) == 1,
        "Only one element was detected as first";
    ok grep({ $res{$_}{last} } keys %res) == 1,
        "Only one element was detected as last";

    my $timing_test = 1;

    for (0 .. 8) {
        $timing_test = 0 if $res{$_+1}{time} - $res{$_}{time} < 0.045;
    }

    ok $timing_test, "Hold guard test";
}

# reverse for

{
    my $cv = condvar AnyEvent;
    my %res;
    my $number;

    async_rfor [ 0 .. 9 ],
        sub {
            my ($g, $value, $index, $first, $last) = @_;
            $res{$index} = {
                value   => $value,
                first   => $first,
                last    => $last,
                called  => $number++,
                time    => time,
            };
        },
        sub {
            $cv->send;
        };


    $cv->recv;


    ok keys(%res) == 10, "All array elements were processed";
    ok grep({ 9 - $res{$_}{called} == $res{$_}{value} } keys %res) == 10,
        "The sequence order is right";

    ok $res{9}{first}, "First element was detected properly";
    ok $res{0}{last}, "Last element was detected properly";
    ok grep({ $res{$_}{first} } keys %res) == 1,
        "Only one element was detected as first";
    ok grep({ $res{$_}{last} } keys %res) == 1,
        "Only one element was detected as last";
}
