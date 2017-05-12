package Bolts::Blueprint;
$Bolts::Blueprint::VERSION = '0.143171';
# ABSTRACT: Defines the interface implemented by blueprints

use Moose::Role;


requires 'builder';


sub get {
    my ($self, $bag, $name, @params) = @_;

    # use Data::Dumper;
    # Carp::cluck( "BLUEPRINT GET[$name]: ", Dumper(\@params));

    $self->builder($bag, $name, @params);
}

#sub init_meta { }


sub implied_scope { }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Blueprint - Defines the interface implemented by blueprints

=head1 VERSION

version 0.143171

=head1 SYNOPSIS

    package MyApp::Blueprint::Custom;
    use Moose;

    with 'Bolts::Blueprint';

    has service_locator => (
        is         => 'ro',
        isa        => 'MyApp::ServiceLocator',
    );

    sub builder {
        my ($self, $bag, $name, @params) = @_;
        $self->service_locator($name, @params);   
    }

=head1 DESCRIPTION

A blueprint is a class for retrieving a fresh instance of a value or object on behalf of an artifact.

=head1 REQUIRED METHODS

=head2 builder

    sub builder {
        my ($self, $bag, $name, @params) = @_;
        ...
    }

This method must be implemented to perform the actual object construction. The arguments passed are as follows:

=over

=item C<$self>

This is the invocant, the blueprint object itself.

=item C<$bag>

This is the bag that contains the artifact being constructed. This is often referenced as an object giving context to the construction.

=item C<$name>

This is the name of the artifact being constructed. This is also given for context.

=item C<@params>

These are the parameters passed in during the pre-injection phase. This may be a list of parameters or hash or whatever the injectors say should be passed in.

=back

=head1 METHODS

=head2 get

    my $artifact = $blueprint->get($bag, $name, @params);

This is basically a wrapper around the call to L</builder>.

=head2 implied_scope

    my $is_implied = $blueprint->implied_scope;

Sometimes, the blueprint itself is inherently scoped. For example, a literal value is immutable and therefore saving the value to the scope would be a waste of time. Another example is a service locator that might manage it's own scope based on complex features of the application state. In those cases, you may override this method to return a true value to cause the artifact to skip saving to and checking the scope for this value and calling the blueprint every time.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
