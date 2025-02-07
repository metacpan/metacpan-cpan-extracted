use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT use_ok ) ], tests => 2;
use Test::API import => [ qw( class_api_ok ) ];

my $module;

BEGIN {
  $module = 'DBIx::Migration';
  use_ok( $module ) or BAIL_OUT "Cannot load module '$module'!";
}

class_api_ok( $module, qw( new dir debug dbh dsn username password migrate version ) );
