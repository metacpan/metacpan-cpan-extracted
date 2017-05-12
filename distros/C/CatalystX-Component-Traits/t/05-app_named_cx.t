use strict;
use warnings;
use Test::More tests => 2;

{
    package Catalyst::Model::CatModel;
    use Moose;
    extends 'Catalyst::Model';
    with 'CatalystX::Component::Traits';

    package CatalystX::App::Model::AModel;
    use base 'Catalyst::Model::CatModel';
}

ok((my $instance = CatalystX::App::Model::AModel->new), 'instance');

is_deeply [$instance->_trait_search_order('Trait', 'Foo')], [
    'CatalystX::App::TraitFor::Model::CatModel::Foo',
    'Catalyst::TraitFor::Model::CatModel::Foo',
], 'trait search order';
