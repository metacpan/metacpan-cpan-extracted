#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use Data::FormValidator;

# Friendy error messages when quality_to_ref fails due to a typo. -mls 05/03/03
my %FORM = (
  bad_email  => 'oops',
  good_email => 'great@domain.com',

  'short_name' => 'tim',
);

my $results;

eval {
  $results = Data::FormValidator->check(
    \%FORM,
    {
      required => 'good_email',
      filters  => 'grim',         # testing filter typo
    } );
};
like( $@, qr/found named/, 'happy filters typo failure' );

eval {
  $results = Data::FormValidator->check(
    \%FORM,
    {
      required      => 'good_email',
      field_filters => {
        'good_email' => 'grim',    # testing filter typo
      },
    } );
};
like( $@, qr/found named/, 'happy field_filters typo failure' );

eval {
  $results = Data::FormValidator->check(
    \%FORM,
    {
      required                => 'good_email',
      field_filter_regexp_map => {
        qr/_email$/ => 'grim',     # testing filter typo
      },
    } );
};
like( $@, qr/found named/, 'happy field_filter_regexp_map typo failure' );

eval {
  $results = Data::FormValidator->check(
    \%FORM,
    {
      required    => 'good_email',
      constraints => {
        good_email => 'e-mail',    # typo in constraint name
      } } );
};
like( $@, qr/found named/, 'happy constraints typo failure' );

eval {
  $results = Data::FormValidator->check(
    \%FORM,
    {
      required                => 'good_email',
      untaint_all_constraints => 1,
      constraints             => {
        good_email => 'e-mail',    # typo in constraint name
      } } );
};
like( $@, qr/found named/, 'happy untainted constraints typo failure' );
