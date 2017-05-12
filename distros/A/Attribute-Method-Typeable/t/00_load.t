#!/usr/bin/perl
#
#		Unit test script for Attribute-Method-Typeable
#		$Id: 00_load.t,v 1.2 2004/03/28 23:17:28 phaedrus Exp $
#
#		Before `make install' is performed this script should be runnable with
#		`make test'. After `make install' it should work as `perl t/00_load.t'
#
#		Please do not commit any changes you make to the module without a
#		successful 'make test'!
#
package main;
use strict;

BEGIN	{ $| = 1; }

use IO::File;
### Load up the test framework
use Test::SimpleUnit qw{:functions};

# Load some other modules

my (
   $manifest,
   @modules,
   @testSuite,
  );

# Read the manifest and grok the list of modules out of it
$manifest = IO::File->new( "MANIFEST", "r" )
   or die "open: MANIFEST: $!";
@modules = map { s{lib/(.+)\.pm$}{$1}; s{/}{::}g; $_ }
	grep { m{\.pm$} && $_ !~ m{old/} }
	$manifest->getlines;

### Test suite (in the order they're run)
@testSuite = map {
	{
		name => "require ${_}",
		test => eval qq{sub { assertNoException {require $_}; }},
	},
} @modules;

runTests( @testSuite );

