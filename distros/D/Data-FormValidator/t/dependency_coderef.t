#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 18;
use Data::FormValidator;

my %code_results  = ();
my $input_hashref = {};
my $input_profile = {
  dependencies => {
    cc_type => sub {
      my $dfv  = shift;
      my $type = shift;

      return ['cc_cvv'] if ( $type eq "VISA" || $type eq "MASTERCARD" );
      return [];
    },

    code_checker => sub {
      my ( $dfv, $val ) = @_;

      $code_results{'code_called'} = 1;
      $code_results{'num_args'}    = @_;
      $code_results{'value'}       = $val;
      $code_results{'dfv_obj'}     = $dfv;

      return [];
    },
  },
};

my $validator = Data::FormValidator->new( { default => $input_profile } );
my $result;

##
## Validate a coderef dependency
##

## Check that the code actually gets called.
#############################################################################

$input_hashref->{code_checker} = 'test';
$result = undef;
eval { $result = $validator->check( $input_hashref, 'default' ); };

ok( !$@,                        "checking that dependency coderef is called" );
ok( $code_results{code_called}, "  code was called" );
is( $code_results{num_args}, 2,      "  code received 2 args" );
is( $code_results{value},    'test', "  received correct value" );
ok( $code_results{dfv_obj}, "  received dfv object" );
isa_ok( $code_results{dfv_obj}, 'Data::FormValidator::Results',
  "  dfv object" );

delete $input_hashref->{code_checker};

## Value that should cause a missing dependency.
#############################################################################

$input_hashref->{cc_type} = 'VISA';
$result = undef;
eval { $result = $validator->check( $input_hashref, 'default' ); };

ok( !$@, "checking a value that has a depenency" );
isa_ok( $result, "Data::FormValidator::Results", "  returned object" );
ok( $result->has_missing,       "  has_missing returned true" );
ok( $result->missing('cc_cvv'), "  missing('cc_cvv') returned true" );

## Value that should NOT cause a missing dependency.
#############################################################################

$input_hashref->{cc_type} = 'AMEX';
$result = undef;
eval { $result = $validator->check( $input_hashref, 'default' ); };

ok( !$@, "checking a value that has no dependencies" );
isa_ok( $result, "Data::FormValidator::Results", "  returned object" );
ok( !$result->has_missing, "  has_missing returned false" );
is( $result->missing('cc_cvv'), undef, "  missing('cc_cvv') returned false" );

## Test with multiple values
#############################################################################

$input_hashref->{cc_type} = [ 'AMEX', 'VISA' ];
$result = undef;
eval { $result = $validator->check( $input_hashref, 'default' ); };

ok( !$@, "checking multiple values" );
isa_ok( $result, "Data::FormValidator::Results", "  returned object" );
ok( $result->has_missing, "  has_missing returned true" );
is( $result->missing('cc_cvv'), 1, "  missing('cc_cvv') returned true" );
