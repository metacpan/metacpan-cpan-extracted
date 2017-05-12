#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;
use lib ( '.', '../t' );
use Data::FormValidator;

# Verify that multiple params passed to a constraint are being handled correctly
my $validator = new Data::FormValidator( {
    default => {
      required    => [qw/my_zipcode_field my_other_field/],
      constraints => {
        my_zipcode_field => {
          constraint => \&zipcode_check,
          name       => 'zipcode',
          params     => [ 'my_zipcode_field', 'my_other_field' ],
        },
      },
    },
  } );

my @args_for_check;    # to control which args were given

sub zipcode_check
{
  @args_for_check = @_;
  if ( $_[0] == 402015 and $_[1] eq 'mapserver_rulez' )
  {
    return 1;
  }
  return 0;
}

my $input_hashref = {
  my_zipcode_field => '402015',
  my_other_field   => 'mapserver_rulez',
};

my ( $valids, $missings, $invalids, $unknowns );

eval {
  ( $valids, $missings, $invalids, $unknowns ) =
    $validator->validate( $input_hashref, 'default' );
};

ok( not $@ )
  or diag "eval error: $@";

ok( not grep { ( ref $_ ) eq 'ARRAY' } @$invalids )
  or diag $#{$invalids};

is_deeply( \@args_for_check, [ 402015, 'mapserver_rulez' ] );

# Local variables:
# compile-command: "cd .. && make test"
# End:
