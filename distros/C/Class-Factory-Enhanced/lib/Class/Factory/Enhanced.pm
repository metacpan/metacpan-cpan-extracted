use 5.006;
use warnings;
use strict;

package Class::Factory::Enhanced;
BEGIN {
  $Class::Factory::Enhanced::VERSION = '1.101420';
}
# ABSTRACT: More functionality for Class::Factory

use parent 'Class::Factory';

# add support for defining several mappings at once
sub add_factory_type {
    my ($item, @args) = @_;
    my $class = ref $item || $item;

    # SUPER::add_factory_type, which only allows one mapping, returns the
    # object class. The return value is not used when defining the mappings,
    # but it is used in get_factory_class(). get_factory_class() only calls
    # this with one argument, so return the first object class we see. It's a
    # hack, yes...
    my $first_object_class;
    while (my ($object_type, $object_class) = splice @args, 0, 2) {
        $class->SUPER::remove_factory_type($object_type);
        $class->SUPER::add_factory_type($object_type, $object_class);
        $first_object_class ||= $object_class;
    }
    return $first_object_class;
}

sub register_factory_type {
    my ($item, @args) = @_;
    my $class = ref $item || $item;
    while (my ($object_type, $object_class) = splice @args, 0, 2) {
        $class->SUPER::unregister_factory_type($object_type);
        $class->SUPER::register_factory_type($object_type, $object_class);
    }
}

sub make_object_for_type {
    my ($self, $object_type, @args) = @_;
    my $class = $self->get_factory_class($object_type);
    $class->new(@args);
}
1;


__END__
=pod

=head1 NAME

Class::Factory::Enhanced - More functionality for Class::Factory

=head1 VERSION

version 1.101420

=head1 SYNOPSIS

    package My::Factory;
    use base 'Class::Factory::Enhanced';

    package Some::Class;
    My::Factory->add_factory_type(
        person_name    => 'Person::Name',
        person_address => 'Person::Address'
    );

=head1 DESCRIPTION

This class subclasses L<Class::Factory> and adds some functionality.

=head1 METHODS

=head2 add_factory_type

Like C<Class::Factory>'s C<add_factory_type()>, but this one can add several
mappings at once. See the Synopsis for an example.

=head2 register_factory_type

Like C<Class::Factory>'s C<register_factory_type()>, but this one can add
several mappings at once.

=head2 make_object_for_type

    $factory->make_object_for_type('person_name',
        last_name  => 'Shindou',
        first_name => 'Hikaru',
    );

An alternative constructor that gets the class to be constructed from the
factory, then calls C<new()> on that class.

Takes as arguments the object type to be constructed and a list of arguments
to be passed to the constructor (C<new()>) of the newly constructed object.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Factory-Enhanced>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Factory-Enhanced/>.

The development version lives at
L<http://github.com/hanekomu/Class-Factory-Enhanced/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

