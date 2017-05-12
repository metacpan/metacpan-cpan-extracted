#!perl -T

use strict;
use warnings;

use Test::More;

BEGIN {
  use_ok( 'Catalyst::Model::DBIx::Connector' );
}

diag( "Testing Catalyst::Model::DBIx::Connector $Catalyst::Model::DBIx::Connector::VERSION, Perl $], $^X" );

done_testing;
