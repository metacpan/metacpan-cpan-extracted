use 5.008;
use strict;
use warnings;

package Data::Semantic::Net::IPAddress::TestData::IPv4;
BEGIN {
  $Data::Semantic::Net::IPAddress::TestData::IPv4::VERSION = '1.101760';
}
# ABSTRACT: Test data class for the IPv4 address semantic data class
use constant TESTDATA => (
    {   args  => { forbid_internal => 0 },
        valid => [
            qw(
              127.0.0.1
              131.130.249.31
              10.0.1.3
              192.168.1.3
              198.51.100.0
              198.51.100.23
              198.51.100.255
              203.0.113.0
              203.0.113.23
              203.0.113.255
              192.0.2.0
              192.0.2.23
              192.0.2.255
              )
        ],
        invalid => [
            qw(
              127.0
              )
        ],
        normalize => {
            '213.160.065.064' => '213.160.65.64',
            '213.065.064'     => undef,
        },
    },
    {   args  => { forbid_internal => 1 },
        valid => [
            qw(
              131.130.249.31
              )
        ],
        invalid => [
            qw(
              127.0
              127.0.0.1
              10.0.1.3
              192.168.1.3
              198.51.100.0
              198.51.100.23
              198.51.100.255
              203.0.113.0
              203.0.113.23
              203.0.113.255
              192.0.2.0
              192.0.2.23
              192.0.2.255
              )
        ],
    },
);
1;


__END__
=pod

=head1 NAME

Data::Semantic::Net::IPAddress::TestData::IPv4 - Test data class for the IPv4 address semantic data class

=head1 VERSION

version 1.101760

=head1 DESCRIPTION

Defines test data for L<Data::Semantic::Net::IPAddress::IPv4_TEST>, but it is
also used in the corresponding value and domain classes, i.e.,
L<Class::Value::Net::IPAddress::IPv4_TEST> and
L<Data::Domain::Net::IPAddress::IPv4_TEST>.

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

