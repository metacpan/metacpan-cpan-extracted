
use strict ;
use warnings ;

use Test::NoWarnings ;

use Test::More qw(no_plan);
use Test::Exception ;
#use Test::UniqueTestNames ;

BEGIN { use_ok( 'Data::HexDump::Range' ) or BAIL_OUT("Can't load module"); } ;

my $object = new Data::HexDump::Range ;

is(defined $object, 1, 'default constructor') ;
isa_ok($object, 'Data::HexDump::Range');

my $new_config = $object->new() ;
is(defined $new_config, 1, 'constructed from object') ;
isa_ok($new_config , 'Data::HexDump::Range');

dies_ok
	{
	Data::HexDump::Range::new () ;
	} "invalid constructor" ;
