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
$VERSION = '0.02';
$DATE = '2003/08/04';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Data_Str2Num.pm' => [qw(0.02 2003/07/21), 'revised 0.01'],
    'MANIFEST' => [qw(0.02 2003/07/21), 'generated, replaces 0.01'],
    'Makefile.PL' => [qw(0.02 2003/07/21), 'generated, replaces 0.01'],
    'README' => [qw(0.02 2003/07/21), 'generated, replaces 0.01'],
    'lib/Data/Str2Num.pm' => [qw(0.02 2003/07/21), 'revised 0.01'],
    't/Data/Str2Num.d' => [qw(0.01 2003/07/20), 'unchanged'],
    't/Data/Str2Num.pm' => [qw(0.01 2003/07/20), 'unchanged'],
    't/Data/Str2Num.t' => [qw(0.01 2003/07/20), 'unchanged'],

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



=head1 Title Page

 Software Version Description

 for

 Data::Str2Num - convert a scalar string to an integer

 Revision: A

 Version: 0.02

 Date: 2003/07/21

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

The "Data::Str2int" module translates an scalar string to a scalar integer.
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

This document releases Data::Str2Num version 0.02
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file found
at the following repository(s):

   http://www.softwarediamonds/packages/Data-Str2Num-0.02
   http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/Data-Str2Num-0.02


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
 lib/Docs/Site_SVD/Data_Str2Num.pm                            0.02    2003/07/21 revised 0.01
 MANIFEST                                                     0.02    2003/07/21 generated, replaces 0.01
 Makefile.PL                                                  0.02    2003/07/21 generated, replaces 0.01
 README                                                       0.02    2003/07/21 generated, replaces 0.01
 lib/Data/Str2Num.pm                                          0.02    2003/07/21 revised 0.01
 t/Data/Str2Num.d                                             0.01    2003/07/20 unchanged
 t/Data/Str2Num.pm                                            0.01    2003/07/20 unchanged
 t/Data/Str2Num.t                                             0.01    2003/07/20 unchanged


=head2 3.3 Changes

Changes are as follows:

=over 4

=item Data::Str2Num 0.01

Originated

=item Data::Str2Num 0.02

Added 1 to end of the code section. 
Unix Perls very strict about this one.

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

To installed the release file, use the CPAN module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

The distribution file is at the following respositories:

   http://www.softwarediamonds/packages/Data-Str2Num-0.02
   http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/Data-Str2Num-0.02


=item Prerequistes.

 'File::TestPath' => '1.1',
 'File::SmartNL' => '1.1',
 'File::Package' => '1.1',
 'Test::Tech' => '1.08',


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

L<Data::Str2Num|Data::Str2Num>

=for html
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

1;

__DATA__

DISTNAME: Data-Str2Num^
REPOSITORY_DIR: packages^

VERSION : 0.02^
FREEZE: 1^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.01^
REVISION: A^


AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: convert a scalar string to an integer^
TITLE   : Data::Str2Num - convert a scalar string to an integer^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
CLASSIFICATION: NONE^
TEMPLATE:  ^
CSS: help.css^
SVD_FSPEC: Unix^

REPOSITORY: 
  http://www.softwarediamonds/packages/
  http://www.perl.com/CPAN-local/authors/id/S/SO/SOFTDIA/
^

COMPRESS: gzip^
COMPRESS_SUFFIX: gz^

RESTRUCTURE:  ^

CHANGE2CURRENT:  ^

AUTO_REVISE: 
lib/Data/Str2Num.pm
t/Data/Str2Num.*
^

PREREQ_PM:
'File::TestPath' => '1.1',
'File::SmartNL' => '1.1',
'File::Package' => '1.1',
'Test::Tech' => '1.08',
^

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

The "Data::Str2int" module translates an scalar string to a scalar integer.
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
To installed the release file, use the CPAN module in the Perl release
or the INSTALL.PL script at the following web site:

 http://packages.SoftwareDiamonds.com

Follow the instructions for the the chosen installation software.

The distribution file is at the following respositories:

${REPOSITORY}
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

L<Data::Str2Num|Data::Str2Num>

^

HTML:
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^
~-~


