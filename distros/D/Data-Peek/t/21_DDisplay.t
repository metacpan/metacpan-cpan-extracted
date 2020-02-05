#!/usr/bin/perl

use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Data::Peek;

is (DDisplay (undef),		'',			'undef  has no PV');
is (DDisplay (0),		'',			'0      has no PV');
is (DDisplay (\undef),		'',			'\undef has no PV');
is (DDisplay (\0),		'',			'\0     has no PV');
is (DDisplay (sub {}),		'',			'code   has no PV');

is (DDisplay (""),		'""',			'empty string');
is (DDisplay ("a"),		'"a"',			'"a"');
is (DDisplay ("\n"),		'"\n"',			'"\n"');
is (DDisplay ("\x{20ac}"),	'"\x{20ac}"',		'"\n"');

done_testing;

1;
