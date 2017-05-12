use 5.008;
use warnings;
use strict;

package Class::Scaffold::Accessor;
BEGIN {
  $Class::Scaffold::Accessor::VERSION = '1.102280';
}
# ABSTRACT: Construct framework-specific accessors
use Error::Hierarchy::Util 'assert_read_only';
use Class::Scaffold::Factory::Type;
use parent qw(
  Class::Accessor::Complex
  Class::Accessor::Constructor
  Class::Accessor::FactoryTyped
);

sub mk_framework_object_accessors {
    my ($self, @args) = @_;
    $self->mk_factory_typed_accessors('Class::Scaffold::Factory::Type', @args);
}

sub mk_framework_object_array_accessors {
    my ($self, @args) = @_;
    $self->mk_factory_typed_array_accessors('Class::Scaffold::Factory::Type',
        @args);
}

sub mk_readonly_accessors {
    my ($self, @fields) = @_;
    my $class = ref $self || $self;
    for my $field (@fields) {
        no strict 'refs';
        *{"${class}::${field}"} = sub {
            local $DB::sub = local *__ANON__ = "${class}::${field}"
              if defined &DB::DB && !$Devel::DProf::VERSION;
            my $self = shift;
            assert_read_only(@_);
            $self->{$field};
        };
        *{"${class}::set_${field}"} = *{"${class}::${field}_set"} = sub {
            local $DB::sub = local *__ANON__ = "${class}::${field}_set"
              if defined &DB::DB && !$Devel::DProf::VERSION;
            $_[0]->{$field} = $_[1];
        };
    }
    $self;    # for chaining
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Accessor - Construct framework-specific accessors

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 mk_framework_object_accessors

Makes factory-typed accessors - see L<Class::Accessor::FactoryTyped> - and
uses L<Class::Scaffold::Factory::Type> as the factory class.

=head2 mk_framework_object_array_accessors

Makes factory-typed array accessors - see L<Class::Accessor::FactoryTyped> -
and uses L<Class::Scaffold::Factory::Type> as the factory class.

=head2 mk_readonly_accessors

Takes an array of strings as its argument. For each string it creates methods
as described below, where C<*> denotes the slot name.

=over 4

=item C<*>

This method can retrieve a value from its slot. If it receives an argument, it
throws an exception. If called without a value, the method retrieves the value
from the slot. There is a method to set the value - see below -, but
separating the setter and getter methods ensures that it can't be set, for
example, using the class' constructor.

=item C<*_set>, C<set_*>

Sets the slot to the given value and returns it.

=back

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

