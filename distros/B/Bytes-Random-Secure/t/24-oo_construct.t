## no critic (RCS,VERSION,encapsulation,Module,eval,constant)

use strict;
use warnings;
use Test::More;


# We only test code that can generate warnings if Test::Warn is available to
# trap and examine the warnings.  Install Test::Warn for full test coverage.
BEGIN{ $main::test_warn = eval 'use Test::Warn; 1;'; }
use constant SKIP_WHY   => 'Test::Warn required for full test coverage.';

use 5.006000;

use Bytes::Random::Secure;


# Test the constructor, and its helper functions.

# There are also a few "private functions" tests that do not pertain directly
# to the constructor.

can_ok( 'Bytes::Random::Secure',
        qw/ new                     _build_args         _validate_args
            _round_bits_to_ge_32    _constrain_bits     _build_attributes
            _build_seed_options     _generate_seed      _instantiate_rng
            _validate_int                                                 / );


# A dummy source so we don't drain entropy.
# Note, this will result in four identical longs: 1633771873.
sub null_source { return join( '', 'a' x shift ); }

# Instantiate with a dummy callback so we don't drain entropy.
my $random = new_ok 'Bytes::Random::Secure' => [
  Source      => \&null_source,
  Weak        => 1,
  NonBlocking => 1,
  Bits        => 128,
];

#######################
# Test _build_args(): #
#######################

# Test when hashref is passed in.
my $args_ref = $random->_build_args( { Weak => 1 } );
is( ref( $args_ref ), 'HASH', '_build_args(): Hashref param returns a hashref.' );
is( scalar keys %{$args_ref}, 1,
    '_build_args(): One named param in, one named param out.' );
ok( exists $args_ref->{Weak},
    '_build_args() We got the proper arg back from hashref.' );

$args_ref = $random->_build_args( Weak => 1 );
is( ref( $args_ref ), 'HASH',
    '_build_args(): Flat key/value list in, hashref out.' );
is( scalar keys %{$args_ref}, 1,
    '_build_args(): One key/value in, hashref of one key/value out.' );
ok( exists $args_ref->{Weak},
    '_build_args(): We got the proper arg back from flat list.' );

ok( ! eval { $random->_build_args( 'Weak' ); 1; },
    '_build_args(): Croak when passed odd length param list.' );

like( $@, qr/key\s=>\svalue\spairs\sexpected/,
      '_build_args(): Correct exception thrown for odd length param list.' );

$args_ref = $random->_build_args( { Weak => 1, NonBlocking => 1 } );
is( scalar keys %{$args_ref}, 2,
    '_build_args(): Passed in two args, got two back.' );

$args_ref = $random->_build_args();
is( scalar keys %{$args_ref}, 0,
    '_build_args(): No args in, none out.' );

#########################
# Test _validate_args() #
#########################

my %validated = $random->_validate_args( { valid => 1 }, valid => 2 );
ok( $validated{valid} == 2,
    '_validate_args(): Passed in a valid arg and got it back.' );

SKIP: {
  skip SKIP_WHY, 2, unless $main::test_warn;

  warning_like {
    %validated = $random->_validate_args( { valid => 1 }, invalid => 1 )
  } qr/^Illegal argument \(invalid\)/, "_validate_args(): Invalid warns.";

  ok( 0 == scalar keys %validated, '_validate_args(): Invalid args ignored.' );

}



SKIP: {
  skip SKIP_WHY, 2, unless $main::test_warn;

  warning_like {
    %validated = $random->_validate_args( { valid => 1 }, valid => undef )
  } qr/^Undefined value specified for attribute \(valid\)/,
    "_validate_args(): Undefined attribute value warns.";

  ok( 0 == scalar keys %validated,
      '_validate_args(): Args dropped if value is undefined.' );

}


###############################
# Test _round_bits_to_ge_32() #
###############################

is( $random->_round_bits_to_ge_32(32), 32,
    '_round_bits_to_ge_32(32): Returns 32' );
