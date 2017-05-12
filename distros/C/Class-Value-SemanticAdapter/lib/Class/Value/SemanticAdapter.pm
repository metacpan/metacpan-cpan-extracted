use 5.008;
use strict;
use warnings;

package Class::Value::SemanticAdapter;
our $VERSION = '1.100841';
# ABSTRACT: Adapter for Data::Semantic objects
use UNIVERSAL::require;
use parent qw(Class::Value);

# Default; subclasses can redefine this. But it makes sense to keep the
# Data::Domain::* and Data::Semantic::* namespaces in sync.
sub semantic_class_name {
    my $self = shift;
    (my $semantic_class_name = ref $self) =~
      s/^Class::Value::/Data::Semantic::/;
    $semantic_class_name;
}

# FIXME might cache the adaptee unless $self->dirty;
sub adaptee {
    my $self                = shift;
    my $semantic_class_name = $self->semantic_class_name;
    $semantic_class_name->require;
    $semantic_class_name->new($self->semantic_args);
}

# Return those of the value object's attributes that are relevant to the
# semantic data object constructor.
sub semantic_args { () }

sub is_valid_value {
    my ($self, $value) = @_;
    $self->adaptee->is_valid($value);
}

sub normalize_value {
    my ($self, $value) = @_;
    $self->adaptee->normalize($value);
}

sub is_valid_normalized_value {
    my ($self, $normalized) = @_;
    $self->adaptee->is_valid_normalized_value($normalized);
}
1;


__END__
=pod

=head1 NAME

Class::Value::SemanticAdapter - Adapter for Data::Semantic objects

=head1 VERSION

version 1.100841

=head1 DESCRIPTION

This class is an adapter, a wrapper, that turns L<Data::Semantic> objects into
L<Class::Value> objects.

=head1 METHODS

=head2 semantic_class_name

Returns the corresponding semantic class name. This method provides a default
mapping, the idea of which is to mirror the layout of the Data::Semantic class
tree. If you have a different mapping, override this method in a subclass.

So in the Class::Value::URI::http class, it will return
C<Data::Semantic::URI::http>.

=head2 adaptee

Takes the results of C<semantic_class_name()> and C<semantic_args()>, loads
the semantic data class and returns a semantic data object with the given args
passed to its constructor.

=head2 semantic_args

Return those of the value object's attributes, in hash format, that are
relevant to the semantic data object constructor.

=head2 is_valid_value

Like the same method in L<Class::Value>, but forwards the question to the
adapted data semantic object.

=head2 normalize_value

Like the same method in L<Class::Value>, but forwards the question to the
adapted data semantic object.

=head2 is_valid_normalized_value

Like the same method in L<Class::Value>, but forwards the question to the
adapted data semantic object.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Value-SemanticAdapter>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Class-Value-SemanticAdapter/>.

The development version lives at
L<http://github.com/hanekomu/Class-Value-SemanticAdapter/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

