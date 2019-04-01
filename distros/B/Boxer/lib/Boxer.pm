package Boxer;

=encoding UTF-8

=head1 NAME

Boxer - system deployment ninja tricks

=cut

use v5.14;
use utf8;
use strictures 2;
use Role::Commons -all;
use namespace::autoclean 0.16;

=head1 VERSION

Version v1.4.0

=cut

our $VERSION = "v1.4.0";

=head1 DESCRIPTION

Framework for system deployment ninja tricks.

See L<boxer> for further information.

=head1 BUGS

Please report any bugs to
L<http://rt.cpan.org/Dist/Display.html?Queue=Boxer>.

=head1 SEE ALSO

L<Debian Installer|https://www.debian.org/devel/debian-installer/>,
L<tasksel|https://www.debian.org/doc/manuals/debian-faq/ch-pkgtools.en.html#s-tasksel>,
L<debconf preseeding|https://wiki.debian.org/DebianInstaller/Preseed>,
L<Hands-off|http://hands.com/d-i/>

L<Debian Pure Blends|https://wiki.debian.org/DebianPureBlends>

L<Footprintless>

L<FAI class system|https://fai-project.org/fai-guide/#defining%20classes>

L<Elbe commands|https://elbe-rfs.org/docs/sphinx/elbe.html>

L<isar|https://github.com/ilbers/isar>

L<Debathena config-package-dev|https://debathena.mit.edu/config-packages/>

L<germinate|https://wiki.ubuntu.com/Germinate>

L<https://freedombox.org/>,
L<https://solidbox.org/>,
L<https://wiki.debian.org/Design>,
L<https://wiki.debian.org/DebianParl>,
L<http://box.redpill.dk/>

=head1 AUTHOR

Jonas Smedegaard C<< <dr@jones.dk> >>.

=cut

our $AUTHORITY = 'cpan:JONASS';

=head1 COPYRIGHT AND LICENCE

Copyright © 2013-2016 Jonas Smedegaard

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED
WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF
MERCHANTIBILITY AND FITNESS FOR A PARTICULAR PURPOSE.

=cut

1;
