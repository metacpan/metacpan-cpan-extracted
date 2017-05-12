package DVD::Read::Dvd::Ifo;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.04';

require XSLoader;
XSLoader::load('DVD::Read', $VERSION);

use base qw(DVD::Read::Dvd::Ifo::Vts);
use base qw(DVD::Read::Dvd::Ifo::Vmg);

=head1 NAME

DVD::Read::Dvd::Ifo - Access to DVD IFO file using libdvdread

=head1 SYNOPSIS

  use DVD::Read::Dvd;
  use DVD::Read::Dvd::Ifo;
  my $dvd = DVD::Read::Dvd->new('/dev/cdrom');
  my $vmg = DVD::Read::Dvd::Ifo->new($dvd, 0);
  ...

=head1 DESCRIPTION

This module provide a low level access DVD IFO files
using libdvdread.

Internally, the libdvdread does not make difference between structure
for files from VMG or VTS (eg IFO 0 or any others).

So this module merge both access to functions.

You are encourage to use L<DVD::Read::Dvd::Ifo::Vmg> and
L<DVD::Read::Dvd::Ifo::Vts> module now, as they will limit access
to allowed functions.

=head1 FUNCTIONS

=head2 new($dvd, $id)

Return a new DVD::Read::Dvd::Ifo:

=over 4

=item $dvd

A DVD::Read::Dvd object.

=item $id

The title number you want to get information.

If $id is 0, you'll get the VGM information.
Otherwise $id is normal given by title_nr function
from VGM DVD::Read::Dvd::Ifo object.

=back

=head2 OTHERS FUNCTION

VMG functions are heritated from L<DVD::Read::Dvd::Ifo::Vmg> module.

VTS functions are heritated from L<DVD::Read::Dvd::Ifo::Vts> module.

See their proper documentations.

=cut

1;

__END__

=head1 CAVEAT

Most of C code come from mplayer and transcode (tcprobe).

Thanks authors of these modules to provide it as free software.

As this software are under another license, and this module reuse
code from it, the Perl license is maybe not appropriate.

Just mail me if this is a problem.

=head1 SEE ALSO

=over 4

=item L<DVD::Read::Dvd>
=item L<DVD::Read::Dvd::Vmg>
=item L<DVD::Read::Dvd::Vts>

=back

=head1 AUTHOR

Olivier Thauvin E<lt>nanardon@nanardon.zarb.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Olivier Thauvin

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

The libdvdread is under the GPL Licence.

=cut
