#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 10;
use Test::NoWarnings;

use Data::Peek;

is (DDisplay (undef),		'',			'undef  has no PV');
is (DDisplay (0),		'',			'0      has no PV');
is (DDisplay (\undef),		'',			'\undef has no PV');
is (DDisplay (\0),		'',			'\0     has no PV');
is (DDisplay (sub {}),		'',			'code   has no PV');

is (DDisplay (""),		'""',			'empty string');
is (DDisplay ("a"),		'"a"',			'"a"');
is (DDisplay ("\n"),		'"\n"',			'"\n"');
if ($] < 5.008) {
    is (DDisplay ("\x{20ac}"),	'"\342\202\254"',	'"\n"');
    }
else {
    is (DDisplay ("\x{20ac}"),	'"\x{20ac}"',		'"\n"');
    }

1;
