#!perl

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok( 'Catalyst::Plugin::Environment' );
}

diag( "Testing Catalyst::Plugin::Environment $Catalyst::Plugin::Environment::VERSION, Perl $], $^X" );

done_testing;
