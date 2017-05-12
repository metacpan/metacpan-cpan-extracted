use 5.008;
use warnings;
use strict;

package Class::Scaffold::Delegate::Mixin;
BEGIN {
  $Class::Scaffold::Delegate::Mixin::VERSION = '1.102280';
}
# ABSTRACT: Mixin that provides access to the framework environment

# Class::Scaffold::Base inherits from this mixin, so we shouldn't use()
# Class::Scaffold::Environment, which inherits from
# Class::Scaffold::Base, creating redefined() warnings. So we just
# require() it here.
sub delegate {
    require Class::Scaffold::Environment;
    Class::Scaffold::Environment->getenv;
}
1;


__END__
=pod

=head1 NAME

Class::Scaffold::Delegate::Mixin - Mixin that provides access to the framework environment

=head1 VERSION

version 1.102280

=head1 METHODS

=head2 delegate

Returns the current framework environment singleton object.

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

