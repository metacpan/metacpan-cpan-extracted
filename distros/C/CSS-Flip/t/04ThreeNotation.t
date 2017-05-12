#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 2;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = 'margin: 1em 0 .25em';
$shouldbe = 'margin: 1em 0 .25em';
is($self->transform($testcase), $shouldbe);

$testcase = 'margin:-1.5em 0 -.75em';
$shouldbe = 'margin:-1.5em 0 -.75em';
is($self->transform($testcase), $shouldbe);

