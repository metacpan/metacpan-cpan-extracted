#!perl -T
# vim:syntax=perl:tabstop=4:number:noexpandtab:

use strict;
use warnings;
use CHI::Driver::MongoDB::t::CHIDriverTests;
use Test::Builder;
use MongoDB;

if ( have_mongodb_server() ) {
	CHI::Driver::MongoDB::t::CHIDriverTests->runtests();
}
else {
	CHI::Driver::MongoDB::t::CHIDriverTests->SKIP_ALL("No MongoDB server available!");
}

sub have_mongodb_server {
	my $uri = $ENV{'MONGODB_CONNECTION_URI'} // 'mongodb://127.0.0.1:27017';
	my $client;
	my @db;
	eval {
		$client = MongoDB->connect($uri);
		@db     = $client->database_names;
	};
	if ( !$@ and defined($client) and ref($client) eq 'MongoDB::MongoClient' and @db ) {
		return 1;
	}
	return 0;
}
