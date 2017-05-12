#!/usr/bin/perl

use strict;
use File::Spec ();
BEGIN {
	$|  = 1;
	$^W = 1;
	require lib;
	lib->import(
		File::Spec->catdir(
			File::Spec->curdir, 't', 'modules',
		)
	);
}

use Test::More tests => 1;
use Scalar::Util 'refaddr';

use Class::Autouse;
Class::Autouse->autouse('baseB');

ok( baseB->isa('baseA'), 'isa() triggers autouse' );
