package Bolts::Meta::Initializer;
$Bolts::Meta::Initializer::VERSION = '0.143171';
# ABSTRACT: Store a path and parameters for acquisition

use Moose;


has path => (
    is          => 'ro',
    isa         => 'ArrayRef[Str]',
    required    => 1,
    traits      => [ 'Array' ],
    handles     => { list_path => 'elements' },
);


has parameters => (
    is          => 'ro',
    isa         => 'HashRef',
    required    => 1,
);


sub BUILDARGS {
    my ($self, @path) = @_;

    my $parameters = {};
    if (@path > 1 and ref $path[-1]) {
        $parameters = pop @path;
    }

    return {
        path       => \@path,
        parameters => $parameters,
    };
}


sub get {
    my $self = shift;
    return ($self->list_path, $self->parameters);
}

__PACKAGE__->meta->make_immutable;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bolts::Meta::Initializer - Store a path and parameters for acquisition

=head1 VERSION

version 0.143171

=head1 DESCRIPTION

Describes an initializer, which is just a path and set of parameters used to make a call to L<Bolts::Role::Locator/acquire> within a L<Bolts::Role::Initializer> for any attributed tagged with the C<Bolts::Initializer> trait.

=head1 ATTRIBUTES

=head2 path

This is the path that is passed into the constructor.

=head2 parameters

This is a reference to the hash of parameters passsed into the constructor (or an empty hash if none was passed).

=head1 METHODS

=head2 new

    my $init = Bolts::Meta::Initailizer->new(@path, \%parameters);

The C<BUILDARGS> for this object has been modified so that the constructor takes arguments in the same form as L<Bolts::Role::Locator/acquire>.

=head2 get

    my (@path, \%parameters) = $init->get;

Returns the contents of this object in a form that can be passed directly on to L<Bolts::Role::Locator/acquire>.

=head1 AUTHOR

Andrew Sterling Hanenkamp <hanenkamp@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Qubling Software LLC.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
