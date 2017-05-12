#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 9;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;
my @args;

@args     = qw(1px 2px 3px 4px);
$shouldbe = '2px 1px 4px 3px';
is(CSS::Janus::reorderBorderRadiusPart(@args), $shouldbe);

@args     = qw(1px 2px 3px);
$shouldbe = '2px 1px 2px 3px';
is(CSS::Janus::reorderBorderRadiusPart(@args), $shouldbe);

@args     = qw(1px 2px);
$shouldbe = '2px 1px';
is(CSS::Janus::reorderBorderRadiusPart(@args), $shouldbe);

@args     = qw(1px);
$shouldbe = '1px';
is(CSS::Janus::reorderBorderRadiusPart(@args), $shouldbe);

@args =
    ('X', '', ': ', '1px', '2px', '3px', '4px', '5px', '6px', undef, '7px');
$shouldbe = 'border-radius: 2px 1px 4px 3px / 6px 5px 6px 7px';
is(CSS::Janus::reorderBorderRadius(@args), $shouldbe);

$testcase = 'border-radius: 1px 2px 3px 4px / 5px 6px 7px 8px';
$shouldbe = 'border-radius: 2px 1px 4px 3px / 6px 5px 8px 7px';
is($self->transform($testcase), $shouldbe);

$testcase = 'border-radius: 1px 2px 3px 4px / 5px 6px 7px';
$shouldbe = 'border-radius: 2px 1px 4px 3px / 6px 5px 6px 7px';
is($self->transform($testcase), $shouldbe);

$testcase = 'border-radius: 1px 2px 3px 4px / 5px 6px';
$shouldbe = 'border-radius: 2px 1px 4px 3px / 6px 5px';
is($self->transform($testcase), $shouldbe);

$testcase = 'border-radius: 1px 2px 3px 4px / 5px';
$shouldbe = 'border-radius: 2px 1px 4px 3px / 5px';
is($self->transform($testcase), $shouldbe);

