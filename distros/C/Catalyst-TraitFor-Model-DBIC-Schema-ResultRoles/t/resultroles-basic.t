use strict;
use warnings;
use Test::More tests => 4;

use lib 't/lib';

use_ok("RRBasicTest");
my $testobject = new_ok( "RRBasicTest" );
if($testobject){
	my $dummy = eval{
		$testobject->BUILD;
		$testobject->schema->source_registrations->{'Dummy'};
	};
	ok($dummy, "fetching resultclass");
	my $hello = eval{$dummy->hello};
	is($hello, "hello world", "helloworld");
}





