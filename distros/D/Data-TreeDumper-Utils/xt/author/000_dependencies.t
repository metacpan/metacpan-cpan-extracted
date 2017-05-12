
# dependencies test

use strict ;
use warnings ;

use Test::More 'no_plan' ;
#use Test::UniqueTestNames ;

SKIP:
{
skip('Test::Dependencies has no support for Module::Build', 1) ;

#use Test::Dependencies  ;
#ok_dependencies();
}