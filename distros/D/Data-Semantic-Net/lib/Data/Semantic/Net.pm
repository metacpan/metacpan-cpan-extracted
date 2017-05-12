use 5.008;
use strict;
use warnings;

package Data::Semantic::Net;
BEGIN {
  $Data::Semantic::Net::VERSION = '1.101760';
}
# ABSTRACT: Semantic data classes for net-related data
use parent qw(Data::Semantic);
1;


__END__
=pod

=head1 NAME

Data::Semantic::Net - Semantic data classes for net-related data

=head1 VERSION

version 1.101760

=head1 DESCRIPTION

This class is a base class for net-related semantic data classes. The
following classes are available:

=over 4

=item IPv4

See L<Data::Semantic::Net::IPAddress::IPv4>.

=item IPv6

See L<Data::Semantic::Net::IPAddress::IPv6>.

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
L<http://search.cpan.org/dist/Data-Semantic-Net/>.

The development version lives at
L<http://github.com/hanekomu/Data-Semantic-Net/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

