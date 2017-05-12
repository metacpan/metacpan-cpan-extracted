#!/usr/bin/perl

use Test;
BEGIN { plan tests => 4 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

DBIx::SQLEngine->define_named_connections( 
  null1 => 'dbi:NullP:',
  null2 => [ 'dbi:NullP:' ],
);

########################################################################

{
  my $sqldb = DBIx::SQLEngine->new( 'null1' );
  ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );
}

########################################################################

{
  my $sqldb = DBIx::SQLEngine->new( 'null2' );
  ok( $sqldb and ref($sqldb) =~ m/^DBIx::SQLEngine/ );
}

########################################################################

ok( ! eval { local $^W; my $sqldb = DBIx::SQLEngine->new( 'null5' ) } );

########################################################################

1;