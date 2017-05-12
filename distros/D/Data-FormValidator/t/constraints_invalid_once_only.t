#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;
use Data::FormValidator;

# this test checks that a failing constraint is only marked as invalid once

sub check_passwords
{
  my ( $dfv, $val ) = @_;
  my $passwords = $dfv->{__INPUT_DATA}->{password};
  if ( ref($passwords) eq 'ARRAY' )
  {
    if ( $$passwords[0] eq $$passwords[1] )
    {
      return 1;
    }
    return 0;
  }
  return 1;
}

my %data = ( 'password' => [ '123456', '123457' ], );

my %profile = (
  optional           => [qw/password/],
  constraint_methods => {
    password => \&check_passwords,
  },
);

my $results = Data::FormValidator->check( \%data, \%profile );

my $invalid    = $results->{invalid};
my $duplicated = {};
my $has_duplicates;
foreach ( @{ $invalid->{password} } )
{
  next unless $_;
  if ( exists $duplicated->{$_} )
  {
    $has_duplicates = 1;
    last;
  }
  $duplicated->{$_} = 1;
}
ok( !$has_duplicates, 'constraint marked as invalid only once' );
