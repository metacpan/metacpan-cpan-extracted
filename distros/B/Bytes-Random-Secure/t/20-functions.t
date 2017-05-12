## no critic (RCS,VERSION,encapsulation,Module)

use strict;
use warnings;

use Test::More;

use 5.006000;

BEGIN{

  @main::functions = qw/ random_bytes           random_bytes_hex
                         random_bytes_base64    random_bytes_qp
                         random_string_from                     /;

  use_ok( 'Bytes::Random::Secure', @main::functions );

}

can_ok( 'Bytes::Random::Secure', @main::functions ); # Fully qualified.
can_ok( 'main', @main::functions );                  # Imported.



foreach my $want ( qw/ 0 1 2 3 4 5 6 7 8 16 17 1024 10000 / ) {
  my $correct = $want >= 0 ? $want : 0;
  is( length random_bytes( $want ), $correct,
      "random_bytes($want) returns $correct bytes." );
}


{
  local $@;
  eval {
    my $bytes = random_bytes( -1 );
  };

  like( $@, qr/Byte count must be a positive integer/,
        'random_bytes: requesting negative byte count throws an exception.' );
}

{
  local $@;
  eval {
    my $bytes = random_bytes( { Illegal => 1 } );
  };
  like( $@, qr/Byte count must be a positive integer/,
        'random_bytes: Non-integer input throws an exception.' );
}


# random_bytes_hex (and _lite) tests.

foreach my $want ( qw/ 0 1 2 3 4 5 6 7 8 16 17 1024 10000 / ) {
  my $result  = random_bytes_hex( $want );
  my $correct = $want >= 0 ? $want * 2 : 0;
  is( length random_bytes_hex( $want ), $correct,
      "random_bytes_hex($want) returned $correct hex digits." );
};

ok( random_bytes_hex(128) =~ /^[[:xdigit:]]+$/,
    'random_bytes_hex only produces hex digits.' );



# random_bytes_base64 (and _lite) tests.

is( length random_bytes_base64(0),  0,
    'random_bytes_base64(0) returns an empty string.'  );


ok( length random_bytes_base64(1) > 0,
    'random_bytes_base64(1) returns a string of some non-zero length.' );


ok( length random_bytes_base64(5) < length random_bytes_base64( 16 ),
    'random_bytes_base64(5) returns a shorter string than ' .
    'random_bytes_base64(16)'                                );


ok( random_bytes_base64(128) =~ /^[^\n]{76}\n/,
    'random_bytes_base64 uses "\n" appropriately' );

ok( random_bytes_base64(128, q{}) =~ /^[^\n]+$/,
    'random_bytes_base64 passes EOL delimiter correctly.' );



# random_bytes_qp (and _lite) tests.


is( length random_bytes_qp(0),  0,
    'random_bytes_qp(0) returns an empty string.'  );


ok( length random_bytes_qp(1) > 0,
    'random_bytes_qp(1) returns a string of some non-zero length.' );


ok( length random_bytes_qp(5) < length random_bytes_qp( 16 ),
    'random_bytes_qp(5) returns a shorter string than ' .
    'random_bytes_qp(16)'                                );


ok( random_bytes_qp(100) =~ m/^[^\n]{1,76}\n/,
    'random_bytes_qp uses "\n" appropriately' );


ok( random_bytes_qp(128, q{}) =~ /^[^\n]+$/,
    'random_bytes_qp passes EOL delimiter correctly.' );


is( length random_bytes(), 0,
    'random_bytes(): No param defaults to zero bytes.' );



# Basic tests for random_string_from
# (More exhaustive tests in 22-random_string_from.t)

my $MAX_TRIES = 1_000_000;
my %bag;
my $tries = 0;
while( scalar( keys %bag ) < 26 && $tries++ < $MAX_TRIES ) {
  $bag{ random_string_from( 'abcdefghijklmnopqrstuvwxyz', 1 ) }++;
}

is( scalar( keys %bag ), 26,
   'random_string_from() returned all bytes from bag, and only bytes from bag.'
);

ok( ! scalar( grep{ $_ =~ m/[^abcdefghijklmnopqrstuvwxyz]/ } keys %bag ),
    'No out of range characters in output.' );
like( random_string_from( 'abc', 100 ), qr/^[abc]{100}$/,
      'random_string_from() returns only correct digits, and length.' );


done_testing();
