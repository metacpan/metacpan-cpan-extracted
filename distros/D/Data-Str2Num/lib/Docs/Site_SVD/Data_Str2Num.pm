#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Data_Str2Num;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.07';
$DATE = '2004/05/22';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Data_Str2Num.pm' => [qw(0.07 2004/05/22), 'revised 0.06'],
    'MANIFEST' => [qw(0.07 2004/05/22), 'generated, replaces 0.06'],
    'Makefile.PL' => [qw(0.07 2004/05/22), 'generated, replaces 0.06'],
    'README' => [qw(0.07 2004/05/22), 'generated, replaces 0.06'],
    'lib/Data/Str2Num.pm' => [qw(0.08 2004/05/22), 'revised 0.05'],
    't/Data/Str2Num.d' => [qw(0.03 2004/05/19), 'unchanged'],
    't/Data/Str2Num.pm' => [qw(0.04 2004/05/19), 'unchanged'],
    't/Data/Str2Num.t' => [qw(0.04 2004/05/19), 'unchanged'],
    't/Data/File/Package.pm' => [qw(1.17 2004/05/22), 'unchanged'],
    't/Data/Test/Tech.pm' => [qw(1.26 2004/05/22), 'unchanged'],
    't/Data/Data/Secs2.pm' => [qw(1.26 2004/05/22), 'revised 1.23'],
    't/Data/Data/Startup.pm' => [qw(0.07 2004/05/22), 'revised 0.06'],

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

Docs::Site_SVD::Data_Str2Num - int str to int; float str to float; else undef. No warnings.

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Data_Str2Num - int str to int; float str to float; else undef. No warnings.

 Revision: D

 Version: 0.07

 Date: 2004/05/22

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

The "L<Data::Str2Num|Data::Str2Num>" module extends the Perl language (the system).

The "Data::Str2Num" package translates an scalar string to a scalar integer.
The package handles parser out of wide range of integers and floats from
an alphanumeric string in different formats.

Perl itself has a documented function, '0+$x', that converts a scalar to
so that its internal storage is an integer
(See p.351, 3rd Edition of Programming Perl).
If it cannot perform the conversion, it leaves the integer 0.
Surprising not all Perls, some Microsoft Perls in particular, may leave
the internal storage as a scalar string.

The "str2int" function is basically the same except if it cannot perform
the conversion to an integer, it returns an "undef" instead of a 0.
Also, if the string is a decimal or floating point, it will return an undef.
This makes it not only useful for forcing an integer conversion but
also for testing a scalar to see if it is in fact an integer scalar.

=head2 1.3 Document overview.

This document releases Data::Str2Num version 0.07
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Data-Str2Num-0.07.tar.gz

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
 lib/Docs/Site_SVD/Data_Str2Num.pm                            0.07    2004/05/22 revised 0.06
 MANIFEST                                                     0.07    2004/05/22 generated, replaces 0.06
 Makefile.PL                                                  0.07    2004/05/22 generated, replaces 0.06
 README                                                       0.07    2004/05/22 generated, replaces 0.06
 lib/Data/Str2Num.pm                                          0.08    2004/05/22 revised 0.05
 t/Data/Str2Num.d                                             0.03    2004/05/19 unchanged
 t/Data/Str2Num.pm                                            0.04    2004/05/19 unchanged
 t/Data/Str2Num.t                                             0.04    2004/05/19 unchanged
 t/Data/File/Package.pm                                       1.17    2004/05/22 unchanged
 t/Data/Test/Tech.pm                                          1.26    2004/05/22 unchanged
 t/Data/Data/Secs2.pm                                         1.26    2004/05/22 revised 1.23
 t/Data/Data/Startup.pm                                       0.07    2004/05/22 revised 0.06


=head2 3.3 Changes

Changes are as follows:

=over 4

=item Data::Str2Num 0.01

Originated

=item Data::Str2Num 0.02

Added 1 to end of the code section. 
Unix Perls very strict about this one.

=item Data::Str2Num 0.03

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

=item Data::Str2Num 0.04

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Data, the same directory as the test script
and deleting the test library File::TestPath program module.

The C<Data::Str2Num> module is now obsolete and superceded by
the C<Data::SecsPack> module.
Replace all subroutines to call the compatible subroutines
in the C<Data:SecsPack> module
and make any necessary manipulates to
provide exact equivalent of the old C<Data::Str2Num> subroutines.

=item Data::Str2Num 0.05

Changed the abstract to 'obsoleted by Data::Secs2'

=item Data::Str2Num 0.06

It was a mistake to merge C<Data::Str2Num> subroutines with
the C<Data::Secs2> and C<Data::SecsPack> modules.
These are specialized modules. There are many cases
where do not need nor want all that SEMI E5 support.
Keep these separate means one does not have to deal
with all that SEMI business if one just needs 
the functionality of these subroutines.

=item Data::Str2Num 0.07

