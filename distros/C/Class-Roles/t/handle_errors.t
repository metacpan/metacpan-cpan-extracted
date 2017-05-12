#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;

use Test::More tests => 3;
use Test::Exception;

my $module = 'Class::Roles';
use_ok( $module ) or exit;

throws_ok { Class::Roles->import( 'only one target' ) }
	qr/Improper argument list/,
	'import() should throw exception with odd number of arguments';

throws_ok { Class::Roles->import( 'no target' => 'who cares' ) }
	qr/Unknown action 'no target'/,
	'import() should throw exception if given an invalid target';
