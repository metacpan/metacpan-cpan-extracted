#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 4;
use Data::FormValidator;

my %FORM = (
  good  => '1',
  extra => '2',
);

my $results = Data::FormValidator->check(
  \%FORM,
  {
    required => 'good',
  } );

ok( $results->success, 'success with unknown' );

{
  my $false;
  $results || ( $false = 1 );
  ok( !$false, "returns true in bool context on success" );
}

# test an unsuccessful success
$FORM{bad} = -1;
$results = Data::FormValidator->check(
  \%FORM,
  {
    required    => [qw(good bad)],
    optional    => [qw(extra)],
    constraints => {
      good => sub { return shift > 0 },
      bad  => sub { return shift > 0 },
    },
  },
);

ok( !$results->success, 'not success()' );

{
  my $false;
  $results || ( $false = 1 );
  ok( $false, "returns false in bool context on not success" );
}
