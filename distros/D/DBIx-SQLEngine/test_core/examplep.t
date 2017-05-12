#!/usr/bin/perl

use Test;
BEGIN { plan tests => 13 }

use DBIx::SQLEngine;
  # DBIx::SQLEngine->DBILogging(1);
ok( 1 );

########################################################################

{
  my $sqldb = DBIx::SQLEngine->new( 'dbi:ExampleP:' );
  ok( $sqldb );
  ok( ref($sqldb) =~ m/^DBIx::SQLEngine/ );
  
  my @cols = $sqldb->detect_table( 'SQLEngine' );
  ok( scalar( @cols ), 14 );
  @cols = $sqldb->detect_table( 'area_51_secrets', 'quietly' );
  ok( scalar( @cols ), 0 );
  
  my $rows = $sqldb->fetch_select( table => '.' );
  ok( ref $rows and scalar @$rows > 1 );
  ok( grep { $_->{name} =~ /SQLEngine/i } @$rows );
}

########################################################################

{
local $^W;
  my $dbh = DBI->connect ( 'dbi:ExampleP:', undef, undef, 
	{ AutoCommit => 1, PrintError => 0, RaiseError => 1 } );
  my $sqldb = DBIx::SQLEngine->new( $dbh );
  ok( $sqldb );
  ok( ref($sqldb) =~ m/^DBIx::SQLEngine/ );
  
  my @cols = $sqldb->detect_table( 'SQLEngine' );
  ok( scalar( @cols ), 14 );
  @cols = $sqldb->detect_table( 'area_51_secrets', 'quietly' );
  ok( scalar( @cols ), 0 );
  
  my $rows = $sqldb->fetch_select( table => '.' );
  ok( ref $rows and scalar @$rows > 1 );
  ok( grep { $_->{name} =~ /SQLEngine/i } @$rows );
}