use strict;
use warnings;

use Test::More tests => 1;

use Class::C3::XS;

=pod

This tests the classic diamond inheritance pattern.

   <A>
  /   \
<B>   <C>
  \   /
   <D>

=cut

{
    package Diamond_A;
    our @ISA = qw//;
}
{
    package Diamond_B;
    use base 'Diamond_A';
}
{
    package Diamond_C;
    use base 'Diamond_A';
}
{
    package Diamond_D;
    use base ('Diamond_B', 'Diamond_C');
}

is_deeply(
    [ Class::C3::XS::calculateMRO('Diamond_D') ],
    [ qw(Diamond_D Diamond_B Diamond_C Diamond_A) ],
    '... got the right MRO for Diamond_D');
