#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 2;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = 'float: right';
$shouldbe = 'float: left';
is($self->transform($testcase), $shouldbe);

$testcase = 'float: left';
$shouldbe = 'float: right';
is($self->transform($testcase), $shouldbe);

