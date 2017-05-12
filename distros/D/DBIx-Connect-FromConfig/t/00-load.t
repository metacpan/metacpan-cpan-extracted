#!perl -T
use strict;
use Test::More tests => 4;

use_ok( 'DBIx::Connect::FromConfig' );
diag( "Testing DBIx::Connect::FromConfig $DBIx::Connect::FromConfig::VERSION, Perl $], $^X" );
can_ok( 'DBIx::Connect::FromConfig' => 'connect' );

use_ok( 'DBIx::Connect::FromConfig', '-in_dbi' );
can_ok( 'DBI' => 'connect_from_config' );
