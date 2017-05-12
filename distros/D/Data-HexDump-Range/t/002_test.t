# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);

use Data::HexDump::Range ;

#multiple ranges on the same line in horizontal display

__END__

{
local $Plan = {'' => 1} ;


throws_ok
	{
	}
	qr//, 'failed' ;
}
