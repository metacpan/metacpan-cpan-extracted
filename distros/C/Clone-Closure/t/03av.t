#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Builder;
use B;
use Scalar::Util    qw/blessed/;
use Clone::Closure  qw/clone/;

BEGIN { *b = \&B::svref_2object }

my $tests;

{
    BEGIN { $tests += 3 }

    my @ary;
    my $av = clone \@ary;

    isa_ok  b($av),             'B::AV',        'empty AV cloned';
    isnt    $av,                \@ary,          '...not copied';
    is      @$av,               0,              '...correctly';
}

{
    BEGIN { $tests += 3 }

    my @ary = qw/one two three/;
    my $av  = clone \@ary;

    is      @$av,               3,              'AV size cloned';
    is      $av->[1],           'two',          'AV contents cloned';
    isnt    \$av->[1],          \$ary[1],       '...not copied';
}

{
    BEGIN { $tests += 5 }

    my $aref      = [ 1, [ 2, undef ] ];
    $aref->[1][1] = $aref;
    my $av        = clone $aref;

    isa_ok  b($av->[1]),        'B::AV',        'nested AV cloned';
    isnt    $av->[1],           $aref->[1],     '...not copied';
    is      $av->[1][0],        2,              '...correctly';

    is      $av->[1][1],        $av,            'recursive arefs cloned';
    isnt    $av->[1][1],        $aref,          '...not copied';
}

{
    BEGIN { $tests += 2 }

    my $aref = bless [], 'Bar';
    my $av   = clone $aref;

    isa_ok  b($av),             'B::AV',        'blessed AV cloned';
    is      blessed($av),       'Bar',          '...preserving class';
}

BAIL_OUT 'arrays won\'t clone correctly'
    if grep !$_, Test::Builder->new->summary;

BEGIN { plan tests => $tests }
