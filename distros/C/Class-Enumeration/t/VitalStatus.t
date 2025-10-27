## no critic (ProhibitMagicNumbers)

use strict;
use warnings;

use Test::Lib;
use Test::More import => [ qw( BAIL_OUT cmp_ok is_deeply isa_ok note ok plan subtest use_ok ) ], tests => 4;
use Test::API import => [ qw( class_api_ok ) ];
use Test::Fatal qw( dies_ok );

my $class;

BEGIN {
  $class = 'VitalStatus';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

# Class::Enumeration methods + enum constants
class_api_ok $class, qw( name ordinal value_of values names to_string is_dead is_alive );

subtest 'Class method invocations' => sub {
  plan tests => 10;

  for my $self ( $class->values ) {
    note my $name = $self->name;
    cmp_ok "$self", 'eq', $name, 'Check default stringification';
    isa_ok $self, $class;
    isa_ok $self, 'Class::Enumeration';
    cmp_ok $self, '==', $class->value_of( $self->name ), 'Get enum object reference by name'
  }

  is_deeply [ $class->names ], [ qw( dead alive ) ], 'Get names of enum objects';

  dies_ok { $class->value_of( 'initial' ) } 'No such enum object for the given name'
};

subtest 'Access enum attributes and use predicate methods' => sub {
  plan tests => 8;

  my $self = $class->value_of( 'dead' );
  cmp_ok $self->name,    'eq', 'dead', 'Get name';
  cmp_ok $self->ordinal, '==', 0,      'Get ordinal';
  ok $self->is_dead,         'Is dead';
  ok not( $self->is_alive ), 'Is not alive'; ## no critic ( RequireTestLabels )

  $self = $class->value_of( 'alive' );
  cmp_ok $self->name,    'eq', 'alive', 'Get name';
  cmp_ok $self->ordinal, '==', 1,       'Get ordinal';
  ok $self->is_alive, 'Is alive';
  ok not( $self->is_dead ), 'Is not dead' ## no critic ( RequireTestLabels )
}
