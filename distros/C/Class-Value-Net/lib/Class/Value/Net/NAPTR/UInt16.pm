use 5.008;
use strict;
use warnings;

package Class::Value::Net::NAPTR::UInt16;
BEGIN {
  $Class::Value::Net::NAPTR::UInt16::VERSION = '1.110250';
}

# ABSTRACT: Network-related value objects
use parent 'Class::Value::Net';

sub is_well_formed_value {
    my ($self, $value) = @_;
    return unless defined $value;
    no warnings;

    # since this apparently has a charset handler now which allows only
    # digits, the only check we have left is the max range (negative numbers
    # don't work, because '-' is not a digit)
    # it's a little strange, because 'fjdkfj' and '-1' now yield
    # 'InvalidValue', whereas '1000000000000' yields a 'MalformedValue'
    # we don't want multiple exceptions for the same error, because they all
    # turn up in the epp response and the karlsplatz-guys seem quite picky
    # about that.
    # all in all: whatever.
    #$value < 0x10000;
    # 16 bit unsigned int
    $value + 0 eq $value && $value >= 0 && $value < 0x10000;
}
1;


__END__
=pod

=head1 NAME

Class::Value::Net::NAPTR::UInt16 - Network-related value objects

=head1 VERSION

version 1.110250

=head1 METHODS

=head2 is_well_formed_value

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

