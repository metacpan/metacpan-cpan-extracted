#!/usr/bin/env perl

use strict;
use warnings;

use App::Highlander;
use Test::More;

foreach my $lockstring ( ('', 'accountid=5') ) {
   my $lockfile; 
   ok( $lockfile = App::Highlander::get_lock($lockstring), 
       "got an exclusive lock on '$lockfile' for '$lockstring'" );
   
   ok( -e $lockfile, "lockfile '$lockfile' exists" );
   
   ok( App::Highlander::release_lock($lockstring), 
       "released lock on '$lockfile' for '$lockstring'" );
   
   ok( ! -e $lockfile, "LOCKFILE '$lockfile' was removed" );
}

done_testing();
