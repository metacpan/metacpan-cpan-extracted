use 5.008;
use strict;
use warnings;

package Data::Domain::Net;
our $VERSION = '1.100840';
# ABSTRACT: Data domain classes for IP addresses
use Data::Domain::SemanticAdapter;
use Exporter qw(import);
our %map = (
    IPv4 => 'Net::IPAddress::IPv4',
    IPv6 => 'Net::IPAddress::IPv6',
);
our %EXPORT_TAGS = (util => [ keys %map ],);
our @EXPORT_OK = @{ $EXPORT_TAGS{all} = [ map { @$_ } values %EXPORT_TAGS ] };
Data::Domain::SemanticAdapter::install_shortcuts(%map);
1;


__END__
=pod

=head1 NAME

Data::Domain::Net - Data domain classes for IP addresses

=head1 VERSION

version 1.100840

=head1 DESCRIPTION

The classes in this distribution are data domain classes for these IP address
types:

=over 4

=item IPv4

See L<Data::Domain::Net::IPAddress::IPv4>.

=item IPv6

See L<Data::Domain::Net::IPAddress::IPv6>.

=back

Besides defining the methods described below, this class also exports, on
request, these functions:

=over 4

=item IPv4

A shortcut for creating a L<Data::Domain::Net::IPAddress::IPv4> object.
Arguments are passed on to the object's constructor.

=item IPv6

A shortcut for creating a L<Data::Domain::Net::IPAddress::IPv6> object.
Arguments are passed on to the object's constructor.

=back

By using the C<:all> tag, you can import all of them.

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Data-Domain-Net>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see
L<http://search.cpan.org/dist/Data-Domain-Net/>.

The development version lives at
L<http://github.com/hanekomu/Data-Domain-Net/>.
Instead of sending patches, please fork this project using the standard git
and github infrastructure.

=head1 AUTHOR

  Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2007 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

