use 5.008;
use strict;
use warnings;

package Data::Semantic::Net::IPAddress;
BEGIN {
  $Data::Semantic::Net::IPAddress::VERSION = '1.101760';
}
# ABSTRACT: Base class for IP address semantic data classes
use parent qw(Data::Semantic::Net);
__PACKAGE__
    ->mk_abstract_accessors(qw(is_internal))
    ->mk_boolean_accessors(qw(forbid_internal));

sub is_valid_normalized_value {
    my ($self, $value) = @_;
    return unless $self->SUPER::is_valid_normalized_value($value);
    $self->forbid_internal ? !$self->is_internal($value) : 1;
}

1;


__END__
=pod

=head1 NAME

Data::Semantic::Net::IPAddress - Base class for IP address semantic data classes

=head1 VERSION

version 1.101760

=head1 DESCRIPTION

This class is a base class for semantic data objects representing IP addresses
- IPv4 and IPv6.

=head1 METHODS

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

