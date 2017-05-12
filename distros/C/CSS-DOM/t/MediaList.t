#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use tests 1; # use
use_ok 'CSS::DOM::MediaList';

use tests 2; # constructor
isa_ok +(my $ml = new CSS::DOM::MediaList 'print', 'screen'), 
	'CSS::DOM::MediaList';
is_deeply [@$ml], ['print' ,'screen'], 'constructor args';

use tests 3; # mediaText
is mediaText $ml, 'print, screen', 'initial value of mediaText';
is +(mediaText $ml " \nscReen (big one),\xa0hologram-101 "),
	'print, screen', 'ret val of mediaText with args';
is_deeply [@$ml], ['scReen', 'hologram-101'],
	'result of setting mediaText';

use tests 1; # length
is $ml->length, 2, 'length';

use tests 1; # item
is +(item $ml 1), 'hologram-101', 'item';

use tests 4; # deleteMedium
is +()=$ml->deleteMedium('hologram-101'), 0, 'ret val of deleteMedium';
is_deeply [@$ml], ['scReen'], 'effect of deleteMedium';
eval { deleteMedium $ml 'foo' };
isa_ok $@, 'CSS::DOM::Exception',
	'$@ (after deleteMedium)';
cmp_ok $@, '==', 
	&CSS::DOM::Exception::NOT_FOUND_ERR,
	'deleteMedium throws a "not found" error';

use tests 3; # appendMedium
@$ml = qw[ foo bar baz ];
is +()=$ml->appendMedium('bop'), 0, 'ret val of appendMedium';
is_deeply [@$ml], [qw [ foo bar baz bop ]], 'effect thereof';
$ml->appendMedium('bar');
is_deeply [@$ml], [qw[ foo baz bop bar ]],
	'appendMedium deletes the item first';

# What do you call a psychic midget escaped from prison?
# A small medium at large.
