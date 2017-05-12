use 5.008;
use strict;
use warnings;

package Data::Semantic::Net::IPAddress::TestData::IPv6;
BEGIN {
  $Data::Semantic::Net::IPAddress::TestData::IPv6::VERSION = '1.101760';
}

# ABSTRACT: Test data class for the IPv4 address semantic data class
use constant TESTDATA => (
    {   args  => { forbid_internal => 0 },
        valid => [
            qw(
              ::
              ::0
              001::
              ::1
              1::
              1000::
              ::131:130:1:12
              2001:0db8::
              2001:0db8:0000:0000:0000:0000:1428:57ab
              2001:0db8:0000:0000:0000::1428:57ab
              2001:0db8:0:0:0:0:1428:57ab
              2001:0db8:0:0::1428:57ab
              2001:0db8::1:0
              2001:0db8::1:0:0
              2001:0db8::1:0:0:0
              2001:0db8::1:0:0:0:0
              2001:0db8:1:0:0:0:0:0
              2001:0db8::1428:57ab
              2001::1
              2001::1:0
              2001:10::
              2001::1:0:0
              2001::1:0:0:0
              2001::1:0:0:0:0
              2001::1:0:0:0:0:0
              2001:10::dead
              2001:db8::1
              2001:db8::1428:57ab
              2001:dead:dead::10:5
              2345::1:0:0:0:2:0
              2345::1:0:0:2:0
              2345::1:0:0:2:0:0
              2345::1:0:2:0
              2345::1:0:2:0:0
              2345::1:0:2:0:0:0
              3000::1
              4000::1
              )
        ],
        invalid => [
            qw(
              0127.0000.01.000000004
              10.0.1.3
              127.0
              127.0.0.1
              127.0.0.1
              131.130.249.31
              192.168.1.3
              2001:00db8::
              2001:0db8::1:0:0:0:0:0:0
              2001:0db8::1:0:0:0:0:0:0:0
              2345::1::2
              )
        ],
        normalize => {
            '::'                     => '::',
            '::0'                    => '::',
            '001::'                  => '1::',
            '0127.0000.01.000000004' => '127.0.1.4',
            '1000::'                 => '1000::',
            '::1'                    => '::1',
            '1::'                    => '1::',
            '2001:0db8:1:0:0:0:0:0'  => '2001:db8:1::',
            '2001:0db8::1:0:0:0:0'   => '2001:db8:0:1::',
            '2001:0db8::1:0:0:0'     => '2001:db8:0:0:1::',
            '2001:0db8::1:0:0'       => '2001:db8::1:0:0',
            '2001:0db8::1:0'         => '2001:db8::1:0',
            '2001:0db8::'            => '2001:db8::',
            '2001::1:0:0:0:0:0'      => '2001:0:1::',
            '2001::1:0:0:0:0'        => '2001:0:0:1::',
            '2001::1:0:0:0'          => '2001::1:0:0:0',
            '2001::1:0:0'            => '2001::1:0:0',
            '2001::1:0'              => '2001::1:0',
            '2001:10::'              => '2001:10::',
            '2001:10::dead'          => '2001:10::dead',
            '2001::1'                => '2001::1',
            '2001:db8::1'            => '2001:db8::1',
            '2001:dead:dead::10:5'   => '2001:dead:dead::10:5',
            '2345::1:0:0:0:2:0'      => '2345:0:1::2:0',
            '2345::1:0:0:2:0:0'      => '2345:0:1::2:0:0',
            '2345::1:0:0:2:0'        => '2345::1:0:0:2:0',
            '2345::1:0:2:0:0:0'      => '2345:0:1:0:2::',
            '2345::1:0:2:0:0'        => '2345::1:0:2:0:0',
            '2345::1:0:2:0'          => '2345::1:0:2:0',
            '3000::1'                => '3000::1',
            '4000::1'                => '4000::1',
        },
    },
    {   args  => { forbid_internal => 1 },
        valid => [
            qw(
              2001::1
              2001::1:0
              2001:10::
              2001::1:0:0
              2001::1:0:0:0
              2001::1:0:0:0:0
              2001::1:0:0:0:0:0
              2001:10::dead
              2001:dead:dead::10:5
              2345::1:0:0:0:2:0
              2345::1:0:0:2:0
              2345::1:0:0:2:0:0
              2345::1:0:2:0
              2345::1:0:2:0:0
              2345::1:0:2:0:0:0
              3000::1
              )
        ],
        invalid => [
            qw(
              ::
              ::0
              001::
              0127.0000.01.000000004
              ::1
              1::
              1000::
              10.0.1.3
              127.0
              127.0.0.1
              127.0.0.1
              ::131:130:1:12
              131.130.249.31
              192.168.1.3
              2001:00db8::
              2001:0db8::
              2001:0db8:0000:0000:0000:0000:1428:57ab
              2001:0db8:0000:0000:0000::1428:57ab
              2001:0db8:0:0:0:0:1428:57ab
              2001:0db8:0:0::1428:57ab
              2001:0db8::1:0
              2001:0db8::1:0:0
              2001:0db8::1:0:0:0
              2001:0db8::1:0:0:0:0
              2001:0db8:1:0:0:0:0:0
              2001:0db8::1:0:0:0:0:0:0
              2001:0db8::1:0:0:0:0:0:0:0
              2001:0db8::1428:57ab
              2001:db8::1
              2001:db8::1428:57ab
              2345::1::2
              4000::1
              )
        ],
    },
);
1;


__END__
=pod

=head1 NAME

Data::Semantic::Net::IPAddress::TestData::IPv6 - Test data class for the IPv4 address semantic data class

=head1 VERSION

version 1.101760

=head1 DESCRIPTION

Defines test data for L<Data::Semantic::Net::IPAddress::IPv6_TEST>, but it is
also used in the corresponding value and domain classes, i.e.,
L<Class::Value::Net::IPAddress::IPv6_TEST> and
L<Data::Domain::Net::IPAddress::IPv6_TEST>.

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

