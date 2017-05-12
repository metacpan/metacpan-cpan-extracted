use 5.008;
use warnings;
use strict;

package Class::Scaffold::HierarchicalDirty;
BEGIN {
  $Class::Scaffold::HierarchicalDirty::VERSION = '1.102280';
}

# ABSTRACT: Mixin that multiplexes the dirty flag among its subobjects

sub dirty {
    my $self = shift;
    for my $attr (Class::Scaffold::Accessor->factory_typed_accessors) {
        return 1 if $self->$attr->dirty;
    }
    for my $attr (Class::Scaffold::Accessor->factory_typed_array_accessors) {
        for my $element ($self->$attr) {
            return 1 if $element->dirty;
        }
    }
    return 0;
}

sub set_dirty {
    my $self = shift;
    $self->$_->set_dirty for Class::Scaffold::Accessor->factory_typed_accessors;
    for my $attr (Class::Scaffold::Accessor->factory_typed_array_accessors) {
        for my $element ($self->$attr) {
            $element->set_dirty;
        }
    }
}

sub clear_dirty {
    my $self = shift;
    $self->$_->clear_dirty
      for Class::Scaffold::Accessor->factory_typed_accessors;
    for my $attr (Class::Scaffold::Accessor->factory_typed_array_accessors) {
        for my $element ($self->$attr) {
            $element->clear_dirty;
        }
    }
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::HierarchicalDirty - Mixin that multiplexes the dirty flag among its subobjects

=head1 VERSION

version 1.102280

=head1 DESCRIPTION

This is a mixin that multiplexes the dirty flag among its subobjects using
L<Class::Accessor::FactoryTyped>'s introspection support.

=head1 METHODS

=head2 dirty

FIXME

=head2 set_dirty

FIXME

=head2 clear_dirty

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Scaffold/>.

The development version lives at
L<http://github.com/hanekomu/Class-Scaffold/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHORS

=over 4

=item *

Marcel Gruenauer <marcel@cpan.org>

=item *

Florian Helmberger <fh@univie.ac.at>

=item *

Achim Adam <ac@univie.ac.at>

=item *

Mark Hofstetter <mh@univie.ac.at>

=item *

Heinz Ekker <ek@univie.ac.at>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2008 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

