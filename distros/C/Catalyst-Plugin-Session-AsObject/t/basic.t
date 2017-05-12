use strict;
use warnings;

use Test::Fatal;
use Test::More 0.88;

my %config;

# Stolen from Catalyst::Plugin::Session t/01_setup.t
{

    package MockContext;

    use MRO::Compat;

    use base 'Catalyst::Plugin::Session::AsObject';

    sub new { bless {}, $_[0] }

    sub debug { }

    sub config { \%config }

    my $log = Class::MOP::Class->create_anon_class(
        superclasses => ['Moose::Object'] )->name()->new();

    sub log { $log }

    my @mock_isa
        = qw( Catalyst::Plugin::Session::State Catalyst::Plugin::Session::Store );

    sub isa {
        my $self  = shift;
        my $class = shift;
        grep { $_ eq $class } @mock_isa or $self->SUPER::isa($class);
    }

    sub get_session_data { }
}

like(
    exception { MockContext->new()->setup() },
    qr/\QMust provide an object_class in the session config when using Catalyst::Plugin::Session::AsObject/,
    'cannot use Session::AsObject without setting object_class config item'
);

$config{'Plugin::Session'}{object_class} = 'DoesNotExist';

like(
    exception { MockContext->new()->setup() },
    qr/\QThe object_class in the session config is either not loaded or does not have a new() method/,
    'object_class must already be loaded'
);

{

    package MySession;

    sub new { bless {}, $_[0] }
}

$config{'Plugin::Session'}{object_class} = 'MySession';

is(
    exception { MockContext->new()->setup() },
    undef,
    'setup works when object_class exists'
);

my $c = MockContext->new();
$c->setup();

isa_ok(
    $c->session_object(),
    'MySession',
    '$c->session_object'
);

done_testing();
