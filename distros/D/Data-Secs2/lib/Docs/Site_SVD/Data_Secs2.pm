#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Data_Secs2;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.09';
$DATE = '2004/05/20';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Data_Secs2.pm' => [qw(0.09 2004/05/20), 'revised 0.08'],
    'MANIFEST' => [qw(0.09 2004/05/20), 'generated, replaces 0.08'],
    'Makefile.PL' => [qw(0.09 2004/05/20), 'generated, replaces 0.08'],
    'README' => [qw(0.09 2004/05/20), 'generated, replaces 0.08'],
    'lib/Data/Secs2.pm' => [qw(1.25 2004/05/20), 'revised 1.23'],
    't/Data/Secs2.d' => [qw(0.06 2004/05/11), 'unchanged'],
    't/Data/Secs2.pm' => [qw(0.06 2004/05/11), 'unchanged'],
    't/Data/Secs2.t' => [qw(0.07 2004/05/11), 'unchanged'],
    't/Data/File/Package.pm' => [qw(1.17 2004/05/20), 'unchanged'],
    't/Data/File/SmartNL.pm' => [qw(1.16 2004/05/20), 'revised 1.15'],
    't/Data/Text/Scrub.pm' => [qw(1.14 2004/05/20), 'revised 1.13'],
    't/Data/Test/Tech.pm' => [qw(1.26 2004/05/20), 'revised 1.25'],
    't/Data/Data/SecsPack.pm' => [qw(0.08 2004/05/20), 'revised 0.07'],
    't/Data/Data/Str2Num.pm' => [qw(0.06 2004/05/20), 'new'],
    't/Data/Data/Startup.pm' => [qw(0.07 2004/05/20), 'revised 0.06'],

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

Docs::Site_SVD::Data_Secs2 - pack, unpack, format between Perl data and SEMI E5-94 nested data

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Data_Secs2 - pack, unpack, format between Perl data and SEMI E5-94 nested data

 Revision: G

 Version: 0.09

 Date: 2004/05/20

 Prepared for: General Public 

 Prepared by:  SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>

 Copyright: copyright 2003 2004 Software Diamonds

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

The 'Data::Strify' module provides a canoncial string for data
no matter how many nests of arrays and hashes it contains.

=head2 1.3 Document overview.

This document releases Data::Secs2 version 0.09
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Data-Secs2-0.09.tar.gz

found at the following repository(s):

  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/

Restrictions regarding duplication and license provisions
are as follows:

=over 4

=item Copyright.

copyright 2003 2004 Software Diamonds

=item Copyright holder contact.

 603 882-0846 E<lt> support@SoftwareDiamonds.com E<gt>

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

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.


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
 lib/Docs/Site_SVD/Data_Secs2.pm                              0.09    2004/05/20 revised 0.08
 MANIFEST                                                     0.09    2004/05/20 generated, replaces 0.08
 Makefile.PL                                                  0.09    2004/05/20 generated, replaces 0.08
 README                                                       0.09    2004/05/20 generated, replaces 0.08
 lib/Data/Secs2.pm                                            1.25    2004/05/20 revised 1.23
 t/Data/Secs2.d                                               0.06    2004/05/11 unchanged
 t/Data/Secs2.pm                                              0.06    2004/05/11 unchanged
 t/Data/Secs2.t                                               0.07    2004/05/11 unchanged
 t/Data/File/Package.pm                                       1.17    2004/05/20 unchanged
 t/Data/File/SmartNL.pm                                       1.16    2004/05/20 revised 1.15
 t/Data/Text/Scrub.pm                                         1.14    2004/05/20 revised 1.13
 t/Data/Test/Tech.pm                                          1.26    2004/05/20 revised 1.25
 t/Data/Data/SecsPack.pm                                      0.08    2004/05/20 revised 0.07
 t/Data/Data/Str2Num.pm                                       0.06    2004/05/20 new
 t/Data/Data/Startup.pm                                       0.07    2004/05/20 revised 0.06


=head2 3.3 Changes

Changes to past revisions are as follows: 

=over 4

