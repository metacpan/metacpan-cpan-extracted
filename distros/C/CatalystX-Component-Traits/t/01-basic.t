use strict;
use warnings;
use Test::More tests => 7;
use Catalyst::Utils;

{
    package Catalyst::Controller::SomeController;
    use Moose;
    extends 'Catalyst::Controller';
    with 'CatalystX::Component::Traits';
    has '+_trait_merge' => (default => 1);

    package Catalyst::TraitFor::Controller::SomeController::Foo;
    use Moose::Role;
    has 'foo' => (is => 'ro');

    package MyApp::Controller::MyController;
    use Moose;
    extends 'Catalyst::Controller::SomeController';

    __PACKAGE__->config(
        traits => ['Foo', 'Bar', 'Baz'],
        foo => 'bar'
    );

    sub find_app_class {
        my $self = shift;
        blessed($self->_application) || $self->_application;
    }

    package MyApp::TraitFor::Controller::SomeController::Bar;
    use Moose::Role;
    has 'bar' => (is => 'ro');

    package MyApp::TraitFor::Controller::SomeController::Baz;
    use Moose::Role;
    has 'baz' => (is => 'ro');

    package MyApp::TraitFor::Controller::SomeController::Quux;
    use Moose::Role;
    has 'quux' => (is => 'ro');

    package MyApp;
    use Moose;
    extends 'Catalyst';

    __PACKAGE__->config->{'Controller::MyController'}{traits} =
        ['-Baz', 'Quux'];

    $INC{'MyApp/Controller/MyController.pm'} = 1;
    __PACKAGE__->setup;
}

my $app_class = 'MyApp';
ok((my $instance = MyApp::Controller::MyController->COMPONENT(
        $app_class,
        { bar => 'baz' }
    )),
    'created a component instance');

ok(($instance->does('Catalyst::TraitFor::Controller::SomeController::Foo')),
    'instance had parent ns trait loaded from component config');

ok(($instance->does('MyApp::TraitFor::Controller::SomeController::Bar')),
    'instance had app ns trait loaded from component config');

is eval { $instance->foo }, 'bar',
    'trait initialized from component config works';

is eval { $instance->bar }, 'baz',
    'trait initialized from app config works';

is $instance->find_app_class, 'MyApp', 'Can find app class passing instance';

is_deeply(
    [MyApp->controller('MyController')->meta->calculate_all_roles]->[0]->name,
    'Catalyst::TraitFor::Controller::SomeController::Foo|MyApp::TraitFor::Controller::SomeController::Bar|MyApp::TraitFor::Controller::SomeController::Quux',
    'traits merged correctly'
);
