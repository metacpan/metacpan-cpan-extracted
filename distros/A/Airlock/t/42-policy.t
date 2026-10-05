#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Airlock::Policy;

subtest 'empty policy' => sub {
  my $policy = Airlock::Policy->new;
  is_deeply( $policy->required( { scopes => [qw( read admin )] }, { id => 'a' } ), [], 'nothing required' );
  is( $policy->fresh( { id => 'a' }, 1000 ), 1, 'always fresh' );
};

subtest 'always and step_up' => sub {
  my $policy = Airlock::Policy->new(
    always  => ['upstream'],
    step_up => { admin => ['totp'], delete => [qw( totp pin )] }
  );
  is_deeply( $policy->required( { scopes => ['read'] }, {} ), ['upstream'], 'plain scope' );
  is_deeply( $policy->required( { scopes => [qw( read admin )] }, {} ), [qw( upstream totp )], 'step-up scope' );
  is_deeply( $policy->required( { scopes => [qw( admin delete )] }, {} ), [qw( upstream totp pin )], 'no duplicates, stable order' );
  is_deeply( $policy->required( { scopes => [] }, {} ), ['upstream'], 'no scopes' );
  is_deeply( $policy->required( {}, {} ), ['upstream'], 'request without scopes key' );
};

subtest 'decide' => sub {
  my @seen;
  my $policy = Airlock::Policy->new(
    step_up => { admin => ['totp'] },
    decide  => sub {
      my ( $request, $subject, $names ) = @_;
      push @seen, [ $request, $subject, [@$names] ];
      return $subject->{id} eq 'root' ? [ @$names, 'pin' ] : $names;
    }
  );
  is_deeply( $policy->required( { scopes => ['admin'] }, { id => 'root' } ), [qw( totp pin )], 'coderef extends the list' );
  is_deeply( $policy->required( { scopes => ['admin'] }, { id => 'alice' } ), ['totp'], 'coderef passes it through' );
  is_deeply( $seen[0], [ { scopes => ['admin'] }, { id => 'root' }, ['totp'] ], 'coderef gets request, subject, declarative list' );
};

subtest 'max_auth_age' => sub {
  my $policy = Airlock::Policy->new( max_auth_age => 300 );
  is( $policy->fresh( { auth_time => 700 }, 1000 ), 1, 'exactly at the limit' );
  is( $policy->fresh( { auth_time => 699 }, 1000 ), 0, 'one second over' );
  is( $policy->fresh( {}, 1000 ),                   0, 'no auth_time counts as too old' );
  is( $policy->fresh( { auth_time => 1060 }, 1000 ), 1, 'a minute in the future is clock drift' );
  is( $policy->fresh( { auth_time => 1061 }, 1000 ), 0, 'further in the future is not a login' );
};

done_testing;
