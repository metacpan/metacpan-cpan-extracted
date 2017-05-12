#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 2;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = 'background-image: -moz-linear-gradient(#326cc1, #234e8c)';
$shouldbe = 'background-image: -moz-linear-gradient(#326cc1, #234e8c)';
is($self->transform($testcase), $shouldbe);

$testcase =
    'background-image: -webkit-gradient(linear, 100% 0%, 0% 0%, from(#666666), to(#ffffff))';
$shouldbe =
    'background-image: -webkit-gradient(linear, 100% 0%, 0% 0%, from(#666666), to(#ffffff))';
is($self->transform($testcase), $shouldbe);

