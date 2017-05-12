#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;
use Data::FormValidator;

my $input_profile = {
  required              => [qw( email_1  email_ok)],
  optional              => [qw/ extra first_name last_name /],
  constraint_regexp_map => {
    '/^email/' => "email",
  },
  field_filter_regexp_map => {
    '/_name$/' => 'ucfirst',
  } };

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  email_1    => 'invalidemail',
  email_ok   => 'mark@stosberg.com',
  extra      => 'unrelated field',
  first_name => 'mark',
  last_name  => 'stosberg',
};

my ( $valids, $missings, $invalids, $unknowns );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};
ok( not $@ );
ok( $invalids->[0] eq 'email_1' );

ok( $valids->{'email_ok'} );
ok( $valids->{'extra'} );
ok(     $valids->{'first_name'} eq 'Mark'
    and $valids->{'last_name'} eq 'Stosberg' );

# Tests below added 04/24/03 to test adding constraints to fields with existing constraints
eval {
  my ( $valids, $missings, $invalids ) = Data::FormValidator->validate(

    # input
    {
      with_no_constraint   => 'f1 text',
      with_one_constraint  => 'f2 text',
      with_mult_constraint => 'f2 text',
    },

    # profile
    {
      required =>
        [qw/with_no_constraint with_one_constraint with_mult_constraint/],
      constraints => {
        with_one_constraint  => 'email',
        with_mult_constraint => [ 'email', 'american_phone' ],
      },
      constraint_regexp_map => {
        '/^with/' => 'state',
      },
      msgs => {},
    } );
};

TODO:
{
  local $TODO = 'rewrite when message system is rebuilt';

#ok (not $@) ir diag $@;
#like($invalids->{with_no_constraint}, qr/Invalid/ ,   '...with no existing constraints');
#ok(scalar @{ $invalids->{with_one_constraint} } eq 2, '...with one existing constraint');
#ok(scalar @{ $invalids->{with_mult_constraint} } eq 3,'...with two existing constraints');
}
