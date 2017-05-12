use strict;
use warnings;
use Test::More tests => 2;

{
    package CatalystX::Something::ControllerBase::SomeController;
    use Moose;
    extends 'Catalyst::Controller';
    with 'CatalystX::Component::Traits';

    package My::App::Controller::AController;
    use base 'CatalystX::Something::ControllerBase::SomeController';
}

# squash warning from catalyst
my $instance;
{
    local $SIG{__WARN__} = sub {};

    ok(($instance = My::App::Controller::AController->new), 'instance');
}

is_deeply [$instance->_trait_search_order('Trait', 'Foo')], [
    'My::App::TraitFor::Controller::SomeController::Foo',
    'CatalystX::Something::TraitFor::Controller::SomeController::Foo',
], 'trait search order';
