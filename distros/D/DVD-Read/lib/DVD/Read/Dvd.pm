package DVD::Read::Dvd;

use 5.010000;
use strict;
use warnings;

our $VERSION = '0.04';

use DVD::Read::Dvd::Ifo::Vmg;
use DVD::Read::Dvd::Ifo::Vts;

require XSLoader;
XSLoader::load('DVD::Read', $VERSION);

=head1 NAME

DVD::Read::Dvd - DVD access using libdvdread

=head1 SYNOPSIS

  use DVD::Read::Dvd;
  my $dvd = DVD::Read::Dvd->new('/dev/cdrom');
  print $dvd->volid;

=head1 DESCRIPTION

This module allow to get information from Video DVD using
the dvdread library.

=head1 CONSTANTS

=head2 BLOCK_SIZE

Return the logical DVD block size

=head1 FUNCTIONS

=head2 new($device)

Return a new DVD::Read::Dvd object over the $device.

$device can be a block devide, an iso file, a directory, or whatever
supported by libdvdread.

=cut

sub new {
    my ($class, $device) = @_;
    if (-d $device) { $device .= '/' }
    $class->_new($device)
}

=head2 volid

Return the DVD volume id, if possible (eg the device
used is an iso image or a real device.

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

=item L<DVD::Read::Dvd::Ifo>

=back

=head1 AUTHOR

Olivier Thauvin E<lt>nanardon@nanardon.zarb.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2008 by Olivier Thauvin

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

The libdvdread is under the GPL Licence.
