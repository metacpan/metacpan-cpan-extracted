#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
	use_ok('CouchDB::Deploy::Process');
	use_ok('CouchDB::Deploy');
}
