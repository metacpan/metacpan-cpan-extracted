#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok( 'Catalyst::Plugin::Log::Log4perl' );
}

diag( "Testing Catalyst::Plugin::Log::Log4perl $Catalyst::Plugin::Log::Log4perl::VERSION, Perl $], $^X" );

done_testing();
