use Test2::V1
  -pragmas,
  -target => { CLASS => 'TurnstileStateMachine' },
  # Cannot use ref_is instead of cmp_ok because magic auto-generation of
  # overload implementations for other operators is turned off
  qw( cmp_ok dies imported_ok is isa_ok isnt note plan subtest );
BEGIN { CLASS->import( ':all' ) }

plan 4;

imported_ok qw( Locked Unlocked );

subtest 'Class method invocations' => sub {
  plan 10;

  for my $self ( CLASS->values ) {
    note my $name = $self->name;
    is "$self", $name, 'Check default stringification';
    isa_ok $self, CLASS;
    isa_ok $self, 'Class::Enumeration';
    cmp_ok $self, '==', CLASS->value_of( $self->name ), 'Get enum object reference by name'
  }

  is [ CLASS->names ], [ qw( Locked Unlocked ) ], 'Get names of enum objects';

  isnt dies { CLASS->value_of( 'Initial' ) }, undef, 'No such enum object for the given name'
};

subtest 'Access enum attributes' => sub {
  plan 4;

  my $self = CLASS->value_of( 'Locked' );
  is $self->name,    'Locked', 'Get name';
  is $self->ordinal, 0,        'Get ordinal';

  $self = CLASS->value_of( 'Unlocked' );
  is $self->name,    'Unlocked', 'Get name';
  is $self->ordinal, 1,          'Get ordinal'
};

subtest 'Trigger state transitions' => sub {
  plan 7;

  # Set initial state
  isa_ok my $state = Locked, CLASS;
  isnt dies { $state->do_something( 'foo' ) }, undef, 'Wrong input';
  cmp_ok $state->do_something( 'push' ), '==', Locked,   'Still locked';
  cmp_ok $state->do_something( 'coin' ), '==', Unlocked, 'Now unlocked';
  isnt dies { $state->do_something( 'foo' ) }, undef, 'Wrong input';
  cmp_ok $state->do_something( 'coin' ), '==', Unlocked, 'Still unlocked';
  cmp_ok $state->do_something( 'push' ), '==', Locked,   'Locked again'
}
