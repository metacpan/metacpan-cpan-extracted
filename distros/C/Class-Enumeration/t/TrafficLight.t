## no critic (ProhibitMagicNumbers)

use strict;
use warnings;

use Test::Lib;
use Test::More import => [ qw( BAIL_OUT cmp_ok is_deeply isa_ok note plan require_ok subtest ) ], tests => 4;
use Test::API import => [ qw( class_api_ok ) ];
use Test::Fatal qw( dies_ok );

my $class;

BEGIN {
  $class = 'TrafficLight';
  require_ok $class or BAIL_OUT "Cannot load class '$class'!";
}

# Class::Enumeration methods + custom methods
class_api_ok $class, qw( name ordinal value_of values names to_string action );

subtest 'Class method invocations' => sub {
  plan tests => 14;

  for my $self ( $class->values ) {
    note my $name = $self->name;
    my $action = $self->action;
    cmp_ok "$self", 'eq', "$action if $name", 'Check overriden stringification';
    isa_ok $self, $class;
    isa_ok $self, 'Class::Enumeration';
    cmp_ok $self, '==', $class->value_of( $self->name ), 'Get enum object reference by name'
  }

  is_deeply [ $class->names ], [ qw( GREEN ORANGE RED ) ], 'Get names of enum objects';

  dies_ok { $class->value_of( 'INITIAL' ) } 'No such enum object for the given name'
};

subtest 'Access enum attributes' => sub {
  plan tests => 9;

  my $self = $class->value_of( 'GREEN' );
  cmp_ok $self->name,    'eq', 'GREEN', 'Get name';
  cmp_ok $self->ordinal, '==', 0,       'Get ordinal';
  cmp_ok $self->action,  'eq', 'go',    'Get action';

  $self = $class->value_of( 'ORANGE' );
  cmp_ok $self->name,    'eq', 'ORANGE',    'Get name';
  cmp_ok $self->ordinal, '==', 1,           'Get ordinal';
  cmp_ok $self->action,  'eq', 'slow down', 'Get action';

  $self = $class->value_of( 'RED' );
  cmp_ok $self->name,    'eq', 'RED',  'Get name';
  cmp_ok $self->ordinal, '==', 2,      'Get ordinal';
  cmp_ok $self->action,  'eq', 'stop', 'Get action'
}
