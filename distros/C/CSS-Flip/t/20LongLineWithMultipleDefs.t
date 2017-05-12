#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 1;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase =
    'body{direction:rtl;float:right}' . '.b2{direction:ltr;float:right}';
$shouldbe =
    'body{direction:ltr;float:left}' . '.b2{direction:ltr;float:left}';
is($self->transform($testcase), $shouldbe);

