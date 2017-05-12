use strict;
use warnings;
use Test::More tests => 2;

{
    package CatalystX::App::Model::AModel;
    use Moose;
    extends 'Catalyst::Model';
    with 'CatalystX::Component::Traits';
}

ok((my $instance = CatalystX::App::Model::AModel->new), 'instance');

is_deeply [$instance->_trait_search_order('Trait', 'Foo')], [
    'CatalystX::App::TraitFor::Model::AModel::Foo'
], 'trait search order';
