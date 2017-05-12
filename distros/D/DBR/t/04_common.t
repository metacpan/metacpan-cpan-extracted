#!/usr/bin/perl

# Test that everything compiles, so the rest of the test suite can
# load modules without having to check if it worked.

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 4;

use_ok('DBR::Common');

#fake an object

my $obj = bless ({},'DBR::Common');


my @list;

#Numbers
@list = $obj->_uniq( 1,1,2,1,3,4,5,5,6,0 );
ok(@list == 7,'_uniq - Numbers');


#Letters
@list = $obj->_uniq( qw(A B C D E E F G) );
ok(@list == 7,'_uniq - Letters');

#Falses
@list = $obj->_uniq( '',undef,0,' ',undef,' ' );
ok( @list == 4, '_uniq - Various forms of false' );


# Split
