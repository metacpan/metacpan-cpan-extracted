use warnings;
use strict;
use Test::More;

{
  package Critter;
  use Class::Type::Enum values => [qw( mouse rabbit dog cat )];
}

{
  package Vehicle;
  # Make sure it works more than once
  use Class::Type::Enum values => [qw(bike car bus train plane)];
}

can_ok( 'Critter', qw(
  new
  inflate_symbol inflate_ordinal
  type_constraint
  test_symbol    test_ordinal
  coerce_symbol  coerce_ordinal
  values
  sym_to_ord     ord_to_sym
  list_is_methods
));

ok( (my @is_methods = Critter->list_is_methods), 'can list_is_methods' );
is( scalar(@is_methods), 4, 'is_methods looks good' );

my $cat = new_ok( 'Critter', ['cat'] );

isa_ok( $cat, 'Class::Type::Enum' );

can_ok( $cat, qw( is is_mouse is_cat is_dog is_rabbit ) );


ok( $cat->is('cat'), 'cat is a cat.');
ok( $cat->is_cat, 'cat is a cat!' );
ok( !$cat->is_dog, 'this aint no dog.' );

is( "$cat", 'cat', "stringified the cat, yeowch!" );
ok( $cat != 1, "are cats even numifiable?" );

ok( $cat == Critter->new('cat'), 'all cats are equal' );
ok( $cat == Critter->new("$cat"), 'no matter where they come from' );

ok( $cat > Critter->new('dog'), '...and more equal than dogs' );
ok( Critter->new('mouse') < $cat, 'these fierce predators' );
ok( Critter->new('mouse') lt $cat, 'no matter how you look at it' );

# Dwarn [ sort {$a <=> $b} map { Critter->new($_) } @{Critter->values} ];

ok( $cat->any(qw(rabbit cat)), 'others could be tolerated' );
ok( $cat->none(qw(dog mouse)), 'but we must keep standards' );

ok( my $dog = $cat->new('dog'), 'okay okay, made a dog' );
cmp_ok( $dog, '!=', $cat, "they're just so different!" );
ok( 'cat' gt $dog, 'cats are still on top though' );

subtest 'test methods for type checks' => sub {
  ok( Critter->test_symbol('rabbit'), 'rabbit ok' );
  ok( Critter->test_symbol($cat),     'cat ok' );

  ok( !Critter->test_symbol('snake'), 'no snakes' );

  ok( Critter->test_ordinal(0),      'numouse ok' );
  ok( Critter->test_ordinal(0+$cat), 'numcat ok');
  ok( !Critter->test_ordinal(42),    'life meaningless' );
};

subtest 'coerce methods' => sub {
  ok( Critter->coerce_symbol($cat), 'coerced cat, maybe' );
  ok( Critter->coerce_symbol('rabbit'), 'coerced rabbit' );
  ok( !defined eval {
      Critter->coerce_symbol('snake') }, 'no legs, no service' );

  ok( Critter->coerce_ordinal($cat), 'coerced cat, sure buddy' );
  ok( Critter->coerce_ordinal(2),    'coerced dog' );
  ok( !defined eval {
      Critter->coerce_ordinal(21) }, 'blackjack' );

  ok( Critter->coerce_any($cat),     'coerced cat, sure buddy' );
  ok( Critter->coerce_any(2),        'coerced dog' );
  ok( Critter->coerce_any('rabbit'), 'coerced bunny' );
  ok( !defined eval {
      Critter->coerce_any('snake') },'cant take a hint' );
  ok( !defined eval {
      Critter->coerce_any(15) },     'learners permit' );
};

ok( eval {
  package Dummy;
  Critter->import();
  1;
}, 'Class::Type::Enum skips import when subclasses are used, or this would die.');


done_testing;

