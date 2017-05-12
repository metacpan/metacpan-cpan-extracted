#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 6;
use Time::HiRes qw(time);
use Encode qw(decode encode);
use AnyEvent;

BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent::Tools', 'pool';
}

{
    my $cv = condvar AnyEvent;
    my $pool = pool qw( a b );
    my $order = 0;
    my @res;

    my $busy = 0;
    my $cnt = 1;
    my $idle;

    $idle = AE::idle  sub {
        $pool->get(sub {
            my ($guard, $object) = @_;
            $busy++;
            push @res, { b => $busy, t => time };
            my $timer;
            $timer = AE::timer 0.1, 0 => sub {
                $busy--;
                undef $timer;
                undef $guard;

                if (@res >= 40) {
                    undef $idle;
                    $cv->send;
                }
            };
        });

        undef $idle if $cnt++ >= 40;
    };


    $cv->recv;


    my $ok;
    for (my $i = 0 ; $i < @res - 2; $i += 2) {
        $ok = $res[$i + 2]{t} - $res[$i]{t} >= .09;
        last unless $ok;
    }

    diag explain \@res unless
        ok $ok, "Sequence order is right";
    ok 0 == grep({ $_->{b} > 2 } @res), "Pool works fine";
}

{
    my $cv = condvar AnyEvent;
    my $pool = pool qw( a b );
    my $order = 0;
    my @res;
    my $dtime = 0;

    my $ano = $pool->push('c');
    my $t;
    $t = AE::timer 0.7, 0 => sub {
        $pool->delete($ano => sub { $dtime = time });
        undef $t;
    };

    for (0 .. 10) {
        $pool->get(sub {
            my ($guard, $object) = @_;
            my $timer;
            $timer = AE::timer 0.5, 0 => sub {
                push @res, { obj => $object, time => time, order => $order++ };
                undef $timer;
                undef $guard;
                $cv->send if @res == 11;
            };
        });
    }


    $cv->recv;

    ok 2 == grep({ $_->{obj} eq 'c' } @res), "delete method works fine";
    my ($f, $s) = grep { $_->{obj} eq 'c' } @res;

    diag explain \@res unless
        ok $s->{time} - $f->{time} >= 0.45, "Sequence order is right";
    ok $dtime - $f->{time} >= 0.45, "delete only if resource free";
}
