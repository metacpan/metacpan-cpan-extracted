#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 16;
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
    my %res;
    my $called = 0;

    my %hash = map {($_ => 100 + $_)  } 0 .. 9;
    my $first = (keys %hash)[0];
    my $last  = (keys %hash)[-1];

    async_for \%hash,
        sub {
            my ($g, $key, $value, $first, $last) = @_;
            $res{$key} = {
                value   => $value,
                first   => $first,
                last    => $last,
                called  => $called++
            };
        },
        sub {
            $cv->send;
        };

    $cv->recv;

    ok keys(%res) == 10, "All array elements were processed";
    ok grep({ $res{$_}{value} == 100 + $_  } keys %res) == 10,
        "All values are correct";

    ok 1 == grep({$res{$_}{first}} 0 .. 9),
        "First element was detected";
    ok 1 == grep({$res{$_}{last}} 0 .. 9),
        "Last element was detected";

    ok $res{$first}{first}, "First element was detected properly";
    ok $res{$last}{last}, "Last element was detected properly";

    my $seq_ok = 1;
    $called = 0;
    for (keys %hash) {
        $seq_ok = 0 unless $res{$_}{called} == $called;
        $called++;
    }

    ok $seq_ok, "The sequence order is right";
}

{
    my $cv = condvar AnyEvent;
    my %res;
    my $called = 0;

    my %hash = map {($_ => 100 + $_)  } 0 .. 9;
    my $first = (keys %hash)[-1];
    my $last  = (keys %hash)[0];

    async_rfor \%hash,
        sub {
            my ($g, $key, $value, $first, $last) = @_;
            $res{$key} = {
                value   => $value,
                first   => $first,
                last    => $last,
                called  => $called++
            };
        },
        sub {
            $cv->send;
        };

    $cv->recv;

    ok keys(%res) == 10, "All array elements were processed";
    ok grep({ $res{$_}{value} == 100 + $_  } keys %res) == 10,
        "All values are correct";

    ok 1 == grep({$res{$_}{first}} 0 .. 9),
        "First element was detected";
    ok 1 == grep({$res{$_}{last}} 0 .. 9),
        "Last element was detected";

    ok $res{$first}{first}, "First element was detected properly";
    ok $res{$last}{last}, "Last element was detected properly";

    my $seq_ok = 1;
    $called = 0;
    for (reverse keys %hash) {
        $seq_ok = 0 unless $res{$_}{called} == $called;
        $called++;
    }

    ok $seq_ok, "The sequence order is right";
}