In C<str2integer> and C<str2float> subroutine, skip
empty and undef strings. Processing produces all kinds of
uninitialize errors.

Add documentation for the C<str2int> subroutine.

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

Right click on 'Data-Str2Num-0.07.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Data-Str2Num-0.07.tar.gz
 tar -xf Data-Str2Num-0.07.tar
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

 t/Data/Str2Num.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There is still much work needed to ensure the quality 
of this module as follows:

=over 4

=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

=item *

All the tests are GO path tests. Should add
NOGO tests.

=item *

Add the requirements addressed as I<# R: >
comment to the tests

=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
Test::TestUtil POD.

=back

=head1 4.0 NOTES

The following are useful acronyms:

=over 4

=item .d

extension for a Perl demo script file

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=back

=head1 2.0 SEE ALSO

=over 4

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=back

=for html


=cut

1;

__DATA__

DISTNAME: Data-Str2Num^
REPOSITORY_DIR: packages^

VERSION : 0.07^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.06^
REVISION: D^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT:int str to int; float str to float; else undef. No warnings.^
TITLE   : Docs::Site_SVD::Data_Str2Num - int str to int; float str to float; else undef. No warnings.^
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
lib/Data/Str2Num.pm
t/Data/Str2Num.*
lib/File/Package.pm => t/Data/File/Package.pm
lib/Test/Tech.pm => t/Data/Test/Tech.pm
lib/Data/Secs2.pm => t/Data/Data/Secs2.pm
lib/Data/Startup.pm => t/Data/Data/Startup.pm
^

PREREQ_PM: ^
README_PODS: lib/Data/Str2Num.pm^
TESTS: t/Data/Str2Num.t^
EXE_FILES:  ^

CHANGES: 
Changes are as follows:

\=over 4

\=item Data::Str2Num 0.01

Originated

\=item Data::Str2Num 0.02

Added 1 to end of the code section. 
Unix Perls very strict about this one.

\=item Data::Str2Num 0.03

Change the test so that test support program modules resides in distribution
directory tlib directory instead of the lib directory. 
Because they are no longer in the lib directory, 
test support files will not be installed as a pre-condition for the 
test of this module.
The test of this module will precede immediately.
The test support files in the tlib directory will vanish after
the installtion.

\=item Data::Str2Num 0.04

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Data, the same directory as the test script
and deleting the test library File::TestPath program module.

The C<Data::Str2Num> module is now obsolete and superceded by
the C<Data::SecsPack> module.
Replace all subroutines to call the compatible subroutines
in the C<Data:SecsPack> module
and make any necessary manipulates to
provide exact equivalent of the old C<Data::Str2Num> subroutines.

\=item Data::Str2Num 0.05

Changed the abstract to 'obsoleted by Data::Secs2'

\=item Data::Str2Num 0.06

It was a mistake to merge C<Data::Str2Num> subroutines with
the C<Data::Secs2> and C<Data::SecsPack> modules.
These are specialized modules. There are many cases
where do not need nor want all that SEMI E5 support.
Keep these separate means one does not have to deal
with all that SEMI business if one just needs 
the functionality of these subroutines.

\=item Data::Str2Num 0.07

In C<str2integer> and C<str2float> subroutine, skip
empty and undef strings. Processing produces all kinds of
uninitialize errors.

Add documentation for the C<str2int> subroutine.

\=back
^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The "L<Data::Str2Num|Data::Str2Num>" module extends the Perl language (the system).

The "Data::Str2Num" package translates an scalar string to a scalar integer.
The package handles parser out of wide range of integers and floats from
an alphanumeric string in different formats.

Perl itself has a documented function, '0+$x', that converts a scalar to
so that its internal storage is an integer
(See p.351, 3rd Edition of Programming Perl).
If it cannot perform the conversion, it leaves the integer 0.
Surprising not all Perls, some Microsoft Perls in particular, may leave
the internal storage as a scalar string.

The "str2int" function is basically the same except if it cannot perform
the conversion to an integer, it returns an "undef" instead of a 0.
Also, if the string is a decimal or floating point, it will return an undef.
This makes it not only useful for forcing an integer conversion but
also for testing a scalar to see if it is in fact an integer scalar.

^

PROBLEMS:
There is still much work needed to ensure the quality 
of this module as follows:

\=over 4

\=item *

State the functional requirements for each method 
including not only the GO paths but also what to
expect for the NOGO paths

\=item *

All the tests are GO path tests. Should add
NOGO tests.

\=item *

Add the requirements addressed as I<# R: >
comment to the tests

\=item *

Write a program to build a matrix to trace
test step to the requirements and vice versa by
parsing the I<# R: > comments.
Automatically insert the matrix in the
Test::TestUtil POD.

\=back

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

SUPPORT: 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>^

NOTES:
The following are useful acronyms:

\=over 4

\=item .d

extension for a Perl demo script file

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=back
^

SEE_ALSO: 
\=over 4

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=back
^

HTML: ^

~-~


















