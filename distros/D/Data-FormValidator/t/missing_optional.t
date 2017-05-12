#!/usr/bin/env perl
use strict;
use warnings;
use Test::More 'no_plan';
use Data::FormValidator;

# Tests for missing_optional_valid
my $input_profile = {
  required              => [qw( email_1  email_ok)],
  optional              => [ 'filled', 'not_filled' ],
  constraint_regexp_map => {
    '/^email/' => "email",
  },
  constraints => {
    not_filled => 'phone',
  },
  missing_optional_valid => 1,
};

my $validator = new Data::FormValidator( { default => $input_profile } );

my $input_hashref = {
  email_1           => 'invalidemail',
  email_ok          => 'mark@stosberg.com',
  filled            => 'dog',
  not_filled        => '',
  should_be_unknown => 1,
};

my ( $valids, $missings, $invalids, $unknowns );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};
is( $@, '', "survived eval" );

# "not_filled" should appear valids now.
ok( exists $valids->{'not_filled'} );

# "should_be_unknown" should be still be unknown
ok( $unknowns->[0] eq 'should_be_unknown' );

eval { require CGI;CGI->VERSION(4.35); };
SKIP:
{
  skip 'CGI 4.35 or higher not found', 3 if $@;

  my $q = CGI->new($input_hashref);
  my ( $valids, $missings, $invalids, $unknowns );
  eval {
    ( $valids, $missings, $invalids, $unknowns ) =
      $validator->validate( $q, 'default' );
  };

  ok( not $@ );

  # "not_filled" should appear valids now.
  ok( exists $valids->{'not_filled'} );

  # "should_be_unknown" should be still be unknown
  ok( $unknowns->[0] eq 'should_be_unknown' );

}

{
  my $res = Data::FormValidator->check( {
      a => 1,
      b => undef,

      # c is completely missing
    },
    {
      optional               => [qw/a b c/],
      missing_optional_valid => 1
    } );

  is( join( ',', sort $res->valid() ),
    'a,b', "optional fields have to at least exist to be valid" );
}

{
  my $data = { optional_invalid => 'invalid' };

  my $profile = {
    optional    => [qw/optional_invalid/],
    constraints => {
      optional_invalid => qr/^valid$/
    },
    missing_optional_valid => 1
  };

  my $results = Data::FormValidator->check( $data, $profile );
  my $valid   = $results->valid();
  my $invalid = $results->invalid();
  ok( exists $invalid->{'optional_invalid'}, 'optional_invalid is invalid' );
  ok( !exists $valid->{'optional_invalid'},  'optional_invalid is not valid' );
}
