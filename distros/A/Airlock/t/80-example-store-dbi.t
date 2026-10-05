#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'DBI and DBD::SQLite are needed for this example'
    unless eval { require DBI; require DBD::SQLite; 1 };
}

use Path::Tiny qw( path );
use Airlock;
use Airlock::Test::Store;
use AirlockExample::StoreDBI;

sub database {
  my $dbh = DBI->connect( 'dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 } );
  $dbh->do($_) for grep { /\S/ } split /;/, path('examples/schema.sql')->slurp_utf8 =~ s/^--.*$//mgr;
  return $dbh;
}

subtest 'store contract' => sub {
  Airlock::Test::Store->new( store => AirlockExample::StoreDBI->new( dbh => database() )->as_subs )->run;
};

subtest 'a whole flow on the database' => sub {
  my $dbh     = database();
  my $clock   = 1_000_000;
  my $airlock = Airlock->new(
    clients          => { cli => {} },
    verification_uri => 'https://example.org/airlock',
    store            => AirlockExample::StoreDBI->new( dbh => sub { $dbh } )->as_subs,
    now              => sub { $clock }
  );
  my $start = $airlock->open( client_id => 'cli', scope => 'read' )->data;
  is( $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->status, 'authorization_pending', 'pending' );
  ok( $airlock->approve( $start->{user_code}, subject => { id => 'alice', amr => [qw( pwd otp )] } )->ok, 'approved' );
  $clock += 5;
  my $token = $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->data->{access_token};
  is_deeply( $airlock->verify_token($token)->{amr}, [qw( pwd otp )], 'the token verifies from the database' );
  is( $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'redeemed once' );
  my ( $secrets ) = $dbh->selectrow_array( 'SELECT COUNT(*) FROM airlock WHERE hash IN (?, ?)', undef, $start->{device_code}, $token );
  is( $secrets, 0, 'neither the device code nor the token is in the table' );
  $clock += 4000;
  is( $airlock->purge, 2, 'purge removes request and token' );
};

done_testing;
