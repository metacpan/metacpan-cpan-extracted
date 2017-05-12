use 5.008;
use strict;
use warnings;

package Data::Domain::Net::IPAddress::IPv4_TEST;
our $VERSION = '1.100840';
# ABSTRACT: Test companion class for the IPv4 address data domain class
use Data::Domain::Net ':all';
use Test::More;
use parent qw(
  Data::Domain::SemanticAdapter::Test
  Data::Semantic::Net::IPAddress::TestData::IPv4
);
use constant PLAN => 5;

sub run {
    my $self = shift;
    $self->SUPER::run(@_);
    my $domain = IPv4();
    isa_ok($domain,          'Data::Domain::Net::IPAddress::IPv4');
    isa_ok($domain,          'Data::Domain::SemanticAdapter');
    isa_ok($domain->adaptee, 'Data::Semantic::Net::IPAddress::IPv4');
    my $domain2 = IPv4(-not_in => [qw(212.186.17.4 212.186.17.5)]);
    $self->is_excluded($domain2, '212.186.17.4');
    $self->is_valid($domain2, '212.186.17.6');
}
1;


__END__
=pod

=head1 NAME

Data::Domain::Net::IPAddress::IPv4_TEST - Test companion class for the IPv4 address data domain class

=head1 VERSION

version 1.100840

=head1 DESCRIPTION

Test companion class for L<Data::Domain::Net::IPAddress::IPv4>. Gets its
test data from L<Data::Semantic::Net::IPAddress::TestData::IPv4>.

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

