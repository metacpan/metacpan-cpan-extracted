use 5.008;
use warnings;
use strict;

package Class::Scaffold::Storable_TEST;
BEGIN {
  $Class::Scaffold::Storable_TEST::VERSION = '1.102280';
}
# ABSTRACT: Companion test class for the storable base class
use Error::Hierarchy::Test 'throws2_ok';
use Test::More;
use parent 'Class::Scaffold::Test';
use constant PLAN => 1;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    $self->make_real_object;
    throws2_ok {
        Class::Scaffold::Storable_TEST::x001->new->storage->prepare('foo');
    }
    'Error::Hierarchy::Internal::CustomMessage',
      qr/can't find method to get storage object from delegate/,
      'using non-existing storage';
}

package Class::Scaffold::Storable_TEST::x001;
BEGIN {
  $Class::Scaffold::Storable_TEST::x001::VERSION = '1.102280';
}
use parent 'Class::Scaffold::Storable';
1;

__END__
=pod

=head1 NAME

Class::Scaffold::Storable_TEST - Companion test class for the storable base class

=head1 VERSION

version 1.102280

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

