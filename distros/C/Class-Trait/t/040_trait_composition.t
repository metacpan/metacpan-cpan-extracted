#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 41;
use Test::Differences;

BEGIN {
    chdir 't' if -d 't';
    unshift @INC => ( 'test_lib', '../lib' );
}

# we have to use it directly because it uses an INIT block to flatten traits
use Circle;

# create a circle
can_ok( "Circle", "new" );
my $circle = Circle->new();

# make sure it is a Circle
isa_ok( $circle, 'Circle' );

# check the traits in it
my @trait_in_circle = qw(
  TCircle
  TColor
  TEquality
  TGeometry
  TMagnitude
);
ok( $circle->does($_), "... circle does $_" ) foreach @trait_in_circle;
is_deeply [ sort $circle->does ], \@trait_in_circle,
  'Calling does() without an argument should return all traits';

ok my $tcircle_config = Class::Trait->fetch_trait_from_cache('TCircle'),
  'We should be able to fetch a traits configuration from the cache';

# now check the methods we expect it to have
my @method_labels = (
    qw/ notEqualTo isSameTypeAs /,    # TEquality
    qw/ lessThanOrEqualTo greaterThan greaterThanOrEqualTo isBetween /
    ,                                                               # TMagnitude
    qw/ area bounds diameter scaleBy /,                             # TGeometry
    qw/ getRed setRed getBlue setBlue getGreen setGreen equalTo /,  # TColor
    qw/ lessThan equalTo /,                                         # TCircle
);

can_ok( $circle, $_ ) foreach @method_labels;

# now check the overloaded operators we expect it to have

# for Circle
ok( overload::Method( $circle, '==' ), '... circle overload ==' );

# for TCircle
# NOTE: TCircle overloads == too, but Circle overrides that
ok( overload::Method( $circle, '<' ), '... circle overload <' );

# for TEquality
# NOTE: TEquality overloads == too, but Circle overrides that
ok( overload::Method( $circle, '!=' ), '... circle overload !=' );

# for TMagnitude
# NOTE: TMagnitude overloads < too, but TCircle overrides that
ok( overload::Method( $circle, '<=' ), '... circle overload <=' );
ok( overload::Method( $circle, '>' ),  '... circle overload >' );
ok( overload::Method( $circle, '>=' ), '... circle overload >=' );

# now lets extract the actul trait and examine it

my $trait;
{
    no strict 'refs';

    # get the trait out
    $trait = ${"Circle::TRAITS"};
}

# check to see it is what we want it to be
isa_ok( $trait, 'Class::Trait::Config' );

# now examine the trait itself
is( $trait->name, 'COMPOSITE', '... get the traits name' );

eq_or_diff $trait->sub_traits, [ 'TCircle', 'TColor' ],
  '... this should not be empty';

eq_or_diff $trait->conflicts, {}, '... we should have no conflicts';

eq_or_diff $trait->requirements,
  {
    getRadius => 1,
    setRadius => 1,
    getRGB    => 1,
    setRGB    => 1,
    getCenter => 1,
    setCenter => 1,
    equalTo   => 2,
  },
  '... and trait requirements should be correct';

eq_or_diff $trait->overloads,
  {
    '==' => 'equalTo',
    '>=' => 'greaterThanOrEqualTo',
    '<=' => 'lessThanOrEqualTo',
    '>'  => 'greaterThan',
    '<'  => 'lessThan',
    '!=' => 'notEqualTo'
  },
  '... and the overloaded operators should be correct';

eq_or_diff [ sort keys %{ $trait->methods } ], [
    qw(
      area
      bounds
      diameter
      getBlue
      getGreen
      getRed
      greaterThan
      greaterThanOrEqualTo
      isBetween
      isExactly
      isSameTypeAs
      lessThan
      lessThanOrEqualTo
      notEqualTo
      scaleBy
      setBlue
      setGreen
      setRed
      )
  ],
  '... and the trait methods should also be correct';

