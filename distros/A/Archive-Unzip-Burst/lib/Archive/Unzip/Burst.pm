package Archive::Unzip::Burst;

# The license of this Perl code is the same as that of perl itself.
# The documentation which should be embedded at the end of this file
# should contain more details.
#
# The license of the InfoZip library which is used by this module is
# reproduced in full in the following paragraphs:
#
# This is version 2005-Feb-10 of the Info-ZIP copyright and license.
# The definitive version of this document should be available at
# ftp://ftp.info-zip.org/pub/infozip/license.html indefinitely.
# 
# 
# Copyright (c) 1990-2005 Info-ZIP.  All rights reserved.
# 
# For the purposes of this copyright and license, "Info-ZIP" is defined as
# the following set of individuals:
# 
#    Mark Adler, John Bush, Karl Davis, Harald Denker, Jean-Michel Dubois,
#    Jean-loup Gailly, Hunter Goatley, Ed Gordon, Ian Gorman, Chris Herborth,
#    Dirk Haase, Greg Hartwig, Robert Heath, Jonathan Hudson, Paul Kienitz,
#    David Kirschbaum, Johnny Lee, Onno van der Linden, Igor Mandrichenko,
#    Steve P. Miller, Sergio Monesi, Keith Owens, George Petrov, Greg Roelofs,
#    Kai Uwe Rommel, Steve Salisbury, Dave Smith, Steven M. Schweda,
#    Christian Spieler, Cosmin Truta, Antoine Verheijen, Paul von Behren,
#    Rich Wales, Mike White
# 
# This software is provided "as is," without warranty of any kind, express
# or implied.  In no event shall Info-ZIP or its contributors be held liable
# for any direct, indirect, incidental, special or consequential damages
# arising out of the use of or inability to use this software.
# 
# Permission is granted to anyone to use this software for any purpose,
# including commercial applications, and to alter it and redistribute it
# freely, subject to the following restrictions:
# 
#     1. Redistributions of source code must retain the above copyright notice,
#        definition, disclaimer, and this list of conditions.
# 
#     2. Redistributions in binary form (compiled executables) must reproduce
#        the above copyright notice, definition, disclaimer, and this list of
#        conditions in documentation and/or other materials provided with the
#        distribution.  The sole exception to this condition is redistribution
#        of a standard UnZipSFX binary (including SFXWiz) as part of a
#        self-extracting archive; that is permitted without inclusion of this
#        license, as long as the normal SFX banner has not been removed from
#        the binary or disabled.
# 
#     3. Altered versions--including, but not limited to, ports to new operating
#        systems, existing ports with new graphical interfaces, and dynamic,
#        shared, or static library versions--must be plainly marked as such
#        and must not be misrepresented as being the original source.  Such
#        altered versions also must not be misrepresented as being Info-ZIP
#        releases--including, but not limited to, labeling of the altered
#        versions with the names "Info-ZIP" (or any variation thereof, including,
#        but not limited to, different capitalizations), "Pocket UnZip," "WiZ"
#        or "MacZip" without the explicit permission of Info-ZIP.  Such altered
#        versions are further prohibited from misrepresentative use of the
#        Zip-Bugs or Info-ZIP e-mail addresses or of the Info-ZIP URL(s).
# 
#     4. Info-ZIP retains the right to use the names "Info-ZIP," "Zip," "UnZip,"
#        "UnZipSFX," "WiZ," "Pocket UnZip," "Pocket Zip," and "MacZip" for its
#        own source and binary releases.


use 5.006;
use strict;
use warnings;

BEGIN {
  if (eval "require prefork;") {
    eval "prefork->import(qw/Cwd File::Spec/)";
  }
}

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	unzip
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw();

our $VERSION = '0.08';

require XSLoader;
XSLoader::load('Archive::Unzip::Burst', $VERSION);

sub unzip {
  my $filename = shift;
  my $dir = shift;
  require Cwd;
  require File::Spec;
  if (not -f $filename) {
    die "ZIP file not found: $filename";
  }
  my $file_is_abs = File::Spec->file_name_is_absolute($filename);
  if (not $file_is_abs) {
    $filename = File::Spec->rel2abs($filename);
  }
  my $olddir = Cwd::cwd();
  mkdir($dir);
  chdir($dir) or die $!;
  my $ret = _unzip($filename);
  chdir($olddir) or die $!;
  return $ret;
}

1;
__END__

=head1 NAME

Archive::Unzip::Burst - Featureless but fast ZIP extraction

=head1 SYNOPSIS

  use Archive::Unzip::Burst 'unzip';
  unzip("zipfile.zip", "targetdirectory");

=head1 DESCRIPTION

This module is a thin XS wrapper around a copy of the well-known
InfoZip library but it does not expose its full functionality.
Instead, it only lets you extract a ZIP archive to some directory,
about as fast as if you were using your system C<unzip> command
itself.

