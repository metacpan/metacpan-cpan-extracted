#$Id$

# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Object-Collection.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More 'no_plan';    #tests => 'noplan';

#use Test::More tests =>24 ;
use Data::Dumper;

BEGIN {
    use_ok('Collection::Utl::ActiveRecord');
    use_ok('Collection');
    use_ok('Collection::Utl::Mirror');
    use_ok('Collection::Mem');
}

