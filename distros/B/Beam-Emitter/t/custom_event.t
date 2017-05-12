
use strict;
use warnings;
use Test::More;

{
    package My::Event;
    use Moo;
    extends 'Beam::Event';

    has data => (
        is      => 'ro',
    );

}
{
    package My::Emitter;

    use Moo;
    with 'Beam::Emitter';

    sub foo {
        my ( $self ) = @_;
        my $event = $self->emit( "foo", class => 'My::Event', data => 'FOO' );
        return if $event->is_default_stopped;
        $self->emit( "after_foo" );
    }
}

subtest 'custom event' => sub {
    my $emitter = My::Emitter->new;
    my $foo_listener = sub {
        my ( $event ) = @_;
        is $event->name, 'foo', 'foo event has correct name';
        is $event->emitter, $emitter, 'foo event has correct emitter';
        isa_ok $event, 'My::Event', 'event is the correct class';
        is $event->data, 'FOO', 'event has the right data';
    };
    my $after_foo_listener = sub {
        my ( $event ) = @_;
        is $event->name, 'after_foo', 'after_foo event has correct name';
        is $event->emitter, $emitter, 'after_foo event has correct emitter';
        isa_ok $event, 'Beam::Event', 'event is the correct class';
    };
    $emitter->on( foo => $foo_listener );
    $emitter->subscribe( after_foo => $after_foo_listener );
    $emitter->foo;
};

done_testing;
