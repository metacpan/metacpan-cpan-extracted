## no critic (ProhibitMagicNumbers)

use strict;
use warnings;

use Test::Lib;
use Test::More import => [ qw( BAIL_OUT cmp_ok is_deeply isa_ok note ok plan subtest use_ok ) ], tests => 4;
use Test::API import => [ qw( class_api_ok ) ];
use Test::Fatal qw( dies_ok );

my $class;

BEGIN {
  $class = 'PowerState';
  use_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

# Class::Enumeration methods + TO_JSON method
class_api_ok $class, qw( name ordinal value_of values names to_string TO_JSON );

subtest 'Class method invocations' => sub {
  plan tests => 10;

  for my $self ( $class->values ) {
    note my $name = $self->name;
    cmp_ok "$self", 'eq', $name, 'Check default stringification';
    isa_ok $self, $class;
    isa_ok $self, 'Class::Enumeration';
    cmp_ok $self, '==', $class->value_of( $self->name ), 'Get enum object reference by name'
  }

  is_deeply [ $class->names ], [ qw( OFF ON ) ], 'Get names of enum objects';

  dies_ok { $class->value_of( 'INITIAL' ) } 'No such enum object for the given name'
};

subtest 'Access enum attributes and check default TO_JSON implementation' => sub {
  plan tests => 6;

  my $self = $class->value_of( 'OFF' );
  cmp_ok $self->name,    'eq', 'OFF', 'Get name';
  cmp_ok $self->TO_JSON, 'eq', 'OFF', 'Call TO_JSON';
  cmp_ok $self->ordinal, '==', 0,     'Get ordinal';

  $self = $class->value_of( 'ON' );
  cmp_ok $self->name,    'eq', 'ON', 'Get name';
  cmp_ok $self->TO_JSON, 'eq', 'ON', 'Call TO_JSON';
  cmp_ok $self->ordinal, '==', 1,    'Get ordinal';
}
