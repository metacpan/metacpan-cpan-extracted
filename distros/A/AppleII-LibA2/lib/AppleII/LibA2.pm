#---------------------------------------------------------------------
package AppleII::LibA2;
#
# Copyright 2015 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: 11 Jul 2015
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Apple II emulator & file utilities
#---------------------------------------------------------------------

our $VERSION = '0.201';
# This file is part of AppleII-LibA2 0.201 (September 12, 2015)

use 5.006;
use strict;
use warnings;

1;

__END__

=head1 NAME

AppleII::LibA2 - Apple II emulator & file utilities

=head1 VERSION

This document describes version 0.201 of
AppleII::LibA2, released September 12, 2015
as part of AppleII-LibA2 version 0.201.

=head1 DESCRIPTION

AppleII-LibA2 (formerly called LibA2, and still called that
informally) is a collection of both end-user utilities and library
modules for accessing files on Apple II ProDOS disk images for use
with most Apple II emulators.

This is a BETA release of LibA2.  There's some documentation, but it's
not complete.  If you want to see the rest of the documentation, then
send email!  Otherwise, I'll probably never get around to writing it.
Until then, use the source, Luke!  There are still probably some bugs,
and the interfaces might still change.  Use at your own risk.  Keep a
recent backup handy.  Wait sixty minutes before swimming.

All this having been said, I'm not aware of any serious bugs in LibA2
(besides the ones listed in the BUGS section below).  Good luck!
I would very much like to hear from everyone who tries LibA2.  The
more comments I get, the more likely I am to do more work on it.
Please send comments and questions to me.  Bug reports and patches
should go to the CPAN RT for LibA2: F<bug-AppleII-LibA2 AT rt.cpan.org>, or
through the web interface:

L<http://rt.cpan.org/Public/Bug/Report.html?Queue=AppleII-LibA2>

You'll find my email address at the end of this file.

=head2 Command-Line Utilities

The included utilities are:

=over 4

=item C<prodos>

L<prodos> is the main end-user utility.  It provides a
Unix-style shell for accessing ProDOS volumes.  This allows
you to list the contents of disk images, create
subdirectories, and copy files to & from disk images.  If you
have installed the Term::ReadKey and Term::ReadLine modules,
the shell will have better editing, command & filename
completion, and a command history.

The parameters for C<prodos> are:

  prodos IMAGE_FILE

=item C<pro_fmt>

L<pro_fmt> creates blank ProDOS disk images.  The images are
NOT bootable, because they lack the necessary code in the boot
blocks.  You can copy blocks from a bootable disk image to
fix this.  The parameters for C<pro_fmt> are:

  pro_fmt [options] IMAGE_FILE

=item C<pro_opt>

L<pro_opt> removes unused space from ProDOS disk images.  This
is most useful for reducing the size of hard disk images.  It
doesn't use any form of compression; it simply moves
everything to the beginning of the disk, squashing out empty
space caused by deleting files.  Be careful with this, as it's
likely to have some bugs left.  The parameters for C<pro_opt> are:

  pro_opt SOURCE_IMAGE_FILE  DESTINATION_IMAGE_FILE

=item C<awp2txt>

L<awp2txt> converts AppleWorks word processor files into text
files.  This is a bit out of place in LibA2, because it has
nothing to do with disk images, but I included it because
users of LibA2 may find it useful.  The parameters for C<awp2txt> are:

  awp2txt FILE ...

=item C<var_display>

L<var_display> lists the contents of an Applesoft BASIC VAR file.
Currently, it can only display string variables and string arrays.
Like awp2txt, you must first extract the VAR file from the disk
image.  The parameters for C<var_display> are:

  var_display FILE

=back

=head2 Modules

For people interested in writing their own utilities in Perl, LibA2
provides Perl 5 modules that supply classes for accessing ProDOS disk
images.  DOS 3.3 disks are not currently supported (except by
L<AppleII::Disk>, which doesn't care what kind of data is on the disk).

The included modules are:

=over

=item C<AppleII::Disk>

L<AppleII::Disk> provides block-level access to disk images.
It's useful because there are two main formats for Apple disk
images:  ProDOS order and DOS 3.3 order.  These formats do not
refer to the operating system used on the disk, but to the
order in which the data appears.  AppleII::Disk takes care of
the differences for you.

=item C<AppleII::ProDOS>

L<AppleII::ProDOS> provides tools for accessing files on ProDOS
disk images.  C<prodos> is basically just a wrapper around
AppleII::ProDOS.

=back

=head1 CONFIGURATION AND ENVIRONMENT

AppleII::LibA2 requires no configuration files or environment variables.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

=head1 AUTHOR

Christopher J. Madsen  S<C<< <perl AT cjmweb.net> >>>

Please report any bugs or feature requests
to S<C<< <bug-AppleII-LibA2 AT rt.cpan.org> >>>
or through the web interface at
L<< http://rt.cpan.org/Public/Bug/Report.html?Queue=AppleII-LibA2 >>.

You can follow or contribute to AppleII-LibA2's development at
L<< https://github.com/madsen/perl-libA2 >>.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Christopher J. Madsen.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENSE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.

=cut
