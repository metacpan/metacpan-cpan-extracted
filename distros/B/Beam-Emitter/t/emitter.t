
use strict;
use warnings;
use Test::More;
use Test::Fatal;

use Scalar::Util qw[ refaddr ];

{
    package My::Emitter;

    use Moo;
    with 'Beam::Emitter';

    sub foo {
        my ( $self ) = @_;
        my $event = $self->emit( "foo" );
        return if $event->is_default_stopped;
        $self->emit( "after_foo" );
    }
}

subtest 'event listeners' => sub {
    my $emitter = My::Emitter->new;
    my $foo_listener = sub {
        my ( $event ) = @_;
        is $event->name, 'foo', 'foo event has correct name';
        is $event->emitter, $emitter, 'foo event has correct emitter';
    };
    my $after_foo_listener = sub {
        my ( $event ) = @_;
        is $event->name, 'after_foo', 'after_foo event has correct name';
        is $event->emitter, $emitter, 'after_foo event has correct emitter';
    };
    $emitter->on( foo => $foo_listener );
    $emitter->subscribe( after_foo => $after_foo_listener );
    $emitter->foo;
};

subtest 'unsubscribe' => sub {
    my $emitter = My::Emitter->new;
    my $foo_count = 0;
    my $foo_listener = sub {
        my ( $event ) = @_;
        if ( $foo_count++ == 0 ) {
            is $event->name, 'foo', 'foo event has correct name';
            is $event->emitter, $emitter, 'foo event has correct emitter';
        }
        else {
            fail "foo listener not called a second time";
        }
    };
    my $after_foo_count = 0;
    my $after_foo_listener = sub {
        my ( $event ) = @_;
        if ( $after_foo_count++ == 0 ) {
            is $event->name, 'after_foo', 'after_foo event has correct name';
            is $event->emitter, $emitter, 'after_foo event has correct emitter';
        }
        else {
            fail "after_foo listener not called a second time";
        }
    };
    $emitter->on( foo => $foo_listener );
    $emitter->subscribe( after_foo => $after_foo_listener );
    $emitter->foo;
    $emitter->unsubscribe( foo => $foo_listener );
    $emitter->un( "after_foo" );

    ok exception { $emitter->unsubscribe( foo => $foo_listener ) }, "Cannot unsubscribe twice";
    ok exception { $emitter->unsubscribe( foo => sub { } ) }, "Cannot find sub in listeners";
};

subtest 'stop' => sub {
    my $emitter = My::Emitter->new;
    my $foo_listener_one = sub {
        my ( $event ) = @_;
        is $event->name, 'foo', 'foo event has correct name';
        is $event->emitter, $emitter, 'foo event has correct emitter';
        $event->stop;
    };
    my $foo_listener_two = sub {
        fail "second foo listener is not called";
    };
    my $after_foo_listener = sub {
        fail "after foo listener is not called";
    };
    $emitter->on( foo => $foo_listener_one );
    $emitter->subscribe( foo => $foo_listener_two );
    $emitter->on( after_foo => $after_foo_listener );
    $emitter->foo;
};

subtest 'stop default' => sub {
    my $emitter = My::Emitter->new;
    my $foo_listener = sub {
        my ( $event ) = @_;
        is $event->name, 'foo', 'foo event has correct name';
        is $event->emitter, $emitter, 'foo event has correct emitter';
        $event->stop_default;
    };
    my $after_foo_listener = sub {
        my ( $event ) = @_;
        fail "after foo listener is not called";
    };
    $emitter->on( foo => $foo_listener );
    $emitter->on( after_foo => $after_foo_listener );
    $emitter->foo;
};

{
    package My::Emitter::Args;

    use Moo;
    with 'Beam::Emitter';

    sub foo {
        my ( $self ) = @_;
        $self->emit_args( foo => $self, 'arg' );
    }
}

subtest 'emit args' => sub {
    my $emitter = My::Emitter::Args->new;
    my $foo_listener = sub {
        my ( $self, $arg ) = @_;
        is $self, $emitter, 'emitter passes itself as first argument';
        is $arg, 'arg', 'emitter passes a second argument';
    };
    $emitter->on( foo => $foo_listener );
    $emitter->foo;
};

subtest 'no listeners' => sub {
    my $emitter = My::Emitter::Args->new;

    my $event;
    ok !exception { $event = $emitter->emit( 'foo' ) }, "emit lives with no listeners";
    isa_ok $event, 'Beam::Event', 'event is still returned';
    is $event->name, 'foo', 'event name is correct';

    ok !exception { $emitter->emit_args( 'foo' ) }, "emit_args lives with no listeners";
};

subtest 'custom name' => sub {
    my $emitter = My::Emitter->new;
    my @events;
    $emitter->on( 'foo', sub { push @events, @_ } );
    $emitter->emit( 'foo', name => 'bar' );
    is scalar @events, 1, 'foo event caught';
    is $events[0]->name, 'bar', 'foo event correctly renamed bar';
};


subtest 'alternate emitter' => sub {

    my $emitter = My::Emitter->new;
    my $alt_emitter = My::Emitter->new;
    my @events;
    $emitter->on( 'foo', sub { push @events, @_ } );
    $emitter->emit( 'foo', emitter => $alt_emitter );
    is scalar @events, 1, 'foo event caught';
    is refaddr $events[0]->emitter, refaddr $alt_emitter,
     'alternate emitter correctly specified';
};

{
  package My::Overloaded::Emitter;
  use Moo;

  extends 'My::Emitter';
  use overload bool => sub { 0 };
}

subtest 'overloaded bool operator in emitter' => sub {

    my $emitter = My::Emitter->new;
    my $class;

    $emitter->on( 'foo', sub { $class = ref $_[0]->emitter } );
    $emitter->emit(
        'foo',
        emitter => My::Overloaded::Emitter->new,
	);

    is( $class, 'My::Overloaded::Emitter', 'insensitive to bool operator' );

};

done_testing;
