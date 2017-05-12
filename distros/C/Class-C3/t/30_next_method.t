use strict;
use warnings;

use Test::More tests => 5;

=pod

This tests the classic diamond inheritence pattern.

   <A>
  /   \
<B>   <C>
  \   /
   <D>

=cut

{
    package Diamond_A;
    use Class::C3;
    sub hello { 'Diamond_A::hello' }
    sub foo { 'Diamond_A::foo' }
}
{
    package Diamond_B;
    BEGIN { our @ISA = ('Diamond_A'); }
    use Class::C3;
    sub foo { 'Diamond_B::foo => ' . (shift)->next::method() }
}
{
    package Diamond_C;
    use Class::C3;
    BEGIN { our @ISA = ('Diamond_A'); }

    sub hello { 'Diamond_C::hello => ' . (shift)->next::method() }
    sub foo { 'Diamond_C::foo => ' . (shift)->next::method() }
}
{
    package Diamond_D;
    BEGIN { our @ISA = ('Diamond_B', 'Diamond_C'); }
    use Class::C3;

    sub foo { 'Diamond_D::foo => ' . (shift)->next::method() }
}

Class::C3::initialize();

is_deeply(
    [ Class::C3::calculateMRO('Diamond_D') ],
    [ qw(Diamond_D Diamond_B Diamond_C Diamond_A) ],
    '... got the right MRO for Diamond_D');

is(Diamond_D->hello, 'Diamond_C::hello => Diamond_A::hello', '... method resolved itself as expected');

is(Diamond_D->can('hello')->('Diamond_D'),
   'Diamond_C::hello => Diamond_A::hello',
   '... can(method) resolved itself as expected');

is(UNIVERSAL::can("Diamond_D", 'hello')->('Diamond_D'),
   'Diamond_C::hello => Diamond_A::hello',
   '... can(method) resolved itself as expected');

is(Diamond_D->foo,
    'Diamond_D::foo => Diamond_B::foo => Diamond_C::foo => Diamond_A::foo',
    '... method foo resolved itself as expected');
