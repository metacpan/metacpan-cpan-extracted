#-*- perl -*-

use strict;
#use warnings;
use Test::More tests => 15;

use CSS::Janus;

my $self = CSS::Janus->new;
my $testcase;
my $shouldbe;

$testcase = 'background-position: 25pt 40%';
my $res;
eval { $res = $self->transform($testcase); };
if ($@) {
    ok(1, $@);
} else {
    fail;
    diag 'returned "', $res, '"';
}

$testcase = 'background-position: 0 40%';
$shouldbe = 'background-position: 100% 40%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 0px 40%';
$shouldbe = 'background-position: 100% 40%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 0 0';
$shouldbe = 'background-position: 100% 0';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 0px 0';
$shouldbe = 'background-position: 100% 0';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 0px 0px';
$shouldbe = 'background-position: 100% 0px';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position: 0 auto';
$shouldbe = 'background-position: 100% auto';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position-x: 0';
$shouldbe = 'background-position-x: 100%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position-x: 0px';
$shouldbe = 'background-position-x: 100%';
is($self->transform($testcase), $shouldbe);

$testcase = 'background-position-y: 0';
$shouldbe = 'background-position-y: 0';
is($self->transform($testcase), $shouldbe);

$testcase = 'background:url(../foo-bar_baz.2008.gif) no-repeat 0 50%';
$shouldbe = 'background:url(../foo-bar_baz.2008.gif) no-repeat 100% 50%';
is($self->transform($testcase), $shouldbe);

$testcase = '.test { background: 0 20% } .test2 { background: 0 30% }';
$shouldbe = '.test { background: 100% 20% } .test2 { background: 100% 30% }';
is($self->transform($testcase), $shouldbe);

$testcase = '.test { background: 0 20% } .test2 { background: 0 30% }';
$shouldbe = '.test { background: 100% 20% } .test2 { background: 100% 30% }';
is($self->transform($testcase), $shouldbe);

# cssjanus Issue #20

$testcase = 'div {background: none; padding: 1em 0;}';
$shouldbe = 'div {background: none; padding: 1em 0;}';
is($self->transform($testcase), $shouldbe);

$testcase = 'div {background: none; padding: 10% 0;}';
$shouldbe = 'div {background: none; padding: 10% 0;}';
is($self->transform($testcase), $shouldbe);

