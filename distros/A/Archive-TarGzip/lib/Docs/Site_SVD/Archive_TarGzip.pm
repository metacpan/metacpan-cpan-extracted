#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  Docs::Site_SVD::Archive_TarGzip;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.03';
$DATE = '2004/05/14';
$FILE = __FILE__;

use vars qw(%INVENTORY);
%INVENTORY = (
    'lib/Docs/Site_SVD/Archive_TarGzip.pm' => [qw(0.03 2004/05/14), 'revised 0.02'],
    'MANIFEST' => [qw(0.03 2004/05/14), 'generated, replaces 0.02'],
    'Makefile.PL' => [qw(0.03 2004/05/14), 'generated, replaces 0.02'],
    'README' => [qw(0.03 2004/05/14), 'generated, replaces 0.02'],
    'lib/Archive/TarGzip.pm' => [qw(0.03 2004/05/14), 'revised 0.02'],
    't/Archive/TarGzip.d' => [qw(0.03 2004/05/14), 'revised 0.02'],
    't/Archive/TarGzip.pm' => [qw(0.01 2003/09/12), 'unchanged'],
    't/Archive/TarGzip.t' => [qw(0.03 2004/05/14), 'revised 0.02'],
    't/Archive/File/SmartNL.pm' => [qw(1.16 2004/05/14), 'new'],
    't/Archive/File/Package.pm' => [qw(1.17 2004/05/14), 'new'],
    't/Archive/Test/Tech.pm' => [qw(1.25 2004/05/14), 'new'],
    't/Archive/Data/Secs2.pm' => [qw(1.23 2004/05/14), 'new'],
    't/Archive/Data/SecsPack.pm' => [qw(0.08 2004/05/14), 'new'],
    't/Archive/Data/Startup.pm' => [qw(0.06 2004/05/14), 'new'],
    't/Archive/TarGzip/expected/Makefile.PL' => [qw(0.01 2003/08/04), 'unchanged'],
    't/Archive/TarGzip/expected/MANIFEST' => [qw(0.01 2003/08/04), 'unchanged'],
    't/Archive/TarGzip/expected/README' => [qw(0.01 2003/08/04), 'unchanged'],
    't/Archive/TarGzip/expected/lib/Data/Str2Num.pm' => [qw(0.01 2003/08/04), 'unchanged'],
    't/Archive/TarGzip/expected/lib/Docs/Site_SVD/Data_Str2Num.pm' => [qw(0.01 2003/08/04), 'unchanged'],
    't/Archive/TarGzip/expected/t/Data/Str2Num.d' => [qw(0.01 2003/08/04), 'unchanged'],
    't/Archive/TarGzip/expected/t/Data/Str2Num.pm' => [qw(0.01 2003/08/04), 'unchanged'],
    't/Archive/TarGzip/expected/t/Data/Str2Num.t' => [qw(0.01 2003/08/04), 'unchanged'],

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

Docs::Site_SVD::Archive_TarGzip - tar and gzip or untar and gunzip with a small memory footprint

=head1 Title Page

 Software Version Description

 for

 Docs::Site_SVD::Archive_TarGzip - tar and gzip or untar and gunzip with a small memory footprint

 Revision: B

 Version: 0.03

 Date: 2004/05/14

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

The Archive::TarGzip module provides tar subroutine to archive a list of files
in an archive file in the tar format. 
The archve file may be optionally compressed using the gzip compression routines.
The ARchive::TarGzip module also provides a untar subroutine that can extract
the files from the tar or tar/gzip archive files.

The tar and untar top level subroutines use methods from the Archive::TarGzip
class. The Archive::TarGzip class is dervided from its parent Archive::Tar class.
The new methods supplied with the Archive::TarGzip derived class provide means
to access individual files within the archive file without bringing the entire
archive file into memory. When the gzip compression option is active, the
compression is performed on the fly without creating an intermediate uncompressed
tar file. The new methods provide a smaller memory footprint that enhances performance
for very large archive files.

=head2 1.3 Document overview.

This document releases Archive::TarGzip version 0.03
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.

=head1 3.0 VERSION DESCRIPTION

All file specifications in this SVD
use the Unix operating
system file specification.

=head2 3.1 Inventory of materials released.

This document releases the file 

 Archive-TarGzip-0.03.tar.gz

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
 lib/Docs/Site_SVD/Archive_TarGzip.pm                         0.03    2004/05/14 revised 0.02
 MANIFEST                                                     0.03    2004/05/14 generated, replaces 0.02
 Makefile.PL                                                  0.03    2004/05/14 generated, replaces 0.02
 README                                                       0.03    2004/05/14 generated, replaces 0.02
 lib/Archive/TarGzip.pm                                       0.03    2004/05/14 revised 0.02
 t/Archive/TarGzip.d                                          0.03    2004/05/14 revised 0.02
 t/Archive/TarGzip.pm                                         0.01    2003/09/12 unchanged
 t/Archive/TarGzip.t                                          0.03    2004/05/14 revised 0.02
 t/Archive/File/SmartNL.pm                                    1.16    2004/05/14 new
 t/Archive/File/Package.pm                                    1.17    2004/05/14 new
 t/Archive/Test/Tech.pm                                       1.25    2004/05/14 new
 t/Archive/Data/Secs2.pm                                      1.23    2004/05/14 new
 t/Archive/Data/SecsPack.pm                                   0.08    2004/05/14 new
 t/Archive/Data/Startup.pm                                    0.06    2004/05/14 new
 t/Archive/TarGzip/expected/Makefile.PL                       0.01    2003/08/04 unchanged
 t/Archive/TarGzip/expected/MANIFEST                          0.01    2003/08/04 unchanged
 t/Archive/TarGzip/expected/README                            0.01    2003/08/04 unchanged
 t/Archive/TarGzip/expected/lib/Data/Str2Num.pm               0.01    2003/08/04 unchanged
 t/Archive/TarGzip/expected/lib/Docs/Site_SVD/Data_Str2Num.pm 0.01    2003/08/04 unchanged
 t/Archive/TarGzip/expected/t/Data/Str2Num.d                  0.01    2003/08/04 unchanged
 t/Archive/TarGzip/expected/t/Data/Str2Num.pm                 0.01    2003/08/04 unchanged
 t/Archive/TarGzip/expected/t/Data/Str2Num.t                  0.01    2003/08/04 unchanged


=head2 3.3 Changes

Changes are as follows

=over 4

=item Archive::TarGzip-0.01

Originated

=item Archive::TarGzip-0.02

Outsource the gzip compression to Tie::Gzip.

Change the mode on tar directories from 666 to 777.

=item Archive::TarGzip-0.03

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Archive, the same directory as the test script
and deleting the test library File::TestPath program module.

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

Right click on 'Archive-TarGzip-0.03.tar.gz' and download to a temporary
installation directory.
Enter the following where $make is 'nmake' for microsoft
windows; otherwise 'make'.

 gunzip Archive-TarGzip-0.03.tar.gz
 tar -xf Archive-TarGzip-0.03.tar
 perl Makefile.PL
 $make test
 $make install

On Microsoft operating system, nmake, tar, and gunzip 
must be in the exeuction path. If tar and gunzip are
not install, download and install unxutils from

 http://packages.softwarediamonds.com

=item Prerequistes.

 'Tie::Gzip' => '0.01',
 'File::AnySpec' => '1.11',
 'Data::Startup' => '0.02',
 'File::Package' => '0.00',
 'File::Where' => '0.00',


=item Security, privacy, or safety precautions.

None.

=item Installation Tests.

Most Perl installation software will run the following test script(s)
as part of the installation:

 t/Archive/TarGzip.t

=item Installation support.

If there are installation problems or questions with the installation
contact

 603 882-0846 E<lt>support@SoftwareDiamonds.comE<gt>

=back

=head2 3.7 Possible problems and known errors

There are no known open issues.

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

DISTNAME: Archive-TarGzip^
VERSION : 0.03^
FREEZE: 0^
PREVIOUS_DISTNAME:  ^
PREVIOUS_RELEASE: 0.02^
REVISION: B^

AUTHOR  : SoftwareDiamonds.com E<lt>support@SoftwareDiamonds.comE<gt>^
ABSTRACT: tar and gzip or untar and gunzip with a small memory footprint^
TITLE   : Docs::Site_SVD::Archive_TarGzip - tar and gzip or untar and gunzip with a small memory footprint^
END_USER: General Public^
COPYRIGHT: copyright © 2003 Software Diamonds^
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
lib/Archive/TarGzip.pm
t/Archive/TarGzip.*
lib/File/SmartNL.pm => t/Archive/File/SmartNL.pm
lib/File/Package.pm => t/Archive/File/Package.pm
lib/Test/Tech.pm => t/Archive/Test/Tech.pm
lib/Data/Secs2.pm => t/Archive/Data/Secs2.pm
lib/Data/SecsPack.pm => t/Archive/Data/SecsPack.pm
lib/Data/Startup.pm => t/Archive/Data/Startup.pm
^

REPLACE: 
t/Archive/TarGzip/expected/*
t/Archive/TarGzip/expected/lib/Data/*
t/Archive/TarGzip/expected/lib/Docs/Site_SVD/*
t/Archive/TarGzip/expected/t/Data/*
^

PREREQ_PM:
'Tie::Gzip' => '0.01',
'File::AnySpec' => '1.11',
'Data::Startup' => '0.02',
'File::Package' => '0.00',
'File::Where' => '0.00',
^

README_PODS: lib/Archive/TarGzip.pm^
TESTS: t/Archive/TarGzip.t^
EXE_FILES:  ^

CHANGES: 
Changes are as follows

\=over 4

\=item Archive::TarGzip-0.01

Originated

\=item Archive::TarGzip-0.02

Outsource the gzip compression to Tie::Gzip.

Change the mode on tar directories from 666 to 777.

\=item Archive::TarGzip-0.03

The lastest build of Test::STDmaker expects the test library in the same
directory as the test script.
Coordiated with the lastest Test::STDmaker by moving the
test library from tlib to t/Archive, the same directory as the test script
and deleting the test library File::TestPath program module.

\=back

^

DOCUMENT_OVERVIEW:
This document releases ${NAME} version ${VERSION}
providing a description of the inventory, installation
instructions and other information necessary to
utilize and track this release.
^

CAPABILITIES: 

The Archive::TarGzip module provides tar subroutine to archive a list of files
in an archive file in the tar format. 
The archve file may be optionally compressed using the gzip compression routines.
The ARchive::TarGzip module also provides a untar subroutine that can extract
the files from the tar or tar/gzip archive files.

The tar and untar top level subroutines use methods from the Archive::TarGzip
class. The Archive::TarGzip class is dervided from its parent Archive::Tar class.
The new methods supplied with the Archive::TarGzip derived class provide means
to access individual files within the archive file without bringing the entire
archive file into memory. When the gzip compression option is active, the
compression is performed on the fly without creating an intermediate uncompressed
tar file. The new methods provide a smaller memory footprint that enhances performance
for very large archive files.
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








