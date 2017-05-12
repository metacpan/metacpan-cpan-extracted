
use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;
#use Test::UniqueTestNames ;

BEGIN { use_ok( 'App::Chained' ) or BAIL_OUT("Can't load module"); } ;

my $object = new App::Chained ;

is(defined $object, 1, 'default constructor') ;
isa_ok($object, 'App::Chained');

my $new_config = $object->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'App::Chained');

dies_ok
	{
	App::Chained::new () ;
	} "invalid constructor" ;
