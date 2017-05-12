#!/usr/bin/perl

use warnings;
use strict;
use utf8;
use open qw(:std :utf8);
use lib qw(lib ../lib);

use Test::More tests    => 6;
use Encode qw(decode encode);


BEGIN {
    my $builder = Test::More->builder;
    binmode $builder->output,         ":utf8";
    binmode $builder->failure_output, ":utf8";
    binmode $builder->todo_output,    ":utf8";

    use_ok 'AnyEvent';
    use_ok 'AnyEvent::AggressiveIdle', ':all';

}

{
    my $cv = condvar AnyEvent;

    my ($cnt1, $cnt2, $cnt2_t, $cnt3) = (0, 0, 0, 0);

    my $idle1 = aggressive_idle {
        $cnt1++;

    };

    my $idle2 = aggressive_idle {
        my ($pid, $guard) = @_;

        $cnt2++;
        my $t;
        $t = AE::timer 0.1, 0 => sub {
            undef $t;
            $cnt2_t++;
            $cv->send if $cnt2 == 10;
            undef $guard;
        }
    };

    my $idle3 = aggressive_idle { $cnt3++ };

    $cv->recv;

    ok $cnt1 == $cnt3, 'Two aggressive_idle counters are equal';
    ok $cnt1 > $cnt2,  'Timer works properly';
    ok $cnt2_t == 10,  'Subroutine was called 10 times';
    ok abs($cnt2 - $cnt2_t) <= 1, 'Idle process was called 10 or 11 times';
}