The module comes with its own copy of InfoZip's UnZip 5.52 included.

If you are looking for a full-featured interface to ZIP archives,
you should look at L<Archive::Zip> or the various C<IO::Compress::*>
or C<IO::Uncompress::*> modules instead. Furthermore, this module
is to be considered B<experimental>. It has only been tested on
x86 and x86-64 linux and is known to fail on, for example win32.
Any help in this regard would be much appreciated.

If available, the module uses the L<prefork> pragma to load its
dependencies either on-demand run-time or at compile-time (if in
a forking environment). It does not, however, require the
C<prefork> module to be installed for normal operation.

=head2 EXPORT

None by default. But you may choose to export the C<unzip> function.

=head1 FUNCTIONS

=head2 unzip

Takes a file name and a target directory as arguments. Extracts the zip
file to the target directory. Returns the integer status code from the
underlying ZIP library. Presumably, zero means success as with system
calls. The return value may change in future versions.

=head1 SEE ALSO

The InfoZip homepage at L<http://www.info-zip.org>.

L<Archive::Zip>

L<IO::Uncompress::Unzip>

L<prefork>

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

The Perl and XS code as well as the compilation are
copyright (C) 2007 by Steffen Mueller. The following paragraph describes
the license for these components:

  This library is free software; you can redistribute it and/or modify
  it under the same terms as Perl itself, either Perl version 5.6 or,
  at your option, any later version of Perl 5 you may have available.

The UnZip library which is included in full and unmodified in a
subdirectory of this distribution is
Copyright (c) 1990-2005 Info-ZIP.  All rights reserved. The full license
text from the C<LICENSE> file in that directory is reproduced below.

  This is version 2005-Feb-10 of the Info-ZIP copyright and license.
  The definitive version of this document should be available at
  ftp://ftp.info-zip.org/pub/infozip/license.html indefinitely.
  
  
  Copyright (c) 1990-2005 Info-ZIP.  All rights reserved.
  
  For the purposes of this copyright and license, "Info-ZIP" is defined as
  the following set of individuals:
  
     Mark Adler, John Bush, Karl Davis, Harald Denker, Jean-Michel Dubois,
     Jean-loup Gailly, Hunter Goatley, Ed Gordon, Ian Gorman, Chris Herborth,
     Dirk Haase, Greg Hartwig, Robert Heath, Jonathan Hudson, Paul Kienitz,
     David Kirschbaum, Johnny Lee, Onno van der Linden, Igor Mandrichenko,
     Steve P. Miller, Sergio Monesi, Keith Owens, George Petrov, Greg Roelofs,
     Kai Uwe Rommel, Steve Salisbury, Dave Smith, Steven M. Schweda,
     Christian Spieler, Cosmin Truta, Antoine Verheijen, Paul von Behren,
     Rich Wales, Mike White
  
  This software is provided "as is," without warranty of any kind, express
  or implied.  In no event shall Info-ZIP or its contributors be held liable
  for any direct, indirect, incidental, special or consequential damages
  arising out of the use of or inability to use this software.
  
  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

      1. Redistributions of source code must retain the above copyright notice,
         definition, disclaimer, and this list of conditions.
  
      2. Redistributions in binary form (compiled executables) must reproduce
         the above copyright notice, definition, disclaimer, and this list of
         conditions in documentation and/or other materials provided with the
         distribution.  The sole exception to this condition is redistribution
         of a standard UnZipSFX binary (including SFXWiz) as part of a
         self-extracting archive; that is permitted without inclusion of this
         license, as long as the normal SFX banner has not been removed from
         the binary or disabled.
  
      3. Altered versions--including, but not limited to, ports to new operating
         systems, existing ports with new graphical interfaces, and dynamic,
         shared, or static library versions--must be plainly marked as such
         and must not be misrepresented as being the original source.  Such
         altered versions also must not be misrepresented as being Info-ZIP
         releases--including, but not limited to, labeling of the altered
         releases--including, but not limited to, labeling of the altered
         versions with the names "Info-ZIP" (or any variation thereof, including,
         but not limited to, different capitalizations), "Pocket UnZip," "WiZ"
         or "MacZip" without the explicit permission of Info-ZIP.  Such altered
         versions are further prohibited from misrepresentative use of the
         Zip-Bugs or Info-ZIP e-mail addresses or of the Info-ZIP URL(s).
  
      4. Info-ZIP retains the right to use the names "Info-ZIP," "Zip," "UnZip,"
         "UnZipSFX," "WiZ," "Pocket UnZip," "Pocket Zip," and "MacZip" for its
         own source and binary releases.

To my best knowledge, it should be legal to use and distribute this Perl module
and its enclosed library freely, as well as commercially provided the above
license information is not stripped. Thus, the license of the InfoZip
library should not collide with the license of the compilation.
But I am not a lawyer.

=cut
