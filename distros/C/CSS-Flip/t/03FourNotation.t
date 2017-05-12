#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 7;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = 'padding: .25em 15px 0pt 0ex';
$shouldbe = 'padding: .25em 0ex 0pt 15px';
is($self->transform($testcase), $shouldbe);

$testcase = 'margin: 1px -4px 3px 2px';
$shouldbe = 'margin: 1px 2px 3px -4px';
is($self->transform($testcase), $shouldbe);

$testcase = 'padding:0 15px .25em 0';
$shouldbe = 'padding:0 0 .25em 15px';
is($self->transform($testcase), $shouldbe);

$testcase = 'padding: 1px 4.1grad 3px 2%';
$shouldbe = 'padding: 1px 2% 3px 4.1grad';
is($self->transform($testcase), $shouldbe);

$testcase = 'padding: 1px 2px 3px auto';
$shouldbe = 'padding: 1px auto 3px 2px';
is($self->transform($testcase), $shouldbe);

$testcase = 'padding: 1px inherit 3px auto';
$shouldbe = 'padding: 1px auto 3px inherit';
is($self->transform($testcase), $shouldbe);

# not really four notation
$testcase = '#settings td p strong';
$shouldbe = $testcase;
is($self->transform($testcase), $shouldbe);

