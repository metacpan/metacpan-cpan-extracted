#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Store::Memory;
use Airlock::Test::Store;

my $memory = Airlock::Store::Memory->new;

Airlock::Test::Store->new( store => $memory->as_subs )->run;

subtest 'rows are copied in and out' => sub {
  my $fresh = Airlock::Store::Memory->new;
  my $row   = Airlock::Test::Store->new( store => $fresh->as_subs )->row;
  $fresh->insert($row);
  $row->{state} = 'tampered';
  is( $fresh->find( 'hash', 'airlock-test-1' )->{state}, 'pending', 'changing the inserted hash does not reach the store' );
  my $found = $fresh->find( 'hash', 'airlock-test-1' );
  $found->{state} = 'tampered';
  is( $fresh->find( 'hash', 'airlock-test-1' )->{state}, 'pending', 'changing a found row does not reach the store' );
};

subtest 'find refuses unknown fields' => sub {
  ok( !eval { $memory->find( 'client_id', 'client' ); 1 }, 'croaks' );
  like( $@, qr/find by client_id is not supported/, 'and says why' );
};

subtest 'refuses to be used across a fork' => sub {
  my $shared = Airlock::Store::Memory->new;
  my $pid    = fork;
  die 'fork failed: '.$! unless defined $pid;
  if ( !$pid ) {
    my $croaked = eval { $shared->find( 'hash', 'x' ); 1 } ? 0 : $@ =~ /used in another process/ ? 1 : 0;
    exit( $croaked ? 0 : 1 );
  }
  waitpid $pid, 0;
  is( $? >> 8, 0, 'the child croaks instead of looking into its own copy' );
  is( $shared->find( 'hash', 'x' ), undef, 'the parent keeps working' );
};

done_testing;
