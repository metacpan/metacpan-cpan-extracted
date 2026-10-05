#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'examples/lib';

BEGIN {
  plan skip_all => 'DBIO and DBD::SQLite are needed for this example'
    unless eval { require DBIO; require DBD::SQLite; 1 };
}

use Path::Tiny qw( path );
use Airlock;
use Airlock::Test::Store;
use AirlockExample::Schema;
use AirlockExample::StoreDBIO;

sub schema {
  my $schema = AirlockExample::Schema->connect( 'dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 } );
  my @ddl    = grep { /\S/ } split /;/, path('examples/schema.sql')->slurp_utf8 =~ s/^--.*$//mgr;
  $schema->storage->dbh_do( sub { $_[1]->do($_) for @ddl } );
  return $schema;
}

subtest 'store contract' => sub {
  Airlock::Test::Store->new( store => AirlockExample::StoreDBIO->new( schema => schema() )->as_subs )->run;
};

subtest 'a whole flow on the schema' => sub {
  my $schema  = schema();
  my $clock   = 1_000_000;
  my $airlock = Airlock->new(
    clients          => { cli => {} },
    verification_uri => 'https://example.org/airlock',
    store            => AirlockExample::StoreDBIO->new( schema => $schema )->as_subs,
    now              => sub { $clock }
  );
  my $start = $airlock->open( client_id => 'cli', scope => 'read' )->data;
  ok( $airlock->approve( $start->{user_code}, subject => { id => 'alice' } )->ok, 'approved' );
  my $token = $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->data->{access_token};
  is( $airlock->verify_token($token)->{subject}, 'alice', 'the token verifies from the schema' );
  is( $airlock->redeem( device_code => $start->{device_code}, client_id => 'cli' )->status, 'invalid_grant', 'redeemed once' );
  is( $schema->resultset('Airlock')->search( { hash => [ $start->{device_code}, $token ] } )->count, 0, 'no secret in the table' );
};

done_testing;
