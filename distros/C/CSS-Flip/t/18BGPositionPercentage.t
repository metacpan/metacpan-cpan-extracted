#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 9;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = 'background-position: 100% 40%';
$shouldbe = 'background-position: 0% 40%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 0% 40%';
$shouldbe = 'background-position: 100% 40%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 23% 0';
$shouldbe = 'background-position: 77% 0';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 23% auto';
$shouldbe = 'background-position: 77% auto';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position-x: 23%';
$shouldbe = 'background-position-x: 77%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position-y: 23%';
$shouldbe = 'background-position-y: 23%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background:url(../foo-bar_baz.2008.gif) no-repeat 75% 50%';
$shouldbe = 'background:url(../foo-bar_baz.2008.gif) no-repeat 25% 50%';
is($self->transform($testcase), $shouldbe);

$testcase = '.test { background: 10% 20% } .test2 { background: 40% 30% }';
$shouldbe = '.test { background: 90% 20% } .test2 { background: 60% 30% }';
is($self->transform($testcase), $shouldbe);

$testcase = '.test { background: 0% 20% } .test2 { background: 40% 30% }';
$shouldbe = '.test { background: 100% 20% } .test2 { background: 60% 30% }';
is($self->transform($testcase), $shouldbe);

