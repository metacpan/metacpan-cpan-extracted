#!/usr/bin/perl

# Unit testing for Class::Inspector

# Do all the tests on ourself, where possible, as we know we will be loaded.

use strict;
use warnings;
use Test::More tests => 2;
use Class::Inspector ();




#####################################################################
# Try the simplistic Win32 approach

SKIP: {
  skip( "Skipping Win32 test", 1 ) unless $^O eq 'MSWin32';
  my $inc   = 'C:/foo/bar.pm';
  my $local = Class::Inspector->_inc_to_local($inc);
  is( $local, 'C:\foo\bar.pm', '->_inc_to_local ok' );
}





#####################################################################
# More general tests

my $module = Class::Inspector->_inc_to_local($INC{'Class/Inspector.pm'});
ok( -f $module, 'Found ourself' );
