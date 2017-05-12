use strict;
use warnings;
use utf8;

use Bytes::Random::Secure qw( random_string_from );

my $quantity = 64;

my $bag = 'abcde';

# Generate a random string of 64 characters, each selected from
# the "bag" of 'a' through 'e', inclusive.

my $string = random_string_from( $bag, $quantity );

print $string, "\n";

# Unicode strings are ok too (Perl 5.8.9 or better):

if( $^V && $^V ge v5.8.9 ) {
  
  $string = random_string_from( 'Ѧѧ', 64 );

  binmode STDOUT, ':encoding(UTF-8)';
  print $string, "\n";

}
