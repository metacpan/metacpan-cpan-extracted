use strict;
use warnings;
use Test::More tests => 2;
use Catalyst::Utils;

# test that everything off with trait merge turned OFF

{
    package Catalyst::Controller::SomeController;
    use Moose;
    extends 'Catalyst::Controller';
    with 'CatalystX::Component::Traits';

    package Catalyst::TraitFor::Controller::SomeController::Foo;
    use Moose::Role;
    has 'foo' => (is => 'ro');

    package MyApp::Controller::MyController;
    use Moose;
    extends 'Catalyst::Controller::SomeController';

    __PACKAGE__->config(
        traits => ['Quux'], # these should be overwritten by app config
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

    __PACKAGE__->config->{'Controller::MyController'} = {
        traits => [qw/Foo Bar Baz/],
        bar => 'baz',
    };

    $INC{'MyApp/Controller/MyController.pm'} = 1;
    __PACKAGE__->setup;
}

is eval { MyApp->controller('MyController')->bar }, 'baz',
    'trait initialized from app config works';

is_deeply(
    [MyApp->controller('MyController')->meta->calculate_all_roles]->[0]->name,
    'Catalyst::TraitFor::Controller::SomeController::Foo|MyApp::TraitFor::Controller::SomeController::Bar|MyApp::TraitFor::Controller::SomeController::Baz',
    'traits from app config override traits from component config'
);
