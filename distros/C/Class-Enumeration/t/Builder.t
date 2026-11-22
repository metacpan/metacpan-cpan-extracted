use Test2::V1
  -pragmas,
  -target => { CLASS => 'Class::Enumeration::Builder' },
  qw( dies is isa_ok isnt lives ok plan subtest );
use Test::Warn qw( warning_like );

plan 5;

isnt dies { CLASS->import( A => {}, B => { foo => 2 } ) }, undef, 'Different number of custom attributes';

isnt dies { CLASS->import( A => { foo => 1 }, B => { bar => 2 } ) }, undef, 'Different names of custom attributes';

isnt dies { CLASS->import( { class => 'PowerState', foo => 1, bar => 2 }, qw( OFF ON ) ) }, undef, 'Unknown options';

ok lives { CLASS->import( A => { foo => 1 }, B => { foo => 2 } ) }, 'Same names of custom attributes';

subtest 'Create enum class at runtime' => sub {
  plan 7;

  my $enum_class;
  ok lives {
    $enum_class = CLASS->import(
      { class => 'CoffeeSize' },
      BIG          => { ounces => 8 },
      HUGE         => { ounces => 10 },
      OVERWHELMING => { ounces => 16 }
    )
  }, 'Create enum class and return its name';
  warning_like {
    CLASS->import(
      { class => 'CoffeeSize' },
      BIG          => { ounces => 8 },
      HUGE         => { ounces => 10 },
      OVERWHELMING => { ounces => 16 }
    )
  }
  { carped => qr/already built/ }, 'Carped warning raised';
  is $enum_class, 'CoffeeSize', 'Check enum class name';
  isa_ok $enum_class, 'Class::Enumeration';

  my $self = $enum_class->value_of( 'HUGE' );
  is $self->name,    'HUGE', 'Get name';
  is $self->ordinal, 1,      'Get ordinal';
  is $self->ounces,  10,     'Get ounces'
}
