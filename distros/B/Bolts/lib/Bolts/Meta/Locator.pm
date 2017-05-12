package Bolts::Meta::Locator;
$Bolts::Meta::Locator::VERSION = '0.143171';
# ABSTRACT: Standard meta locator for Bolts

use Moose;

with qw( Bolts::Role::RootLocator );

use Bolts::Artifact;
use Bolts::Artifact::Thunk;
use Bolts::Bag;

use Bolts::Blueprint::Built;
use Bolts::Blueprint::Factory;
use Bolts::Blueprint::Given;
use Bolts::Blueprint::Literal;

use Bolts::Injector::Parameter::ByName;

use Bolts::Scope::Prototype;
use Bolts::Scope::Singleton;

use Class::Load;


sub root { $_[0] }


has blueprint => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_blueprint {
    my $self = shift;

    my $bp = Bolts::Bag->start_bag(
        package      => 'Bolts::Meta::Locator::Blueprint',
        such_that_each => {
            does => 'Bolts::Blueprint',
        },
    );

    return $bp->name->new if $bp->is_finished_bag;

    $bp->add_artifact(
        acquired => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Acquired');
                Bolts::Blueprint::Acquired->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        given => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Given');
                Bolts::Blueprint::Given->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        literal => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Literal');
                Bolts::Blueprint::Literal->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        built => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Built');
                Bolts::Blueprint::Built->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        built_injector => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::BuiltInjector');
                Bolts::Blueprint::BuiltInjector->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        factory => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::Factory');
                Bolts::Blueprint::Factory->new(%o);
            },
        ),
    );

    $bp->add_artifact(
        parent_bag => Bolts::Artifact::Thunk->new(
            thunk => sub {
                my ($self, $bag, %o) = @_;
                Class::Load::load_class('Bolts::Blueprint::ParentBag');
                Bolts::Blueprint::ParentBag->new(%o);
            },
        ),
    );

    $bp->finish_bag;

    return $bp->name->new;
}


has inference => (
    is          => 'ro',
    isa         => 'ArrayRef',
    lazy_build  => 1,
);

sub _build_inference {
    my $self = shift;

    my $singleton = $self->scope->singleton->get($self->scope);

    return [
        Bolts::Artifact->new(
            name         => 'moose',
            blueprint    => Bolts::Blueprint::Factory->new(
                class    => 'Bolts::Inference::Moose',
            ),
            scope        => $singleton,
        ),
    ];
}


has injector => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_injector {
    my $self = shift;

    my $prototype = $self->scope->prototype->get($self->scope);

    my $parameter_name = Bolts::Artifact->new(
        name         => 'parameter_name',
        blueprint    => Bolts::Blueprint::Factory->new(
            class    => 'Bolts::Injector::Parameter::ByName',
        ),
        scope        => $prototype,
        injectors    => [
            Bolts::Injector::Parameter::ByName->new(
                key      => 'key',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 1,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'blueprint',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 1,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'does',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 0,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'isa',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 0,
                ),
            ),
            Bolts::Injector::Parameter::ByName->new(
                key      => 'name',
                blueprint => Bolts::Blueprint::Given->new(
                    required => 0,
                ),
            ),
        ],
    );

    my $bag = Bolts::Bag->start_bag(
        package        => 'Bolts::Meta::Locator::Injector',
        such_that_each => {
            does => 'Bolts::Injector',
        },
    );

    return $bag->name->new if $bag->is_finished_bag;

    $bag->add_artifact( parameter_name => $parameter_name );
    
    $bag->add_artifact(
        parameter_position => Bolts::Artifact->new(
            name         => 'parameter_position',
            blueprint    => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Injector::Parameter::ByPosition',
            ),
            infer        => 'options',
            scope        => $prototype,
        ),
    );

    $bag->add_artifact(
        setter => Bolts::Artifact->new(
            name         => 'setter',
            blueprint    => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Injector::Setter',
            ),
            infer        => 'options',
            scope        => $prototype,
        ),
    );

    $bag->add_artifact(
        store_array => Bolts::Artifact->new(
            name         => 'store_array',
            blueprint    => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Injector::Store::Array',
            ),
            infer        => 'options',
            scope        => $prototype,
        ),
    );

    $bag->add_artifact(
        store_hash => Bolts::Artifact->new(
            name         => 'store_hash',
            blueprint    => Bolts::Blueprint::Factory->new(
                class => 'Bolts::Injector::Store::Hash',
            ),
            infer        => 'options',
            scope        => $prototype,
        ),
    );

    $bag->finish_bag;

    return $bag->name->new;
}


