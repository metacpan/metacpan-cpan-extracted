#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 10;
use Data::FormValidator;

# Integration with Regexp::Common;
my %FORM = (
  bad_ip      => '127 0 0 1',
  good_ip     => '127.0.0.1',
  embedded_ip => 'The address is 127.0.0.1 or something close to that',
);

my $results;

eval {
  $results = Data::FormValidator->check(
    \%FORM,
    {
      required              => [qw/good_ip bad_ip/],
      constraint_regexp_map => {
        qr/_ip$/ => 'RE_net_IPv4',

      } } );
};
ok( ( not $@ ), 'runtime errors' ) or diag $@;
ok( $results->valid->{good_ip},  'good ip' );
ok( $results->invalid->{bad_ip}, 'bad ip' );

$results = Data::FormValidator->check(
  \%FORM,
  {
    untaint_all_constraints => 1,
    required                => [qw/good_ip bad_ip/],
    constraint_regexp_map   => {
      qr/_ip$/ => 'RE_net_IPv4',

    } } );

ok( ( not $@ ), 'runtime errors' ) or diag $@;
ok( $results->valid->{good_ip},  'good ip with tainting' );
ok( $results->invalid->{bad_ip}, 'bad ip with tainting' );

# Test passing flags
$results = Data::FormValidator->check(
  \%FORM,
  {
    required              => [qw/good_ip bad_ip/],
    constraint_regexp_map => {
      qr/_ip$/ => {
        constraint => 'RE_net_IPv4_dec',
        params     => [ \'-sep' => \' ' ],
      } } } );

ok( ( not $@ ), 'runtime errors' ) or diag $@;

# Here we are trying passing a parameter which should reverse
# the notion of which one expect to succeed.
ok( $results->valid->{bad_ip},    'expecting success with params' );
ok( $results->invalid->{good_ip}, 'expecting failure with params' );

# Testing end-to-end matching
$results = Data::FormValidator->check(
  \%FORM,
  {
    required              => [qw/embedded_ip/],
    constraint_regexp_map => {
      qr/_ip$/ => 'RE_net_IPv4',
    } } );
my $invalid = scalar $results->invalid || {};
ok( $invalid->{embedded_ip}, 'testing that the RE must match from end-to-end' );
