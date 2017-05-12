#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 4;

BEGIN {
	use_ok('CouchDB::Client::Doc');
	use_ok('CouchDB::Client::DesignDoc');
	use_ok('CouchDB::Client::DB');
	use_ok('CouchDB::Client');
}
