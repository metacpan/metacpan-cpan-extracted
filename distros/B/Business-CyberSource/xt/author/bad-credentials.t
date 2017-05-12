use strict;
use warnings;
use Test::More;
use Test::Fatal;

use FindBin;
use Test::Requires  qw( Path::FindDev );
use lib Path::FindDev::find_dev( $FindBin::Bin )->child('t', 'lib' )->stringify;
use Module::Runtime qw( use_module );

my $t = new_ok( use_module('Test::Business::CyberSource') );

my $req = $t->resolve( service  =>'/request/authorization' );

my $client
	= new_ok( use_module( 'Business::CyberSource::Client') => [{
		user => 'foobar',
		pass => 'test',
		test => 1,
	}]);

my $exception = exception { $client->submit( $req ) };

TODO: {
	local $TODO = 'this test fails a lot because cybersource often ISEs';
	isa_ok $exception, 'Business::CyberSource::Exception::SOAPFault';
}

done_testing;
