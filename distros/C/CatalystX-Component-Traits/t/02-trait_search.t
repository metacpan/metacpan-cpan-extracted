use strict;
use warnings;
use Test::More tests => 2;

{
    package Catalyst::Model::CatModel;
    use Moose;
    extends 'Catalyst::Model';
    with 'CatalystX::Component::Traits';

    package My::App::Model::AModel;
    use base 'Catalyst::Model::CatModel';
}

ok((my $instance = My::App::Model::AModel->new), 'instance');

is_deeply [$instance->_trait_search_order('Trait', 'Foo')], [
    'My::App::TraitFor::Model::CatModel::Foo',
    'Catalyst::TraitFor::Model::CatModel::Foo',
], 'trait search order';
