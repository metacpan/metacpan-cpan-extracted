use Test::More;
use Acme::Geo::Whitwell::Name;

my %expected = (
   1 => [ qw(Atou   Bout   ) ],
  -7 => [ qw(Eesout Nouvou ) ],
  "35.27N" => [ qw(Ilen Fudee ) ], # positive
  "35.27S" => [ qw(Isudee Fuven ) ], # negative
  "35.27E" => [ qw(Ilen Fudee ) ], # positive
  "35.27W" => [ qw(Isudee Fuven ) ], # negative
);

plan tests => (int keys %expected) * 2;

foreach my $arg (keys %expected) {
   my @expected = @{ $expected{$arg} };

   is Acme::Geo::Whitwell::Name::_vowel_build($arg), $expected[0],
       "vowel substitution $expected[0] right for $arg"; 
   is Acme::Geo::Whitwell::Name::_consonant_build($arg), $expected[1],
       "consonant substitution $expected[1] right for $arg"; 
}
