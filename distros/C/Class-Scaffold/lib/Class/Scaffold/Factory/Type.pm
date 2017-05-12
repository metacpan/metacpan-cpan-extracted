use 5.008;
use warnings;
use strict;

package Class::Scaffold::Factory::Type;
BEGIN {
  $Class::Scaffold::Factory::Type::VERSION = '1.102280';
}
# ABSTRACT: Factory for framework object types
use parent 'Class::Factory::Enhanced';

sub import {
    shift;   # We don't need the package name
    my $spec = shift;
    return unless defined $spec && $spec eq ':all';
    my $pkg = caller;
    for my $symbol (Class::Scaffold::Factory::Type->get_registered_types) {
        my $factory_class =
          Class::Scaffold::Factory::Type->get_registered_class($symbol);
        no strict 'refs';
        my $target = "${pkg}::obj_${symbol}";
        *$target = sub () { $factory_class };
    }
}

# override this method with a caching version; it's called very often
sub make_object_for_type {
    my ($self, $object_type, @args) = @_;
    our %cache;
    my $class = $cache{$object_type} ||= $self->get_factory_class($object_type);
    $class->new(@args);
}

# no warnings
sub factory_log { }

sub register_factory_type {
    my ($item, @args) = @_;
    $item->SUPER::register_factory_type(@args);
    return unless $::PTAGS;
    while (my ($factory_type, $package) = splice @args, 0, 2) {
        $::PTAGS->add_tag("csft--$factory_type", "filename_for:$package", 1);
    }
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Factory::Type - Factory for framework object types

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 make_object_for_type

FIXME

=head2 factory_log

FIXME

=head2 register_factory_type

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

