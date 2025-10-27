## no critic (ProhibitMagicNumbers)

use strict;
use warnings;

use Test::Lib;
use Test::More import => [ qw( BAIL_OUT cmp_ok is_deeply isa_ok note plan subtest use_ok ) ], tests => 4;
use Test::API import => [ qw( class_api_ok ) ];
use Test::Fatal qw( dies_ok );

my $class;

BEGIN {
  $class = 'LockFlag';
  use_ok $class, ':all' or BAIL_OUT "Cannot load class '$class'!";
}

# Class::Enumeration methods + enum constants
class_api_ok $class, qw( name ordinal value_of values names to_string LOCK_SH LOCK_EX LOCK_NB LOCK_UN );

subtest 'Class method invocations' => sub {
  plan tests => 18;

  for my $self ( $class->values ) {
    note my $name = $self->name;
    cmp_ok "$self", 'eq', $name, 'Check default stringification';
    isa_ok $self, $class;
    isa_ok $self, 'Class::Enumeration';
    cmp_ok $self, '==', $class->value_of( $self->name ), 'Get enum object reference by name'
  }

  is_deeply [ $class->names ], [ qw( LOCK_SH LOCK_EX LOCK_NB LOCK_UN ) ], 'Get names of enum objects';

  dies_ok { $class->value_of( 'INITIAL' ) } 'No such enum object for the given name'
};

subtest 'Access enum attributes and enum constants' => sub {
  plan tests => 12;

  my $self = $class->value_of( 'LOCK_SH' );
  cmp_ok $self,          '==', LOCK_SH,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'LOCK_SH', 'Get name';
  cmp_ok $self->ordinal, '==', 1,         'Get ordinal';

  $self = $class->value_of( 'LOCK_EX' );
  cmp_ok $self,          '==', LOCK_EX,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'LOCK_EX', 'Get name';
  cmp_ok $self->ordinal, '==', 2,         'Get ordinal';

  $self = $class->value_of( 'LOCK_NB' );
  cmp_ok $self,          '==', LOCK_NB,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'LOCK_NB', 'Get name';
  cmp_ok $self->ordinal, '==', 4,         'Get ordinal';

  $self = $class->value_of( 'LOCK_UN' );
  cmp_ok $self,          '==', LOCK_UN,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'LOCK_UN', 'Get name';
  cmp_ok $self->ordinal, '==', 8,         'Get ordinal'
}
