#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;
use Data::FormValidator;

# This test is to confirm that values are preserved
# for input data when used with multiple constraints
# as 'params'

# note: this relies on the constraint built_to_fail
# being evaluated before expected_to_succeed. Which
# relies on the order on which perl returns the keys
# from each %{ $profile->{constraints} }

my %data = (
  'depart_date' => '2004',
  'return_date' => '2005',
);

my %profile = (
  required => [
    qw/
      depart_date
      return_date
      /
  ],
  field_filters => {
    depart_date => sub { my $v = shift; $v =~ s/XXX//; $v; }
  },
  constraints => {
    depart_date => {
      name       => 'expected_to_succeed',
      params     => [qw/depart_date return_date/],
      constraint => sub {
        my ( $depart, $return ) = @_;
        Test::More::is( $depart, '2004' );
        Test::More::is( $return, '2005' );
        return ( $depart < $return );
      },
    },
    return_date => {
      name       => 'built_to_fail',
      params     => [qw/depart_date return_date/],
      constraint => sub {
        my ( $depart, $return ) = @_;
        Test::More::is( $depart, '2004' );
        Test::More::is( $return, '2005' );
        return ( $depart > $return );
      },
    },
  },
  missing_optional_valid => 1,
  msgs                   => {
    format      => 'error(%s)',
    constraints => {
      'valid_date'       => 'bad date',
      'depart_le_return' => 'depart is greater than return',
    },
  },
);

my $results = Data::FormValidator->check( \%data, \%profile );

ok( !$results->valid('return_date'),
  'first constraint applied intentionally fails' );
ok( $results->valid('depart_date'),
  'second constraint still has access to value of field used in first failed constraint.'
);

# The next test are to confirm when a constraint method returns 'undef'
# that it causes no warnings to be issued
{
  my %profile = (
    required    => ['foo'],
    constraints => {
      foo => {
        constraint => sub {
          return;
        },
      },
    },
    untaint_all_constraints => 1,
  );

  my $err = '';
  local *STDERR;
  open STDERR, '>', \$err;
  my $results = Data::FormValidator->check( { foo => 1 }, \%profile );
  is( $err, '', 'no warnings emitted' );

}