is( $random->_round_bits_to_ge_32(0),  0,
    '_round_bits_to_ge_32(0):   Returns 0 (never occurs)' );

SKIP: {
  skip SKIP_WHY, 4 unless $main::test_warn;
  
  my $got;
  warning_like { $got = $random->_round_bits_to_ge_32(1) }
               qr/^Bits field must be a multiple of 32\./,
               '_round_bits_to_ge_32Rounding up of bits generates warning.';

  is( $got,  32, '_round_bits_to_ge_32(1):  Returns 32' );

  warning_like { $got = $random->_round_bits_to_ge_32(33) }
               qr/^Bits field must be a multiple of 32\./,
               '_round_bits_to_ge_32Rounding up of bits generates warning.';

  is( $got,  64, '_round_bits_to_ge_32(33):  Returns 64' );

}

is( $random->_round_bits_to_ge_32(512), 512,
    '_round_bits_to_ge_32(512): Returns 512' );

##########################
# Test _constrain_bits() #
##########################

SKIP: {
  skip SKIP_WHY, 4 unless $main::test_warn;

  my $bits = 0;

  warning_like {
    $bits = $random->_constrain_bits( 63, 64, 512 );
  }  qr/^Bits field must be >= 64/, '_constrain_bits(63,64,512) warns.';

  is( $bits, 64, '_constrain_bits(): underflow rounds to in-range.' );

  warning_like {
    $bits = $random->_constrain_bits( 8193, 64, 512 );
  }  qr/^Bits field must be <= 8192/, '_constrain_bits(8193,64,512)warns';

  is( $bits, 512, '_constrain_bits(): overflow rounds to in-range.' );

}

is( $random->_constrain_bits( 128, 64, 512 ), 128,
    '_constrain_bits(128,64,512) returns input unchanged.' );


##############################
# Test _build_seed_options() #
##############################

is_deeply( { $random->_build_seed_options() },
           { NonBlocking => 1, Weak => 1, Source => \&null_source },
           "_build_seed_options(): Options hash returned."               );


#########################
# Test _generate_seed() #
#########################

is( scalar @{[$random->_generate_seed( Source => \&null_source )]}, 4,
    '_generate_seed() returns four longs when seed size set to 128 bits.' );

my $crs = undef;
eval { $crs = $random->_generate_seed( Only => [] ); };
like( $@, qr/Unable to obtain a strong seed source/,
      '_generate_seed(): If unable to seed appropriately, throw exception.' );

ok( ! defined $crs, '_generate_seed(): Nothing returned if unable to seed.' );

###########################
# Test _instantiate_rng() #
###########################

is( ref $random->_instantiate_rng(), 'Math::Random::ISAAC',
    '_instantiate_rng(): Default RNG is Math::Random::ISAAC' );

########################
# Test _validate_int() #
########################

ok( eval { $random->_validate_int(1); 1; },
    '_validate_int(1): Legitimate positive int passes.' );

ok( eval { $random->_validate_int( 0 ); 1; },
    '_validate_int(0): Allow zero.' );


{
  local $@;
  eval {
    $random->_validate_int( { Illegal => 1 } );
  };
  like( $@, qr/Byte count must be a positive integer/,
        '_validate_int(): Non integer input throws.' );
}

{
  local $@;
  eval {
    $random->_validate_int( 'illegal' );
  };
  like( $@, qr/Byte count must be a positive integer/,
        '_validate_int(): Must "look like a number".' );
}

{
  local $@;
  eval {
    $random->_validate_int( -1 );
  };
  like( $@, qr/Byte count must be a positive integer/,
        '_validate_int(-1): Must be >= 0.' );
}

{
  local $@;
  eval {
    $random->_validate_int( 1.5 );
  };
  like( $@, qr/Byte count must be a positive integer/,
        '_validate_int(1.5): Must be an integer.' );
}

done_testing();
