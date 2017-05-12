use 5.008;
use strict;
use warnings;

package Data::Semantic::Net::IPAddress::IPv6;
BEGIN {
  $Data::Semantic::Net::IPAddress::IPv6::VERSION = '1.101760';
}
# ABSTRACT: Semantic data class for IPv6 addresses
use Net::IP qw/ip_is_ipv6 ip_iptype/;
use parent qw(Data::Semantic::Net::IPAddress);

sub is_valid_normalized_value {
    my ($self, $value) = @_;
    $self->SUPER::is_valid_normalized_value($value) && ip_is_ipv6($value);
}

sub is_internal {
    my ($self, $value) = @_;
    return unless defined $value;
    my $ip = Net::IP->new($value);
    return unless $ip;
    $ip->iptype ne 'GLOBAL-UNICAST';
}

sub normalize {
    my ($self, $value) = @_;
    my $ip = Net::IP->new($value);
    return undef unless $ip;
    $ip->short;
}

1;


__END__
=pod

=head1 NAME

Data::Semantic::Net::IPAddress::IPv6 - Semantic data class for IPv6 addresses

=head1 VERSION

version 1.101760

=head1 SYNOPSIS

    my $obj = Data::Semantic::Net::IPAddress::IPv6->new;
    if ($obj->is_valid('...')) {
        # ...
    }

=head1 DESCRIPTION

This class can tell whether a value is an IPv6 address. The C<valid()> method
will respect the inherited C<forbid_internal> boolean attribute.

=head1 METHODS

=head2 is_internal

Takes a value and returns true if the indicated IPv4 address is an internal
address.

=head2 is_valid_normalized_value

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

