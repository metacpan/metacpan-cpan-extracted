#! perl

use strict;
use warnings;

use Test::More tests => 4;
use Test::Warn;

use Data::Transpose;
use Data::Dumper;

my ($tp, $g, $output);

# first case: join with default string
$tp = Data::Transpose->new;
$g = $tp->group('baz',
           $tp->field('foo'),
           $tp->field('bar'),
    );

$output = $tp->transpose({foo => 'my', bar => 'name'});

ok (exists $output->{baz} && $output->{baz} eq 'my name',
    'simple transpose group test foo + bar => foo bar')
    || diag "Transpose output: " . Dumper($output);

# second case: join with custom string
$tp = Data::Transpose->new;
$g = $tp->group('baz',
           $tp->field('foo'),
           $tp->field('bar'),
    );
$g->join(',');

$output = $tp->transpose({foo => 'my', bar => 'name'});

ok (exists $output->{baz} && $output->{baz} eq 'my,name',
    'simple transpose group test foo + bar => foo,bar')
    || diag "Transpose output: " . Dumper($output);

# third case: with transpose value
$tp = Data::Transpose->new;
$g = $tp->group('baz',
           $tp->field('foo'),
           $tp->field('bar'),
    );
$g->target('foobar');

$output = $tp->transpose({foo => 'my', bar => 'name'});

ok (exists $output->{foobar} && $output->{foobar} eq 'my name',
    'simple transpose group test with transpose set')
    || diag "Transpose output: " . Dumper($output);

# ensure that joining emits no warning
$tp = Data::Transpose->new;
$g = $tp->group('baz',
           $tp->field('foo'),
           $tp->field('bar'),
    );
$g->target('foobar');

warnings_are {$output = $tp->transpose({foo => undef, bar => 'name'})} [],
    'transpose group test with undefined values';


