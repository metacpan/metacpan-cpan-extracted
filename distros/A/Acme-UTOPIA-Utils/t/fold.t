use Test::More;

BEGIN {
  use_ok( 'Acme::UTOPIA::Utils' );
  Acme::UTOPIA::Utils->import( qw( fold ) );
}

is ( ( fold { $a + $b } 5 ), 5, 'Fold with a single value' );
is ( ( fold { $a + $b } 0, 5, 3 ), 8, 'Fold for summing' );
is ( ( fold { $a . $b } 'Hello', ', ', 'World', '!' ), 'Hello, World!',
  'Fold for string concatenation' );

is ( ( fold { $a . ', ' . $b } 1, 2, 3 ), '1, 2, 3',
  'Fold for joining strings with a delimiter' );

my %x = ( foo => 'Foo!', bar => 'Bar!' );
my %y = ( zebra => 'Zebra!', platypus => 'Wha!?' );

is_deeply(
  ( fold { @$a{keys $b} = values $b; $a } {}, \%x, \%y ),
  { foo => 'Foo!', bar => 'Bar!', zebra => 'Zebra!', platypus => 'Wha!?' },
  'Fold for merging datastructures' );

&done_testing;
