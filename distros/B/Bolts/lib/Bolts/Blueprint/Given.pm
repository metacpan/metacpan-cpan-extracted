package Bolts::Blueprint::Given;
$Bolts::Blueprint::Given::VERSION = '0.143171';
# ABSTRACT: Used to pass parameters from the user during acquisition into the injector

use Moose;

with 'Bolts::Blueprint::Role::Injector';

use Carp ();


has required => (
    is          => 'ro',
    isa         => 'Bool',
    required    => 1,
    default     => 0,
);


sub builder { 
    my ($self, $bag, $name, %params) = @_;

    Carp::croak("Missing required parameter $name")
        if $self->required and not exists $params{ $name };

    return unless exists $params{ $name };

    return $params{ $name };
}


sub exists {
    my ($self, $bag, $name, %params) = @_;

    return 1 if $self->required;
    return exists $params{ $name };
}

# sub inline_get {
#     return q[$artifact = $self->_].$name.q[;];
# }


sub implied_scope { 'singleton' }

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Blueprint::Given - Used to pass parameters from the user during acquisition into the injector

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    use Bolts;

    # Using the usual sugar...
    artifact thing => (
        ...
        parameters => {
            thing => option { # uses blueprint, given
                isa      => 'Str',
                required => 1,
            },
        },
    );

    # Or directly...
    my $meta = Bolts::Bag->start_bag;

    my $artifact = Bolts::Artifact->new(
        ...
        injectors => [
            $meta->locator->acquire('injector', 'parameter_name', {
                key       => 'thing',
                blueprint => $meta->locator->acquire('blueprint', 'given', {
                    required => 1,
                }),
                isa       => 'Str',
            }),
        ],
    );

=head1 DESCRIPTION

This takes parameters passed in during acquisition and passes them on to the injector. It is only useful for handling parameters passed during acquisition. It is a no-op if used as a regular artifact blueprint. 

=head1 ROLES

=over

=item *

L<Bolts::Blueprint::Role::Injector>

=back

=head1 ATTRIBUTES

=head2 required

The blueprint will complain if this flag is set, but the keyed parameter is not
found in those passed during acquisition.

=head1 METHODS

=head2 builder

This takes finds the parameter matching the injector key in the passed in
parameters and returns it.

=head2 exists

Returns true when the parameters contains the named key and when L</required>
is set to true.

=head2 implied_scope

This is set, but doesn't really matter since scope does not matter during
injection.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
