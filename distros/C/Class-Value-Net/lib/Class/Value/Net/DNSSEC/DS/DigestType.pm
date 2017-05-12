use 5.008;
use strict;
use warnings;

package Class::Value::Net::DNSSEC::DS::DigestType;
BEGIN {
  $Class::Value::Net::DNSSEC::DS::DigestType::VERSION = '1.110250';
}
# ABSTRACT: Network-related value objects

use parent 'Class::Value::Enum';

# http://www.iana.org/assignments/ds-rr-types/ds-rr-types.xhtml
# we support all mandatory and optional digest types.

sub get_valid_values_list {
    [
        1,         # SHA-1
        2,         # SHA-256
        3,         # GOST R 34.11-94
    ]
}

sub send_notify_value_invalid {
    my ($self, $value) = @_;
    local $Error::Depth = $Error::Depth + 2;
    $self->exception_container->record(
        'Class::Value::Net::Exception::DNSSEC::DS::InvalidDigestType',
        recordfield => $value,);
}

1;


__END__
=pod

=head1 NAME

Class::Value::Net::DNSSEC::DS::DigestType - Network-related value objects

=head1 VERSION

version 1.110250

=head1 METHODS

=head2 send_notify_value_invalid

FIXME

=head2 send_notify_value_not_wellformed

FIXME

=head1 INSTALLATION

See perlmodinstall for information and options on installing Perl modules.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests through the web interface at
L<http://rt.cpan.org/Public/Dist/Display.html?Name=Class-Value-Net>.

=head1 AVAILABILITY

The latest version of this module is available from the Comprehensive Perl
Archive Network (CPAN). Visit L<http://www.perl.com/CPAN/> to find a CPAN
site near you, or see L<http://search.cpan.org/dist/Class-Value-Net/>.

The development version lives at L<http://github.com/hanekomu/Class-Value-Net>
and may be cloned from L<git://github.com/hanekomu/Class-Value-Net.git>.
Instead of sending patches, please fork this project using the standard
git and github infrastructure.

=head1 AUTHOR

Marcel Gruenauer <marcel@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2004 by Marcel Gruenauer.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

