use strict;
use warnings;
use Test::More;
use Catalyst::Utils;

{
    package MyApp::Controller::SomeController;
    use Moose;
    extends 'Catalyst::Controller';
    with 'CatalystX::Component::Traits';
    has '+_trait_merge' => (default => 1);

    __PACKAGE__->config( traits => 'Foo' );

    package MyApp::TraitFor::Controller::SomeController::Foo;
    use Moose::Role;
    has 'foo' => (is => 'ro');

    package MyApp::TraitFor::Controller::SomeController::Bar;
    use Moose::Role;
    has 'bar' => (is => 'ro');

}

ok((my $instance = MyApp::Controller::SomeController->COMPONENT(
        bless({}, 'Catalyst'),
        { traits => 'Bar', foo => 'bar', bar => 'baz' }
    )),
    'created a component instance');

ok(($instance->does('MyApp::TraitFor::Controller::SomeController::Foo')),
    'instance had parent ns trait loaded from component config');

ok(($instance->does('MyApp::TraitFor::Controller::SomeController::Bar')),
    'instance had app ns trait loaded from component config');

is eval { $instance->foo }, 'bar',
    'trait initialized from component config works';

is eval { $instance->bar }, 'baz',
    'trait initialized from app config works';

done_testing;

