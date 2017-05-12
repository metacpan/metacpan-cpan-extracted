#! perl
 
BEGIN
{
	chdir 't' if -d 't';
	use lib '../lib', '../blib/lib';
}

use strict;
use warnings;

use Test::More;
eval "use Test::Pod::Coverage";
plan( skip_all => 'Test::Pod::Coverage required for testing pod coverage' )
	if $@;
plan( tests => 2 );
pod_coverage_ok( 'Class::StorageFactory'       );
pod_coverage_ok( 'Class::StorageFactory::YAML' );
