# -*- mode: perl -*-
#
# $Id: SoundFile.pm,v 1.6 2002/08/21 15:05:21 tai Exp $
#

package Audio::SoundFile;

=head1 NAME

 Audio::SoundFile - Perl interface to libsndfile, a sound I/O library

=head1 SYNOPSIS

 use Audio::SoundFile;
 use Audio::SoundFile::Header;

 $header = new Audio::SoundFile::Header(...);
 $reader = new Audio::SoundFile::Reader(...);
 $writer = new Audio::SoundFile::Writer(...);
 ...

=head1 DESCRIPTION

This module provides interface to libsndfile, available from

  http://www.zip.com.au/~erikd/libsndfile/

With this library, you will be able to read, write, and manipulate
sound data of more than 10 formats.

Also, in addition to read/write interface using usual Perl scalar,
this module provides interface using PDL object directly. Since
PDL provides efficient method to handle large bytestream, sound
processing is much faster if this module and PDL is used in pair.

For rest of the details, please consult each module's document.

=cut

use PDL::Core;

use Audio::SoundFile::Header;
use Audio::SoundFile::Reader;
use Audio::SoundFile::Writer;

use strict;
use vars qw($VERSION);

$VERSION = '0.16';

=head1 NOTES

I have only tested the code with .au and .wav formats.

=head1 AUTHORS / CONTRIBUTORS

 Taisuke Yamada <tai atmark rakugaki.org>
 Aldo Calpini <dada atmark perl.it>

=head1 COPYRIGHT

Copyright (C) 2001. All rights reserved.

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=cut

1;
