#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Data_Startup;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.04';
$DATE = '2004/05/27';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Data_Startup.pm' => [qw(0.04 2004/05/27), 'revised 0.03'],
    'MANIFEST' => [qw(0.04 2004/05/27), 'generated, replaces 0.03'],
    'Makefile.PL' => [qw(0.04 2004/05/27), 'generated, replaces 0.03'],
    'README' => [qw(0.04 2004/05/27), 'generated, replaces 0.03'],
    'lib/Data/Startup.pm' => [qw(0.08 2004/05/27), 'revised 0.07'],
    't/Data/Startup.d' => [qw(0.02 2004/05/27), 'revised 0.01'],
    't/Data/Startup.pm' => [qw(0.02 2004/05/27), 'revised 0.01'],
    't/Data/Startup.t' => [qw(0.02 2004/05/27), 'revised 0.01'],
    't/Data/File/Package.pm' => [qw(1.18 2004/05/27), 'unchanged'],
    't/Data/Test/Tech.pm' => [qw(1.26 2004/05/27), 'unchanged'],
    't/Data/Data/Secs2.pm' => [qw(1.26 2004/05/27), 'unchanged'],
    't/Data/Data/Str2Num.pm' => [qw(0.08 2004/05/27), 'unchanged'],
    't/ExtUtils/SVDmaker/Test.pm' => [qw(0.04 2004/05/27), 'new'],
    't/ExtUtils/SVDmaker/Algorithm/Diff.pm' => [qw(0.04 2004/05/27), 'new'],

);

########
# The ExtUtils::SVDmaker module uses the data after the __DATA__ 
# token to automatically generate this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time ExtUtils::SVDmaker generates this file.
#
#



=head1 NAME

Docs::Site_SVD::Data_Startup - startup options class, override, config methods

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Data_Startup - startup options class, override, config methods

 Revision: C

 Version: 0.04

 Date: 2004/05/27

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 Copyright: copyright © 2003 Software Diamonds

 Classification: NONE

=head1 1.0 SCOPE

This paragraph identifies and provides an overview
of the released files.

=head2 1.1 Identification

This release,
identified in L<3.2|/3.2 Inventory of software contents>,
is a collection of Perl modules that
extend the capabilities of the Perl language.

=head2 1.2 System overview

The "L<Data::Startup|Data::Startup>" module extends the Perl language (the system).

Many times there is a group of subroutines that can be tailored by
different situations with a few, say global variables.
However, global variables pollute namespaces, become mangled
when the functions are multi-threaded and probably have many 
other faults that it is not worth the time discovering.

As well documented in literature, object oriented programming do not have
these faults.
This program module class of objects provide the objectized options
for a group of subroutines or encapsulated options by using
the methods directly as in an option object.

=head2 1.3 Document overview.

This document releases Data::Startup version 0.04
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Data-Startup-0.04.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright © 2003 Software Diamonds

=item Copyright holder contact.

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=item License.

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

The installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions.

=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.

=back

=head2 3.2 Inventory of software contents

The content of the released, compressed, archieve file,
consists of the following files:

 file                                                         version date       comment
 ------------------------------------------------------------ ------- ---------- ------------------------
 lib/Docs/Site_SVD/Data_Startup.pm                            0.04    2004/05/27 revised 0.03
 MANIFEST                                                     0.04    2004/05/27 generated, replaces 0.03
 Makefile.PL                                                  0.04    2004/05/27 generated, replaces 0.03
 README                                                       0.04    2004/05/27 generated, replaces 0.03
 lib/Data/Startup.pm                                          0.08    2004/05/27 revised 0.07
 t/Data/Startup.d                                             0.02    2004/05/27 revised 0.01
 t/Data/Startup.pm                                            0.02    2004/05/27 revised 0.01
 t/Data/Startup.t                                             0.02    2004/05/27 revised 0.01
 t/Data/File/Package.pm                                       1.18    2004/05/27 unchanged
 t/Data/Test/Tech.pm                                          1.26    2004/05/27 unchanged
 t/Data/Data/Secs2.pm                                         1.26    2004/05/27 unchanged
 t/Data/Data/Str2Num.pm                                       0.08    2004/05/27 unchanged
 t/ExtUtils/SVDmaker/Test.pm                                  0.04    2004/05/27 new
 t/ExtUtils/SVDmaker/Algorithm/Diff.pm                        0.04    2004/05/27 new


=head2 3.3 Changes

Changes are as follows:

=over 4

=item Data::Startup 0.01

Originated

=item Data::Startup 0.02

FAILURE:

 From: "Thurn, Martin" <martin.thurn@ngc.com> 
 Date: Thu, 29 Apr 2004 09:21:20 -0400 (EDT) 
 Subject: FAIL Data-Startup-0.01 sun4-solaris 2.8 

I noticed that the test suite seem to fail without these modules:
Data::SecsPack

CORRECTION:

Added C<Data::SecsPack> to the test library. The test Perl site lib only
was corrupted and had a C<Data::SecsPack> install else c<vmake>
would of failed. Remove C<Data::SecsPack> from the test Perl
only site lib.

=item Data::Startup 0.03

Replaced C<Data::SecsPack> wit C<Data::Str2Num> in test library. The
C<Data::Secs2> package used form comparisions now only includes
C<Data::SecsPack> if it needs to pack numbers in accordance with
SEMI E5.

Reworked the C<new> subroutine so that it specifically handles the
case of no inputs and only accepts an array with even number of
members to initialize an option hash.

=item Data::Startup 0.04

