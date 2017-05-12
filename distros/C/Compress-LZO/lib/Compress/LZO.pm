#  LZO.pm -- Perl bindings for the LZO data compression library
#
#  This file is part of the LZO real-time data compression library.
#
#  Copyright (C) 2002 Markus Franz Xaver Johannes Oberhumer
#  Copyright (C) 2001 Markus Franz Xaver Johannes Oberhumer
#  Copyright (C) 2000 Markus Franz Xaver Johannes Oberhumer
#  Copyright (C) 1999 Markus Franz Xaver Johannes Oberhumer
#  Copyright (C) 1998 Markus Franz Xaver Johannes Oberhumer
#  All Rights Reserved.
#
#  The LZO library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License as
#  published by the Free Software Foundation; either version 2 of
#  the License, or (at your option) any later version.
#
#  The LZO library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with the LZO library; see the file COPYING.
#  If not, write to the Free Software Foundation, Inc.,
#  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
#
#  Markus F.X.J. Oberhumer
#  <markus@oberhumer.com>
#  http://www.oberhumer.com/opensource/lzo/


package Compress::LZO;
$Compress::LZO::VERSION = '1.09';
$VERSION = "1.09";

require 5.003_05;
require Exporter;
require DynaLoader;
use AutoLoader;
use Carp;

use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $AUTOLOAD);

@ISA = qw(Exporter DynaLoader);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.
@EXPORT = qw(
	LZO_VERSION LZO_VERSION_STRING LZO_VERSION_DATE
);

@EXPORT_OK = qw(
	compress decompress optimize
	adler32 crc32
	LZO_VERSION LZO_VERSION_STRING LZO_VERSION_DATE
);


sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.
    my($constname);
    ($constname = $AUTOLOAD) =~ s/.*:://;
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Compress::LZO macro $constname not defined";
	}
    }
    eval "sub $AUTOLOAD { $val }";
    goto &$AUTOLOAD;
}

bootstrap Compress::LZO $VERSION;

# Preloaded methods go here.


1;
# Autoload methods go after __END__, and are processed by the autosplit program.

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Compress::LZO

=head1 VERSION

version 1.09

=head1 SYNOPSIS

    use Compress::LZO;

    $dest = Compress::LZO::compress($source, [$level]);
    $dest = Compress::LZO::decompress($source);
    $dest = Compress::LZO::optimize($source);

    $crc = Compress::LZO::adler32($buffer [,$crc]);
    $crc = Compress::LZO::crc32($buffer [,$crc]);

    LZO_VERSION, LZO_VERSION_STRING, LZO_VERSION_DATE

=head1 DESCRIPTION

The I<Compress::LZO> module provides a Perl interface to the I<LZO>
compression library (see L</AUTHOR> for details about where to get
I<LZO>). A relevant subset of the functionality provided by I<LZO>
is available in I<Compress::LZO>.

All string parameters can either be a scalar or a scalar reference.

=head1 NAME

Compress::LZO - Interface to the LZO compression library

=head1 COMPRESSION FUNCTIONS

$dest = Compress::LZO::compress($string)

Compress a string using the default compression level, returning a string
containing compressed data.

$dest = Compress::LZO::compress($string, $level)

Compress string, using the chosen compression level (either 1 or 9).
Return a string containing the compressed data.

If the string is not compressible, I<undef> is returned.

=head1 DECOMPRESSION FUNCTIONS

$dest = Compress::LZO::decompress($string)

Decompress the data in string, returning a string containing the
decompressed data.

On error (in case of corrupted data) I<undef> is returned.

=head1 OPTIMIZATION FUNCTIONS

$dest = Compress::LZO::optimize($string)

Optimize the representation of the compressed data, returning a
string containing the compressed data.

On error I<undef> is returned.

=head1 CHECKSUM FUNCTIONS

Two functions are provided by I<LZO> to calculate a checksum. For the
Perl interface the order of the two parameters in both functions has
been reversed. This allows both running checksums and one off
calculations to be done.

    $crc = Compress::LZO::adler32($string [,$initialAdler]);
    $crc = Compress::LZO::crc32($string [,$initialCrc]);

=head1 AUTHOR

The I<Compress::LZO> module was written by Markus F.X.J. Oberhumer
F<markus@oberhumer.com>.
The latest copy of the module should also be found on CPAN in
F<modules/by-module/Compress/Compress-LZO-x.y.tar.gz>.

The I<LZO> compression library was written by Markus F.X.J. Oberhumer
F<markus@oberhumer.com>.
It is available from the LZO home page at
F<http://www.oberhumer.com/opensource/lzo/>.

The I<LZO> library and algorithms
are Copyright (C) 1996, 1997, 1998, 1999, 2000, 2001, 2002 by
Markus Franz Xaver Johannes Oberhumer F<markus@oberhumer.com>.
All Rights Reserved.

=head1 MODIFICATION HISTORY

1.08  2002-08-29  Updated for Perl 5.8.0.

1.00  1998-08-22  First public release of I<Compress::LZO>.

=head1 AUTHOR

Markus Franz Xaver Johannes Oberhumer <markus@oberhumer.com>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1996, 1997, 1998, 1999, 2000, 2001, 2002 by Markus Franz Xaver Johannes Oberhumer.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
