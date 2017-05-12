# test

use strict ;
use warnings ;

use Test::Exception ;
use Test::Warn;
use Test::NoWarnings qw(had_no_warnings);

use Test::More 'no_plan';
#use Test::UniqueTestNames ;

use Test::Block qw($Plan);

use App::Textcast  ;

{
local $Plan = {'' => 1} ;


throws_ok
	{
	}
	qr//, 'failed' ;
}
