use strict;
use warnings;
package Alien::LibUSB;

# ABSTRACT: Perl distribution for LibUSB
our $VERSION = '0.3'; # VERSION

use parent 'Alien::Base';

=pod

=encoding utf8

=head1 NAME

Alien::LibUSB - Perl distribution for LibUSB

=head1 INSTALL

    cpan Alien::LibUSB

=head1 DESCRIPTION
    
libusb-1.0 is a C library that provides generic access to USB devices. It is intended to be used by developers to facilitate the production of applications that communicate with USB hardware.

This module is based on L<Alien::LibUSBx> by Henrik Brix Andersen, but fetches the source of the latest release on L<the libusb Github repository|http://github.com/libusb/libusb>.

=cut

1;
__END__


=head1 GIT REPOSITORY

L<http://github.com/athreef/Alien-LibUSB>

=head1 SEE ALSO

L<LibUSB|http://github.com/libusb/libusb>

L<Alien::LibUSB>

L<Alien>


=head1 AUTHOR

Ahmad Fatoum C<< <athreef@cpan.org> >>, L<http://a3f.at>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2017 Ahmad Fatoum

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
