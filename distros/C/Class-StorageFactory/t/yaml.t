#!/usr/bin/perl -w

BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib', 'lib';
}

use TestYAML;
TestYAML->expected_tests( 18 );
TestYAML->runtests();
