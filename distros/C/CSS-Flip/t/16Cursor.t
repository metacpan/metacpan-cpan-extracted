#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 6;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = 'cursor: e-resize';
$shouldbe = 'cursor: w-resize';
is($self->transform($testcase), $shouldbe);

$testcase = 'cursor: w-resize';
$shouldbe = 'cursor: e-resize';
is($self->transform($testcase), $shouldbe);

$testcase = 'cursor: se-resize';
$shouldbe = 'cursor: sw-resize';
is($self->transform($testcase), $shouldbe);

$testcase = 'cursor: sw-resize';
$shouldbe = 'cursor: se-resize';
is($self->transform($testcase), $shouldbe);

$testcase = 'cursor: ne-resize';
$shouldbe = 'cursor: nw-resize';
is($self->transform($testcase), $shouldbe);

$testcase = 'cursor: nw-resize';
$shouldbe = 'cursor: ne-resize';
is($self->transform($testcase), $shouldbe);

