#!/usr/bin/perl

use Test;
use strict;
use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);

########################################################################

BEGIN { require 'test_drivers/get_test_dsn.pl' }

BEGIN { plan tests => 2 }

########################################################################

my ($type) = ( ref($sqldb) =~ /DBIx::SQLEngine::(.+)/ );

if ( ! $sqldb ) {
warn <<".";
  Skipping: Could not connect to this DSN to test your local server.
.
  skip(
    "Skipping: Could not connect to this DSN to test your local server.",
    0,
  );
  exit 0;
}

warn "Using DBIx::SQLEngine::$type.\n";

ok( $sqldb and $type );

ok( $sqldb->detect_any );

########################################################################

1;