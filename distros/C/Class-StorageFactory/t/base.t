#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib', 'lib';
}

use TestBase;
TestBase->expected_tests( 14 );
TestBase->runtests();
