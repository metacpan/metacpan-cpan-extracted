use strict;
use warnings;

use Test::More import => [ qw( BAIL_OUT cmp_ok isa_ok plan require_ok subtest ) ], tests => 6;
use Test::Fatal qw( dies_ok lives_ok );
use Test::Warn  qw( warning_like );

my $class;

BEGIN {
  $class = 'Class::Enumeration::Builder';
  require_ok $class or BAIL_OUT "Cannot load class '$class'!"
}

dies_ok { $class->import( A => {}, B => { foo => 2 } ) } 'Different number of custom attributes';

dies_ok { $class->import( A => { foo => 1 }, B => { bar => 2 } ) } 'Different names of custom attributes';

dies_ok { $class->import( { class => 'PowerState', foo => 1, bar => 2 }, qw( OFF ON ) ) } 'Unknown options';

lives_ok { $class->import( A => { foo => 1 }, B => { foo => 2 } ) } 'Same names of custom attributes';

subtest 'Create enum class at runtime' => sub {
  plan tests => 7;

  my $enum_class;
  lives_ok {
    $enum_class = $class->import(
      { class => 'CoffeeSize' },
      BIG          => { ounces => 8 },
      HUGE         => { ounces => 10 },
      OVERWHELMING => { ounces => 16 }
    )
  }
  'Create enum class and return its name';
  warning_like {
    $class->import(
      { class => 'CoffeeSize' },
      BIG          => { ounces => 8 },
      HUGE         => { ounces => 10 },
      OVERWHELMING => { ounces => 16 }
    )
  }
  { carped => qr/already built/ }, 'Carped warning raised';
  cmp_ok $enum_class, 'eq', 'CoffeeSize', 'Check enum class name';
  isa_ok $enum_class, 'Class::Enumeration';

  my $self = $enum_class->value_of( 'HUGE' );
  cmp_ok $self->name,    'eq', 'HUGE', 'Get name';
  cmp_ok $self->ordinal, '==', 1,      'Get ordinal';
  cmp_ok $self->ounces,  '==', 10,     'Get ounces'
}
