## no critic (ProhibitMagicNumbers)

use strict;
use warnings;

use Test::Lib;
use Test::More import => [ qw( BAIL_OUT cmp_ok is_deeply isa_ok note plan require_ok subtest ) ], tests => 3;
use Test::Fatal qw( dies_ok );

my $class;

BEGIN {
  $class = 'CoffeeSize';
  require_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

subtest 'Class method invocations' => sub {
  plan tests => 14;

  for my $self ( $class->values ) {
    note my $name = $self->name;
    cmp_ok "$self", 'eq', $name, 'Check default stringification';
    isa_ok $self, $class;
    isa_ok $self, 'Class::Enumeration';
    cmp_ok $self, '==', $class->value_of( $self->name ), 'Get enum object reference by name'
  }

  is_deeply [ $class->names ], [ qw( BIG HUGE OVERWHELMING ) ], 'Get names of enum objects';

  dies_ok { $class->value_of( 'INITIAL' ) } 'No such enum object for the given name'
};

subtest 'Access enum attributes' => sub {
  plan tests => 10;

  my $self = $class->value_of( 'BIG' );
  cmp_ok $self->name,    'eq', 'BIG', 'Get name';
  cmp_ok $self->ordinal, '==', 0,     'Get ordinal';
  cmp_ok $self->ounces,  '==', 8,     'Get ounces';

  $self = $class->value_of( 'HUGE' );
  cmp_ok $self->name,    'eq', 'HUGE', 'Get name';
  cmp_ok $self->ordinal, '==', 1,      'Get ordinal';
  cmp_ok $self->ounces,  '==', 10,     'Get ounces';

  $self = $class->value_of( 'OVERWHELMING' );
  cmp_ok $self->name,    'eq', 'OVERWHELMING', 'Get name';
  cmp_ok $self->ordinal, '==', 2,              'Get ordinal';
  cmp_ok $self->ounces,  '==', 16,             'Get ounces';

  cmp_ok $class->value_of( 'BIG' ), '!=', $class->value_of( 'HUGE' ), 'BIG and HUGE are different enum objects'
}