Add capability to the C<override> subroutine so that it may handle
hashes as well as object references for the first argument.
This adds a subroutine interface to the object interface.

=back

=head2 3.4 Adaptation data.

This installation requires that the installation site
has the Perl programming language installed.
There are no other additional requirements or tailoring needed of 
configurations files, adaptation data or other software needed for this
installation particular to any installation site.

=head2 3.5 Related documents.

There are no related documents needed for the installation and
test of this release.

=head2 3.6 Installation instructions.

Instructions for installation, installation tests
and installation support are as follows:

=over 4

=item Installation Instructions.

To installed the release file, use the CPAN module
pr PPM module in the Perl release
or the INSTALL.PL script at the following web site:


 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

If all else fails, the file may be manually installed.
Enter one of the following repositories in a web browser:

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Right click on 'Data-Startup-0.04.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Data-Startup-0.04.tar.gz
 tar -xf Data-Startup-0.04.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 None.


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Data/Startup.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There are no known open issues.

=head1 4.0 NOTES

None.

=head1 2.0 SEE ALSO

=over 4

=item L<Data::Startup|Data::Startup> 

=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=back

=for html


=cut

1;

__DATA__

DISTNAME: Data-Startup^
REPOSITORY_DIR: packages^

VERSION : 0.04^
FREEZE: 1^
PREVIOUS_DISTNAME: ^
PREVIOUS_RELEASE: 0.03^
REVISION: C^


AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: startup options class, override, config methods^
TITLE   : Docs::Site_SVD::Data_Startup - startup options class, override, config methods^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/
^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

RESTRUCTURE:  ^
CHANGE2CURRENT:  ^

AUTO_REVISE: 
lib/Data/Startup.pm
t/Data/Startup.*
lib/File/Package.pm => t/Data/File/Package.pm
lib/Test/Tech.pm => t/Data/Test/Tech.pm
lib/Data/Secs2.pm => t/Data/Data/Secs2.pm
lib/Data/Str2Num.pm => t/Data/Data/Str2Num.pm
^

REPLACE: 
libperl/Test.pm => t/ExtUtils/SVDmaker/Test.pm
libperl/Algorithm/Diff.pm  => t/ExtUtils/SVDmaker/Algorithm/Diff.pm
^

PREREQ_PM:  ^
README_PODS: lib/Data/Startup.pm^
TESTS: t/Data/Startup.t^
EXE_FILES:  ^

CHANGES: 
Changes are as follows:

\=over 4

\=item Data::Startup 0.01

Originated

\=item Data::Startup 0.02

FAILURE:

 From: "Thurn, Martin" <martin.thurn@ngc.com> 
 Date: Thu, 29 Apr 2004 09:21:20 -0400 (EDT) 
 Subject: FAIL Data-Startup-0.01 sun4-solaris 2.8 

I noticed that the test suite seem to fail without these modules:
Data::SecsPack

CORRECTION:

Added C<Data::SecsPack> to the test library. The test Perl site lib only
was corrupted and had a C<Data::SecsPack> install else c<vmake>
would of failed. Remove C<Data::SecsPack> from the test Perl
only site lib.

\=item Data::Startup 0.03

Replaced C<Data::SecsPack> wit C<Data::Str2Num> in test library. The
C<Data::Secs2> package used form comparisions now only includes
C<Data::SecsPack> if it needs to pack numbers in accordance with
SEMI E5.

Reworked the C<new> subroutine so that it specifically handles the
case of no inputs and only accepts an array with even number of
members to initialize an option hash.

\=item Data::Startup 0.04

Add capability to the C<override> subroutine so that it may handle
hashes as well as object references for the first argument.
This adds a subroutine interface to the object interface.

\=back
^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The "L<Data::Startup|Data::Startup>" module extends the Perl language (the system).

Many times there is a group of subroutines that can be tailored by
different situations with a few, say global variables.
However, global variables pollute namespaces, become mangled
when the functions are multi-threaded and probably have many 
other faults that it is not worth the time discovering.

As well documented in literature, object oriented programming do not have
these faults.
This program module class of objects provide the objectized options
for a group of subroutines or encapsulated options by using
the methods directly as in an option object.

^

PROBLEMS: 
^

LICENSE:
Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

\=over 4

\=item 1

Redistributions of source code, modified or unmodified
must retain the above copyright notice, this list of
conditions and the following disclaimer. 

\=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

\=item 3

The installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions.

\=back

SOFTWARE DIAMONDS, http://www.SoftwareDiamonds.com,
PROVIDES THIS SOFTWARE 
'AS IS' AND ANY EXPRESS OR IMPLIED WARRANTIES,
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT
SHALL SOFTWARE DIAMONDS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL,EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE,DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING USE OF THIS SOFTWARE, EVEN IF
ADVISED OF NEGLIGENCE OR OTHERWISE) ARISING IN
ANY WAY OUT OF THE POSSIBILITY OF SUCH DAMAGE.
^


INSTALLATION:
To installed the release file, use the CPAN module
pr PPM module in the Perl release
or the INSTALL.PL script at the following web site:


 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

If all else fails, the file may be manually installed.
Enter one of the following repositories in a web browser:

${REPOSITORY}

Right click on '${DIST_FILE}' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip ${BASE_DIST_FILE}.tar.${COMPRESS_SUFFIX}
 tar -xf ${BASE_DIST_FILE}.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com
^

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>
^


NOTES:

^

SEE_ALSO:

\=over 4

\=item L<Data::Startup|Data::Startup> 

\=item L<ExtUtils::SVDmaker|ExtUtils::SVDmaker> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=back

^


HTML: ^

~-~


















