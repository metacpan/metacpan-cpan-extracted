#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 13;
use Data::FormValidator;

# Integration with Regexp::Common;

my %FORM = (
  bad_ip      => '127 0 0 1',
  good_ip     => '127.0.0.1',
  embedded_ip => 'The address is 127.0.0.1 or something close to that',
  valid_int   => 0,
);

my $results;

BEGIN { use_ok( 'Data::FormValidator::Constraints', qw/:regexp_common/ ) }

eval {
  $results = Data::FormValidator->check(
    \%FORM,
    {
      required                     => [qw/good_ip bad_ip valid_int/],
      constraint_method_regexp_map => {
        qr/_ip$/ => FV_net_IPv4(),
      },
      constraint_methods => {
        valid_int => FV_num_int(),
      } } );
};
is( $@, '', 'survived eval' );
ok( $results->valid->{good_ip},  'good ip' );
ok( $results->invalid->{bad_ip}, 'bad ip' );
is( $results->valid->{valid_int}, 0, 'zero is valid int' );

$results = Data::FormValidator->check(
  \%FORM,
  {
    untaint_all_constraints      => 1,
    required                     => [qw/good_ip bad_ip valid_int/],
    constraint_method_regexp_map => {
      qr/_ip$/ => FV_net_IPv4(),
    },
    constraint_methods => {
      valid_int => FV_num_int(),
    } } );

is( $@, '', 'survived eval' );
ok( $results->valid->{good_ip},  'good ip with tainting' );
ok( $results->invalid->{bad_ip}, 'bad ip with tainting' );
is( $results->valid->{valid_int}, 0, 'zero is valid int with untainting' );

# Test passing flags
$results = Data::FormValidator->check(
  \%FORM,
  {
    required                     => [qw/good_ip bad_ip/],
    constraint_method_regexp_map => {
      qr/_ip$/ => FV_net_IPv4_dec( -sep => ' ' ),
    } } );

ok( ( not $@ ), 'runtime errors' ) or diag $@;

# Here we are trying passing a parameter which should reverse
# the notion of which one expect to succeed.
ok( $results->valid->{bad_ip},    'expecting success with params' );
ok( $results->invalid->{good_ip}, 'expecting failure with params' );

# Testing end-to-end matching
$results = Data::FormValidator->check(
  \%FORM,
  {
    required                     => [qw/embedded_ip/],
    constraint_method_regexp_map => {
      qr/_ip$/ => FV_net_IPv4(),
    } } );
my $invalid = scalar $results->invalid || {};
ok( $invalid->{embedded_ip}, 'testing that the RE must match from end-to-end' );
