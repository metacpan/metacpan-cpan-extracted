use 5.008;
use warnings;
use strict;

package Class::Scaffold::BusinessObject;
BEGIN {
  $Class::Scaffold::BusinessObject::VERSION = '1.102280';
}
# ABSTRACT: Base class for framework business objects
use Error::Hierarchy::Util 'assert_defined';
use parent qw(
  Class::Scaffold::Storable
  Class::Scaffold::HierarchicalDirty
);
__PACKAGE__->mk_scalar_accessors(qw(key_name))
  ->mk_abstract_accessors(qw(key object_type));
use constant DEFAULTS => (key_name => 'key field',);

# Each business object can tell its defining key, e.g. handle for persons,
# domainname for domains etc.

sub check { }

sub used_objects {
    my $self = shift;
    ($self->object_type => $self->key);
}

sub assert_key {
    my $self = shift;
    local $Error::Depth = $Error::Depth + 1;
    assert_defined $self->key,
      sprintf('called without defined %s', $self->key_name);
}

sub store {
    my $self = shift;
    if ($self->key) {
        $self->update;
    } else {
        $self->insert;
    }
}
use constant SKIP_COMPARABLE_KEYS => ('key_name');

sub apply_instruction_container { }
1;


__END__
=pod

=head1 NAME

Class::Scaffold::BusinessObject - Base class for framework business objects

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 apply_instruction_container

This method will be called with an instruction container object and is
expected to apply the instructions contained therein to the business object.
In this base class the method does nothing; subclasses will implement it.

=head2 assert_key

Checks that the business object defines a key. If it does not, an exception is
raised.

=head2 check

This method is given an exception container, which it fills with exceptions
that arise from checking. Since we're dealing exclusively with value objects,
we can check for valid characters, field lengths, some wellformedness and
validity (in case of email value objects, for example), all from within
the business objects themselves. By moving part of the checking code into
the objects themselves we make the policy stage more generic. Other
registries can simply define business objects in terms of different value
objects.

=head2 store

If the business object has a defined key, it will be updated, otherwise it
will be stored. The business object will have a key when it has been stored or
originally read from the storage. New business objects that haven't been
stored yet won't have a key, so they will be inserted.

=head2 used_objects

Returns a value pair where the first value is the object type and the second
value is the business object's key.

FIXME: This method is used in conjunction with keywords in Registry-Core and
might be better placed in that distribution.

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