=item Data-Strify-0.01

Originated

=item Data-Secs2-0.01

Abandoned Data::Dumper in favor of SEMI E35,
SECS-II standard for stringifying Perl data.

=item Data-Secs2-0.02

Added arrayification of REF and GLOB references.
Thus, the 'Data::Secs2' module will nest into
REF and GLOB references.

=item Data-Secs2-0.03

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Data, the same directory as the test script
and deleting the test library File::TestPath program module.

=item Data-Secs2-0.04

Greater expanded the subroutines to the following: arrayify, itemify, 
listify, neuterify, scalarize, secsify, stringify, transify, vectorize.
Added descriptions and tests for the new functions.

=item Data-Secs2-0.05

Change Perlify to allow translation packed multi-cell number item elements
as number arrays. Single cell number item elements are still translated
as a number scalar. This situation exists because SEMI E5 treats a
single text character and a single number as a cell, while Perl treats
multiple characters and a single number as a scalar. Granted
there is the Perl function C<vec> that allows some manipulation
of multicell data. But it is stretch to say that because of the 
C<vec> function that multicell integers are an underlying Perl data
type.

Added C<new> and C<config> subroutine to supply the default, (startup)
options for each subroutine in the C<Data::Secs2> program module.
The default options may be overriden with a subroutine input for
most subroutines.

The Perl undef was not finding a home in the SECS2 Object. Found a home
as a SEMI E5-94 empty list L[0].

Added support for the C<CODE> underlying Perl data type.

=item Data-Secs2-0.06

Changed the definition of a C<SECS Object>, eliminating the option of have
numbers packed or unpacked to unpack only. Replaced the slot for packed
with a new encoding of a 'Numeric Scalar'. 
Perl does not  support 'Test Scalars' while the SEMI E5-94 standard does not 
support neither scalars. Other languages, such as APL, support nested array,
'Text Scalars' and 'Numeric Scalars'.

BEFORE: (Data-Secs2-0.05)

 U1
 [1 2 3] # unpacked

 U1
 $*%  # packed


AFTER: (Data-Secs2-0.06)

 U1
 [1 2 3]  # numeric array

 U1
 1  # numeric scalar

 A
 'hello'  # text array

 A
 'h' # text scalar

Note that altough text scalars are possible and exist in other
languages, the C<Data::Secs2> program module
does not provide support for them.
In Perl what other languages consider text arrays are text scalars.
Since underlying Perl language does not
support them, they are not part of common Perl practices, and
turning Perl text arrays into text scalars and introducing
text arrays require extensive gyrations to Perl.

Added a new format type to C<SECS Object> with unspecified
bytes per cell, format 'N', where the 'N' stands for number.
Eliminated the C<textify> and C<numerify> subroutines that
packed and unpacked C<SECS Object> numeric data. It is always
unpacked for C<Data-Secs2>. Eliminated the C<perl_secs_numbers>
for the C<listify> subroutine. Since have a crystal clear encoding
of scalar numberics and scalar arrays (lists), Perl numeric arrays will
always be encoded as 'multicell' when going form Perl nested lists to
C<SECS Object>.

Changed the output of the C<perlify> subroutine from a list of
variables to a reference to a list of variables and introduced
a scalar as an error message. This allows another way to
output error messages beside optional C<warns> and C<dies>.

=item Data-Secs2-0.07

The C<secs_elementify> subroutine did not handle a numeric zero properly.
Added test for numeric zero and undef.

=item Data-Secs2-0.08

Documentation woes.
The SEMI link does not work on. Changed to SEMI, http://www.semi.org.
The new SVD =head1 NAME is masking out the code program module.
Changed the SVD =head1 NAME so not same as code program module =head1 NAME

=item Data-Secs2-0.09

Change C<use Data::SecsPack> to C<require Data::SecsPack> so that it is not loaded
unless using C<Data::Secs2> to pack and unpack SEMI E5 numbers.

Move C<str2float> and C<str2int> from C<Data::SecsPack> to C<Data::Str2Num> so
that the C<Data::Secs2> package and other packages may load them without loading
the subroutines to pack and unpack numbers in the C<Data::SecsPack> subroutine.

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

