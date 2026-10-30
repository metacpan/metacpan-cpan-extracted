#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use CLI::Simple ();

# Inline roles keep this test self-contained. Role::Tiny still requires
# a module to be present in %INC before composing it.
{
  package Local::Options::First;

  use Role::Tiny;

  sub _first_init {
    my ($self) = @_;
    return;
  }

  sub _first_resolve {
    my ( $self, @names ) = @_;
    return { map { $_ => qq(first:$_) } @names };
  }
}

{
  package Local::Options::Second;

  use Role::Tiny;

  sub _second_resolve {
    my ( $self, @names ) = @_;
    return { map { $_ => qq(second:$_) } @names };
  }
}

BEGIN {
  $INC{'Local/Options/First.pm'}  = __FILE__;
  $INC{'Local/Options/Second.pm'} = __FILE__;
}

{
  package Local::CLI::Multiple;
  use parent qw(CLI::Simple);
}

{
  package Local::CLI::InvalidName;
  use parent qw(CLI::Simple);
}

{
  package Local::CLI::InvalidDefinition;
  use parent qw(CLI::Simple);
}

{
  package Local::CLI::InvalidOptions;
  use parent qw(CLI::Simple);
}

subtest 'multiple providers compose into the application class' => sub {
  my $class = 'Local::CLI::Multiple';

  is(
    $class->use_options(
      first => {
        'Local::Options::First' => [qw(rabbit_password rabbit_username)],
      },
      second => {
        'Local::Options::Second' => [qw(rabbit_password api_key)],
      },
    ),
    $class,
    'registration returns the application class',
  );

  ok( $class->can('_first_init'), 'optional first-provider initializer composed' );
  ok( $class->can('_first_resolve'), 'first-provider resolver composed' );
  ok( $class->can('_second_resolve'), 'second-provider resolver composed' );

  my $object = bless {}, $class;
  is_deeply(
    $object->_first_resolve(qw(rabbit_password rabbit_username)),
    {
      rabbit_password => 'first:rabbit_password',
      rabbit_username => 'first:rabbit_username',
    },
    'composed role method can be called on an application instance',
  );

  # Overlap is intentional and must not be rejected at registration.
  # Provider invocation order and unresolved-name filtering will be
  # tested separately when the orchestrator is implemented.
};

subtest 'registration rejects duplicate provider names' => sub {
  my $class = 'Local::CLI::Multiple';

  my $ok = eval {
    $class->use_options(
      first => { 'Local::Options::First' => [qw(rabbit_password)] },
    );
    1;
  };

  ok( !$ok, 'duplicate name rejected' );
  like( $@, qr/Duplicate option provider: first/, 'useful diagnostic' );
};

subtest 'registration validates its input' => sub {
  my $ok = eval {
    Local::CLI::InvalidName->use_options(
      'invalid-name' => { 'Local::Options::First' => [] },
    );
    1;
  };
  ok( !$ok, 'invalid provider name rejected' );
  like( $@, qr/Invalid provider name/, 'invalid name diagnostic' );

  $ok = eval {
    Local::CLI::InvalidDefinition->use_options(
      mixed => {
        'Local::Options::First'  => [],
        'Local::Options::Second' => [],
      },
    );
    1;
  };
  ok( !$ok, 'multiple roles in one provider definition rejected' );
  like( $@, qr/Invalid provider definition/, 'invalid definition diagnostic' );

  $ok = eval {
    Local::CLI::InvalidOptions->use_options(
      first => { 'Local::Options::First' => 'rabbit_password' },
    );
    1;
  };
  ok( !$ok, 'non-array option specification rejected' );
  like( $@, qr/Invalid option list/, 'invalid option list diagnostic' );
};

subtest 'odd argument count is rejected' => sub {
  my $ok = eval {
    Local::CLI::InvalidName->use_options(orphan => ());
    1;
  };
  ok( !$ok, 'odd number of arguments rejected' );
  like( $@, qr/Odd number of arguments/, 'odd argument diagnostic' );
};

done_testing;
1;
