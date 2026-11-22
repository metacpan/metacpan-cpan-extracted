## no critic (ProhibitMagicNumbers)
use Test2::V1
  -pragmas,
  -target => { CLASS => 'ToastStatus' },
  qw( cmp_ok dies imported_ok is isa_ok note ok plan subtest );
BEGIN { CLASS->import( ':all' ) }
use Test::API import => [ qw( class_api_ok ) ];

plan 4;

# Class::Enumeration methods + enum constants
class_api_ok CLASS, qw( name ordinal value_of values names to_string bread burnt toast toasting );

imported_ok qw( bread burnt toast toasting );

subtest 'Class method invocations' => sub {
  plan 18;

  for my $self ( CLASS->values ) {
    note my $name = $self->name;
    cmp_ok "$self", 'eq', $name, 'Check default stringification';
    isa_ok $self, CLASS;
    isa_ok $self, 'Class::Enumeration';
    cmp_ok $self, '==', CLASS->value_of( $self->name ), 'Get enum object reference by name'
  }

  is [ CLASS->names ], [ qw( bread toasting toast burnt ) ], 'Get names of enum objects';

  ok defined( dies { CLASS->value_of( 'initial' ) } ), 'No such enum object for the given name'
};

subtest 'Access enum attributes and enum constants' => sub {
  plan 12;

  my $self = CLASS->value_of( 'bread' );
  cmp_ok $self,          '==', bread,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'bread', 'Get name';
  cmp_ok $self->ordinal, '==', 0,       'Get ordinal';

  $self = CLASS->value_of( 'toasting' );
  cmp_ok $self,          '==', toasting,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'toasting', 'Get name';
  cmp_ok $self->ordinal, '==', 1,          'Get ordinal';

  $self = CLASS->value_of( 'toast' );
  cmp_ok $self,          '==', toast,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'toast', 'Get name';
  cmp_ok $self->ordinal, '==', 2,       'Get ordinal';

  $self = CLASS->value_of( 'burnt' );
  cmp_ok $self,          '==', burnt,   'Access enum constant';
  cmp_ok $self->name,    'eq', 'burnt', 'Get name';
  cmp_ok $self->ordinal, '==', 3,       'Get ordinal'
}