Right click on 'Data-Secs2-0.09.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Data-Secs2-0.09.tar.gz
 tar -xf Data-Secs2-0.09.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'Data::SecsPack' => '0.06',
 'Data::Str2Num' => '0.05',
 'Data::Startup' => '0.02'


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Data/Secs2.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt> support@SoftwareDiamonds.com E<gt>

=back

=head2 3.7 Possible problems and known errors

None.

=head1 4.0 NOTES

The following are useful acronyms:

=over 4

=item .d

extension for a Perl demo script file

=item .pm

extension for a Perl Library Module

=item .t

extension for a Perl test script file

=item POD

Plain Old Documentation

=back

=head1 2.0 SEE ALSO

=over 4

=item L<Data::Secs2|Data::Secs2> 

=item L<Data::SecsPack|Data::SecsPack> 

=item L<Data::Startup|Data::Startup> 

=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

=item L<Docs::US_DOD::STD|Docs::US_DOD::STD> 

=back

=for html
<p><br>

=cut

1;

__DATA__

DISTNAME: Data-Secs2^
VERSION : 0.09^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.08^
REVISION: G^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: pack, unpack, format, transform between Perl data and SEMI E5-94 SECS-II nested data^
TITLE   : Docs::Site_SVD::Data_Secs2 - pack, unpack, format between Perl data and SEMI E5-94 nested data^
END_USER: General Public^
COPYRIGHT: copyright 2003 2004 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^
REPOSITORY_DIR: packages^
REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN/authors/id/S/SO/SOFTDIA/
^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

RESTRUCTURE:  ^
CHANGE2CURRENT:  ^

AUTO_REVISE: 
lib/Data/Secs2.pm
t/Data/Secs2.*
lib/File/Package.pm => t/Data/File/Package.pm
lib/File/SmartNL.pm => t/Data/File/SmartNL.pm
lib/Text/Scrub.pm => t/Data/Text/Scrub.pm
lib/Test/Tech.pm => t/Data/Test/Tech.pm
lib/Data/SecsPack.pm => t/Data/Data/SecsPack.pm
lib/Data/Str2Num.pm => t/Data/Data/Str2Num.pm
lib/Data/Startup.pm => t/Data/Data/Startup.pm
^

REPLACE:
^

PREREQ_PM:
'Data::SecsPack' => '0.06',
'Data::Str2Num' => '0.05',
'Data::Startup' => '0.02'
^
README_PODS: lib/Data/Secs2.pm^
TESTS: t/Data/Secs2.t^
EXE_FILES:  ^

CHANGES:

Changes to past revisions are as follows: 

\=over 4

\=item Data-Strify-0.01

Originated

\=item Data-Secs2-0.01

Abandoned Data::Dumper in favor of SEMI E35,
SECS-II standard for stringifying Perl data.

\=item Data-Secs2-0.02

Added arrayification of REF and GLOB references.
Thus, the 'Data::Secs2' module will nest into
REF and GLOB references.

\=item Data-Secs2-0.03

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Data, the same directory as the test script
and deleting the test library File::TestPath program module.

\=item Data-Secs2-0.04

Greater expanded the subroutines to the following: arrayify, itemify, 
listify, neuterify, scalarize, secsify, stringify, transify, vectorize.
Added descriptions and tests for the new functions.

\=item Data-Secs2-0.05

Change Perlify to allow translation packed multi-cell number item elements
as number arrays. Single cell number item elements are still translated
as a number scalar. This situation exists because SEMI E5 treats a
single text character and a single number as a cell, while Perl treats
multiple characters and a single number as a scalar. Granted
there is the Perl function C<vec> that allows some manipulation
of multicell data. But it is stretch to say that because of the 
C<vec> function that multicell integers are an underlying Perl data
type.

Added C<new> and C<config> subroutine to supply the default, (startup)
options for each subroutine in the C<Data::Secs2> program module.
The default options may be overriden with a subroutine input for
most subroutines.

