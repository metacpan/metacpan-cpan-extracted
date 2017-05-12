package Alien::LibUSBx;

use 5.006;
use strict;
use warnings;

use parent 'Alien::Base';

=head1 NAME

Alien::LibUSBx - Alien package for libusb (libusb-1.0) which provides generic access to USB devices

=head1 VERSION

Version 0.12

=cut

our $VERSION = '0.12';

=head1 SYNOPSIS

C<Alien::LibUSBx> is an L<Alien> package for libusb-1.0.

On installation, C<Alien::LibUSBx> will try to detect whether or not
libusb-1.0 is already available on the system. If not, the libusb-1.0
library from L<libusbx.org> will be installed.

C<Alien::LibUSBx> is a simple extension to L<Alien::Base>, please see
L<Alien::Base::Authoring> for API reference.

=head1 AUTHOR

Henrik Brix Andersen, C<< <brix at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-alien-libusbx at
rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Alien-LibUSBx>.  I
will be notified, and then you'll automatically be notified of
progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::LibUSBx

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Alien-LibUSBx>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-LibUSBx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-LibUSBx>

=item * Search CPAN

L<http://search.cpan.org/dist/Alien-LibUSBx/>

=back

=head1 SEE ALSO

L<Alien>, L<Alien::Base>, L<Alien::Base::Authoring>, L<perlartistic>, L<perlgpl>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Henrik Brix Andersen.

This program is free software; you can redistribute it and/or modify
it under the terms of either:

=over 4

=item * the GNU General Public License as published by the Free
Software Foundation; either version 1, or (at your option) any
later version, or

=item * the "Artistic License" which comes with this Kit.

=back

The libusb-1.0 library from libusbx.org, which may be installed by
C<Alien::LibUSBx>, is released under version 2.1 of the GNU Lesser
General Public License (LGPL).

=cut

1; # End of Alien::LibUSBx
