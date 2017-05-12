#!/usr/bin/perl

use Test;

BEGIN { require 't/get_test_dsn.pl' }

BEGIN { plan tests => 15 }

########################################################################

use Carp;
# $SIG{__DIE__} = \&Carp::confess;

########################################################################

use DBIx::DBO2;
  # Turn this on for verbose logging...
  # DBIx::SQLEngine->DBILogging(1);

use lib "t/lib"; 
use MyCDs;

########################################################################

MyCDs->init();
MyCDs->connect_datasource( $dsn, $user, $pass );

my ($sqldb) = MyCDs->datasource;
my ($type) = ( ref($sqldb) =~ /DBIx::SQLEngine::(.+)/ );

########################################################################

if ( ! $sqldb ) {
warn <<".";
  Skipping: Could not connect to this DBI_DSN to test your local server.

.
  skip(
    "Skipping: Could not connect to this DBI_DSN to test your local server.\n",
    0,
  );
  exit 0;
}

warn <<".";
  Connected using DBIx::SQLEngine::$1 and DBD::$sqldb->{dbh}->{Driver}->{Name}.

.
ok( $sqldb and $type );
ok( $sqldb->detect_any );

########################################################################

INIT: {
  
  MyCDs->declare_tables;
  MyCDs->create_tables;

  DBIx::SQLEngine::Schema::Table->column_primary_is_sequence(1);
}

CREATE_RECORDS: {
  my $artist = MyCDs::Artist->new( 'name' => 'Underworld' )->save_record
	or die "Can't create artist record";
  MyCDs::Disc->new( 
      'name' => "Everything Everything", 'artist' => $artist,
  )->save_record() or die "Can't create disc record";

  $artist = MyCDs::Artist->new( 'name' => 'Fat Boy Slim' )->save_record
	or die "Can't create artist record";
  MyCDs::Disc->new( 
      'name' => "You've Come A Long Way, Baby", 'artist' => $artist,
  )->save_record() or die "Can't create disc record";

  $artist = MyCDs::Artist->new( 'name' => 'Kraftwerk' )->save_record
	or die "Can't create artist record";
  MyCDs::Disc->new( 
      'name' => "Ultra Rare Trax", 'artist' => $artist,
  )->save_record() or die "Can't create disc record";
  MyCDs::Disc->new( 
      'name' => "Trans Europa Express", 'artist' => $artist,
  )->save_record() or die "Can't create disc record";
  MyCDs::Disc->new( 
      'name' => "The Mix", 'artist' => $artist,
  )->save_record() or die "Can't create disc record";

  ok( MyCDs::Artist->count_rows, 3 );
  ok( MyCDs::Disc->count_rows, 5 );
}

########################################################################

my $rs = MyCDs::Disc->fetch_records( order => 'name' );
ok( $rs->count and scalar ( $rs->records ) );
foreach my $r ( $rs->records ) {
  # "CD " . $r->id . ": " . $r->name . " (" . ( $r->year || 'unknown' ) . ")"
}

my $disc = MyCDs::Disc->fetch_one( criteria => { 'name' => "Everything Everything" } );
ok( $disc->name eq "Everything Everything" );

# warn "Added to DB: " . $disc->added_to_db_readable() . "\n";
ok( $disc->added_to_db_readable =~ /200\d/ );

########################################################################

RESTRICT_DELETE: {

  my $artist = MyCDs::Artist->fetch_one(criteria => {'name'=>"Underworld"} );
  ok( $artist );

  ok( ! $artist->delete_record );
  ok( $artist = MyCDs::Artist->fetch_one(criteria => { 'name' => "Underworld" } ) );

  ok( $artist->count_discs );
  $artist->delete_discs;

  ok( ! $artist->count_discs );
  
  ok( $artist->delete_record );
  ok( ! MyCDs::Artist->fetch_one(criteria => { 'name' => "Underworld" } ) );
  
}

########################################################################

CLEANUP: {
  MyCDs->drop_tables;

  ok( 1 );
}

########################################################################

1;