The Perl undef was not finding a home in the SECS2 Object. Found a home
as a SEMI E5-94 empty list L[0].

Added support for the C<CODE> underlying Perl data type.

\=item Data-Secs2-0.06

Changed the definition of a C<SECS Object>, eliminating the option of have
numbers packed or unpacked to unpack only. Replaced the slot for packed
with a new encoding of a 'Numeric Scalar'. 
Perl does not  support 'Test Scalars' while the SEMI E5-94 standard does not 
support neither scalars. Other languages, such as APL, support nested array,
'Text Scalars' and 'Numeric Scalars'.

BEFORE: (Data-Secs2-0.05)

 U1
 [1 2 3] # unpacked

 U1
 $*%  # packed


AFTER: (Data-Secs2-0.06)

 U1
 [1 2 3]  # numeric array

 U1
 1  # numeric scalar

 A
 'hello'  # text array

 A
 'h' # text scalar

Note that altough text scalars are possible and exist in other
languages, the C<Data::Secs2> program module
does not provide support for them.
In Perl what other languages consider text arrays are text scalars.
Since underlying Perl language does not
support them, they are not part of common Perl practices, and
turning Perl text arrays into text scalars and introducing
text arrays require extensive gyrations to Perl.

Added a new format type to C<SECS Object> with unspecified
bytes per cell, format 'N', where the 'N' stands for number.
Eliminated the C<textify> and C<numerify> subroutines that
packed and unpacked C<SECS Object> numeric data. It is always
unpacked for C<Data-Secs2>. Eliminated the C<perl_secs_numbers>
for the C<listify> subroutine. Since have a crystal clear encoding
of scalar numberics and scalar arrays (lists), Perl numeric arrays will
always be encoded as 'multicell' when going form Perl nested lists to
C<SECS Object>.

Changed the output of the C<perlify> subroutine from a list of
variables to a reference to a list of variables and introduced
a scalar as an error message. This allows another way to
output error messages beside optional C<warns> and C<dies>.

\=item Data-Secs2-0.07

The C<secs_elementify> subroutine did not handle a numeric zero properly.
Added test for numeric zero and undef.

\=item Data-Secs2-0.08

Documentation woes.
The SEMI link does not work on. Changed to SEMI, http://www.semi.org.
The new SVD =head1 NAME is masking out the code program module.
Changed the SVD =head1 NAME so not same as code program module =head1 NAME

\=item Data-Secs2-0.09

Change C<use Data::SecsPack> to C<require Data::SecsPack> so that it is not loaded
unless using C<Data::Secs2> to pack and unpack SEMI E5 numbers.

Move C<str2float> and C<str2int> from C<Data::SecsPack> to C<Data::Str2Num> so
that the C<Data::Secs2> package and other packages may load them without loading
the subroutines to pack and unpack numbers in the C<Data::SecsPack> subroutine.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES:
The 'Data::Strify' module provides a canoncial string for data
no matter how many nests of arrays and hashes it contains.
^

PROBLEMS:
None.
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

Commercial installation of the binary or source
must visually present to the installer 
the above copyright notice,
this list of conditions intact,
that the original source is available
at http://softwarediamonds.com
and provide means
for the installer to actively accept
the list of conditions; 
otherwise, a license fee must be paid to
Softwareware Diamonds.


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

SUPPORT: 603 882-0846 E<lt> support@SoftwareDiamonds.com E<gt>^


NOTES:
The following are useful acronyms:

\=over 4

\=item .d

extension for a Perl demo script file

\=item .pm

extension for a Perl Library Module

\=item .t

extension for a Perl test script file

\=item POD

Plain Old Documentation

\=back
^

SEE_ALSO: 
\=over 4

\=item L<Data::Secs2|Data::Secs2> 

\=item L<Data::SecsPack|Data::SecsPack> 

\=item L<Data::Startup|Data::Startup> 

\=item L<Docs::US_DOD::SVD|Docs::US_DOD::SVD> 

\=item L<Docs::US_DOD::STD|Docs::US_DOD::STD> 

\=back
^


HTML: 
<p><br>
^
~-~
























