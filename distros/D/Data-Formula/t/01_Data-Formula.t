#!/usr/bin/perl

use strict;
use warnings;
use 5.010;
use utf8;

use Test::Most;

use_ok('Data::Formula') or die;

SIMPLE_FORMULA: {
    my $formula = 'n212 - n213 + n314 + n354';
    note('testing formula: '.$formula);
    my $df = Data::Formula->new(
        variables => [qw( n212 n213 n314 n354 )],
        formula   => $formula,
    );
    my $tokens = $df->_tokens;
    eq_or_diff(
        $tokens,
        [qw( n212 - n213 + n314 + n354)],
        '_tokens()'
    );

    my $used_variables = $df->used_variables;
    eq_or_diff(
        $used_variables,
        [qw( n212 n213 n314 n354 )],
        'used_variables()'
    );

    my $rpn = $df->_rpn;
    eq_or_diff(
        $rpn,
        [
            'n212',
            'n213',
            { 'name' => '-', calc => 'minus', method => 'minus', prio => 10, },
            'n314',
            { 'name' => '+', calc => 'plus', method => 'plus', prio => 10, },
            'n354',
            { 'name' => '+', calc => 'plus', method => 'plus', prio => 10, },
        ],
        '_rpn()'
    );

    my $val = $df->calculate(
        n212 => 5,
        n213 => 10,
        n314 => 7,
        n354 => 100
    );
    is($val,(5-10+7+100), 'calculate()');
}

SIMPLE_FORMULA2: {
    my $formula = 'n212 - (n213 + n314 + n354)';
    note('testing formula: '.$formula);
    my $df = Data::Formula->new(
        formula   => $formula,
    );

    my $val = $df->calculate(
        n212 => 5,
        n213 => 2,
        n314 => 3,
        n354 => 6,
    );
    is($val,(5-(2+3+6)), 'calculate()');

    my $rpn = $df->_rpn;
    eq_or_diff(
        $rpn,
        [
            'n212',
            'n213',
            'n314',
            { 'name' => '+', calc => 'plus', method => 'plus', prio => 110, },
            'n354',
            { 'name' => '+', calc => 'plus', method => 'plus', prio => 110, },
            { 'name' => '-', calc => 'minus', method => 'minus', prio => 10, },
        ],
        '_rpn()'
    );
}

MULTIPLICATION_FORMULA: {
    my $formula = 'n212 - n213 * n314 + n354';
    note('testing formula: '.$formula);
    my $df = Data::Formula->new(
        formula   => $formula,
    );

    my $val = $df->calculate(
        n212 => 5,
        n213 => 10,
        n314 => 7,
        n354 => 100
    );
    is($val,(5-(10*7)+100), 'calculate()');

    my $tokens = $df->_tokens;
    eq_or_diff(
        $tokens,
        [qw( n212 - n213 * n314 + n354)],
        '_tokens()'
    );

    my $rpn = $df->_rpn;
    eq_or_diff(
        $rpn,
        [
            'n212',
            'n213',
            'n314',
            { 'name' => '*', calc => 'multiply', method => 'multiply', prio => 50, },
            { 'name' => '-', calc => 'minus', method => 'minus', prio => 10, },
            'n354',
            { 'name' => '+', calc => 'plus', method => 'plus', prio => 10, },
        ],
        '_rpn()'
    );
}

LONGER_FORMULA: {
    my $formula = 'n212 - n213 + n314 * (n354 + n394) - 10';
    note('testing formula: '.$formula);
    my $df = Data::Formula->new(
        variables => [qw( n212 n213 n274 n294 n314 n334 n354 n374 n394 )],
        formula   => $formula,
    );
    my $tokens = $df->_tokens;
    eq_or_diff(
        $tokens,
        [qw( n212 - n213 + n314 * ( n354 + n394 ) - 10 )],
        '_tokens()'
    );

    my $used_variables = $df->used_variables;
    eq_or_diff(
        $used_variables,
        [qw( n212 n213 n314 n354 n394 )],
        'used_variables()'
    );

    my $rpn = $df->_rpn;
    eq_or_diff(
        $rpn,
        [
            'n212',
            'n213',
            { 'name' => '-', calc => 'minus', method => 'minus', prio => 10, },
            'n314',
            'n354',
            'n394',
            { 'name' => '+', calc => 'plus', method => 'plus', prio => 110, },
            { 'name' => '*', calc => 'multiply', method => 'multiply', prio => 50, },
            { 'name' => '+', calc => 'plus', method => 'plus', prio => 10, },
            10,
            { 'name' => '-', calc => 'minus', method => 'minus', prio => 10, },
        ],
        '_rpn()'
    );

    my $val = $df->calculate(
        n212 => 5,
        n213 => 10,
        n314 => 2,
        n354 => 3,
        n394 => 9,
    );
    is($val,(5-10+(2*(3+9))-10), 'calculate()');
}

done_testing();
