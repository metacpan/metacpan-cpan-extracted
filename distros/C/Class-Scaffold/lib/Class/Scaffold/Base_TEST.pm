use 5.008;
use warnings;
use strict;

package Class::Scaffold::Base_TEST;
BEGIN {
  $Class::Scaffold::Base_TEST::VERSION = '1.102280';
}
# ABSTRACT: Test companion class for the general base class
use Error::Hierarchy::Test 'throws2_ok';
use Test::More;
use parent 'Class::Scaffold::Test';
use constant PLAN => 4;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my $obj = $self->make_real_object;
    isa_ok($obj->delegate, 'Class::Scaffold::Environment');
    isa_ok($obj->log,      'Class::Scaffold::Log');
    throws2_ok { $obj->foo }
    'Error::Simple',
      qr/^Undefined subroutine &Class::Scaffold::Base::foo called at/,
      'call to undefined subroutine caught by UNIVERSAL::AUTOLOAD';

    # Undef the existing error. Strangely necessary, otherwise the next
    # ->make_real_object dies with the error message still in $@, although the
    # require() in ->make_real_object should have cleared it on success...
    undef $@;
    throws2_ok { Class::Scaffold::Does::Not::Exist->new }
    'Error::Hierarchy::Internal::CustomMessage',
      qr/Couldn't load package \[Class::Scaffold::Does::Not::Exist\]:/,
      'call to undefined package caught by UNIVERSAL::AUTOLOAD';
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Base_TEST - Test companion class for the general base class

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 run

Runs the actual tests specific to this class.

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