has scope => (
    is          => 'ro',
    isa         => 'Object',
    lazy_build  => 1,
);

sub _build_scope {
    my $self = shift;

    my $singleton = Bolts::Scope::Singleton->new;
    my $prototype = Bolts::Scope::Prototype->new;

    my $prototype_artifact = Bolts::Artifact->new(
        name         => 'prototype',
        blueprint    => Bolts::Blueprint::Literal->new(
            value => $prototype,
        ),
        scope        => $singleton,
    );

    my $bag = Bolts::Bag->start_bag(
        package        => 'Bolts::Meta::Locator::Scope',
        such_that_each => {
            does => 'Bolts::Scope',
        },
    );

    return $bag->name->new if $bag->is_finished_bag;

    $bag->add_artifact(_         => $prototype_artifact);
    $bag->add_artifact(prototype => $prototype_artifact);

    $bag->add_artifact(
        singleton => Bolts::Artifact->new(
            name         => 'singleton',
            blueprint    => Bolts::Blueprint::Literal->new(
                value => $singleton,
            ),
            scope        => $singleton,
        ),
    );

    return $bag->name->new;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Meta::Locator - Standard meta locator for Bolts

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

This provides the standard meta locator for Bolts. It may be extended by your application to add custom blueprints, scopes, injectors, inferrers, and other objects.

=head1 ROLES

=over

=item *

L<Bolts::Role::RootLocator>

=back

=head1 ATTRIBUTES

=head2 root

This returns the object itself for L<Bolts::Role::Locator> to use.

=head2 blueprints

This is a bag within the meta locator containing these blueprints.

=head3 acquired

This constructs artifacts by acquisition, via L<Bolts::Blueprint::Acquired>.

=head3 given

This constructs artifacts for injection by pulling values from passed parameters, via L<Bolts::Blueprint::Given>.

=head3 literal

This constructs artifacts using a value defined when the bag is defined, via L<Bolts::Blueprint::Literal>.

=head3 built

This constructs artifacts using a subroutine given when the bag is defined, via L<Bolts::Blueprint::Built>.

=head3 build_injector

This constructs artifacts for injection using a subroutine given when the bag is defined, via L<Bolts::Blueprint::BuiltInjector>.

=head3 factory

This constructs artifacts by calling a class method on a package name, via L<Bolts::Blueprint::Factory>.

=head2 inference

This is a nested array bag containing these inferrers. (Actually, just this inferrer so far.)

=head3 moose

This infers the dependencies a L<Moose> class has by examining the attributes on it's metaclass. This inferer only works with L<Bolts::Blueprint::Factory> blueprints.

=head2 injector

This is a nested bag containing dependency injector objects. It contains these injectors.

=head3 parameter_name

Injects by passing named parameters to the blueprint, via L<Bolts::Injector::Parameter::ByName>.

=head3 parameter_position

Injects by passing parameters by position to the blueprint, via L<Bolts::Injector::Parameter::ByPosition>.

=head3 setter

Injects by calling a setter method on the constructed artifact, via L<Bolts::Injector::Setter>.

=head3 store_array

Injects into an array reference by index or push, via L<Bolts::Injector::Store::Array>.

=head3 store_hash

Injects into a hash reference by key, via L<Bolts::Injector::Store::Hash>.

=head2 scope

Nested bag containing the predefined scopes.

=head3 _

This is the default scope, which is the same as L</prototype>.

=head3 prototype

This is the non-scope scope, which never caches a value and always causes it to constructed on each acquisition, via L<Bolts::Scope::Prototype>.

=head3 singleton

This scopes an artifact to last as long as the bag containing it, via L<Bolts::Scope::Singleton>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
