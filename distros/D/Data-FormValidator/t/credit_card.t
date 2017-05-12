#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 25;
use Data::FormValidator;
use Data::FormValidator::Constraints qw(:closures);

# check credit card number validation (the cc_number constraint).
# note: this constraint is checked directly in 11_procedural_match.t and
# procedural_valid.t, but here we will test it indirectly through a profile

my $dfv_profile_old = {
  required    => [qw(credit_card_type credit_card_number)],
  constraints => {
    credit_card_number => {
      constraint => 'cc_number',
      params     => [qw(credit_card_number credit_card_type)],
    },
  },
};

# numbers from
# http://www.verisign.com/support/payflow/manager/selfHelp/testCardNum.html
# maps type  => [ [ invalids ... ], [ valids ... ] ]
my %cc_numbers = (
  Visa =>
    [ [ '4000111122223333', ], [ '4111111111111111', '4012888888881881', ] ],

  Mastercard =>
    [ [ '5424111122223333', ], [ '5105105105105100', '5555555555554444', ] ],

  Discover =>
    [ [ '6000111122223333', ], [ '6011111111111117', '6011000990139424', ] ],

  Amex => [ [ '371500001111222', ], [ '378282246310005', '371449635398431', ] ],
);

while ( my ( $card_type, $numbers ) = each %cc_numbers )
{
  foreach my $is_valid ( 0 .. 1 )
  {
    foreach my $n ( @{ $numbers->[$is_valid] } )
    {
      my $msg = ( $is_valid ? "Valid" : "Invalid" ) . ": $card_type/$n";
      my $input = {
        credit_card_type   => $card_type,
        credit_card_number => $n,
      };

      is( validate_q( $input, $dfv_profile_old ), $is_valid, "$msg (old)" );
    }
  }
}

my $dfv_profile_new = eval { {
    required           => [qw(credit_card_type credit_card_number)],
    constraint_methods => {
      credit_card_number => cc_number( { fields => ['credit_card_type'] } ),
    },
  };
};

ok( !$@, "cc_number subroutine runs without error" );

# broken cc_number subroutine in older dfv
SKIP:
{
  skip "(Older DFV has broken cc_number subroutine)", 12 if $@;

  while ( my ( $card_type, $numbers ) = each %cc_numbers )
  {
    foreach my $is_valid ( 0 .. 1 )
    {
      foreach my $n ( @{ $numbers->[$is_valid] } )
      {
        my $msg = ( $is_valid ? "Valid" : "Invalid" ) . ": $card_type/$n";
        my $input = {
          credit_card_type   => $card_type,
          credit_card_number => $n,
        };

        is( validate_q( $input, $dfv_profile_new ), $is_valid, "$msg (new)" );
      }
    }
  }
}

##

sub validate_q
{
  my ( $data, $profile ) = @_;

  my $dfv_result = eval { Data::FormValidator->check( $data, $profile ); };

  if ($@)
  {
    diag "Failed check [$@]";
    return;
  }

  return ( $dfv_result->has_invalid || $dfv_result->has_missing ) ? 0 : 1;
}
