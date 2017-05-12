#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Data::Str2Num;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.04';
$DATE = '2004/05/19';
$FILE = __FILE__;

########
# The Test::STDmaker module uses the data after the __DATA__ 
# token to automatically generate the this file.
#
# Don't edit anything before __DATA_. Edit instead
# the data after the __DATA__ token.
#
# ANY CHANGES MADE BEFORE the  __DATA__ token WILL BE LOST
#
# the next time Test::STDmaker generates this file.
#
#


=head1 NAME

 - Software Test Description for Data::Str2Num

=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Data::Str2Num Program Module

 Revision: -

 Version: 

 Date: 2004/05/19

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

#######
#  
#  1. SCOPE
#
#
=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Data::Str2Num|Data::Str2Num>
The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.

#######
#  
#  3. TEST PREPARATIONS
#
#
=head1 TEST PREPARATIONS

Test preparations are establishes by the L<General STD|Test::STD::PerlSTD>.


#######
#  
#  4. TEST DESCRIPTIONS
#
#
=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD PM Form Database Test Description Fields|Test::STDmaker/STD PM Form Database Test Description Fields>.

=head2 Test Plan

 T: 13^

=head2 ok: 1


  C:
     use File::Package;
     my $fp = 'File::Package';
     my $uut = 'Data::Str2Num';
     my $loaded;
     my ($result,@result); # force a context
 ^
  N: Load UUT^
  R: L<DataPort::DataFile/general [1] - load>^
  S: $loaded^
  C: my $errors = $fp->load_package($uut, 'str2float','str2int','str2integer',)^
  A: $errors^
 SE: ''^
 ok: 1^

=head2 ok: 2

  N: str2int(\'033\')^
  A: $uut->str2int('033')^
  E: 27^
 ok: 2^

=head2 ok: 3

  N: str2int(\'0xFF\')^
  A: $uut->str2int('0xFF')^
  E: 255^
 ok: 3^

=head2 ok: 4

  N: str2int(\'0b1010\')^
  A: $uut->str2int('0b1010')^
  E: 10^
 ok: 4^

=head2 ok: 5

  N: str2int(\'255\')^
  A: $uut->str2int('255')^
  E: 255^
 ok: 5^

=head2 ok: 6

  N: str2int(\'hello\')^
  A: $uut->str2int('hello')^
  E: undef^
 ok: 6^

=head2 ok: 7

  N: str2integer(1E20)^
  A: $result = $uut->str2integer(1E20)^
  E: undef^
 ok: 7^

=head2 ok: 8

  N: str2integer(' 78 45 25', ' 512E4 1024 hello world') \@numbers^
  C: my ($strings, @numbers) = str2integer(' 78 45 25', ' 512E4 1024 hello world')^
  A: [@numbers]^
  E: [78,45,25,]^
 ok: 8^

=head2 ok: 9

  N: str2integer(' 78 45 25', ' 512E4 1024 hello world') \@strings^
  A: join( ' ', @$strings)^
  E: '512E4 1024 hello world'^
 ok: 9^

=head2 ok: 10

  N: str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') numbers^
  C: ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025  0', ' 512E4 hello world')^
  A: [@numbers]^
  E: [[78,1], [-24,-6], [25,-3], [0, -1], [512,6]]^
 ok: 10^

=head2 ok: 11

  N: str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') \@strings^
  A: join( ' ', @$strings)^
  E: 'hello world'^
 ok: 11^

=head2 ok: 12

  N: str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) numbers^
  C: ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1})^
  A: [@numbers]^
  E: ['78','-2.4E-6','0.0025','255','63','0','512E4']^
 ok: 12^

=head2 ok: 13

  N: str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) \@strings^
  A: join( ' ', @$strings)^
  E: 'hello world'^
 ok: 13^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<DataPort::DataFile/general [1] - load>                         L<t::Data::Str2Num/ok: 1>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::Data::Str2Num/ok: 1>                                        L<DataPort::DataFile/general [1] - load>


=cut

#######
#  
#  6. NOTES
#
#

=head1 NOTES

copyright © 2003 Software Diamonds.

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

#######
#
#  2. REFERENCED DOCUMENTS
#
#
#

=head1 SEE ALSO

L<Data::Str2Num>

=back

=for html


=cut

__DATA__

Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Classification: None^
Detail_Template: ^
End_User: General Public^
File_Spec: Unix^
Name: ^
Revision: -^
STD2167_Template: ^
Temp: temp.pl^
UUT: Data::Str2Num^
Version: ^
Demo: Str2Num.d^
Verify: Str2Num.t^


 T: 13^


 C:
    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Data::Str2Num';
    my $loaded;
    my ($result,@result); # force a context
^

 N: Load UUT^
 R: L<DataPort::DataFile/general [1] - load>^
 S: $loaded^
 C: my $errors = $fp->load_package($uut, 'str2float','str2int','str2integer',)^
 A: $errors^
SE: ''^
ok: 1^

 N: str2int(\'033\')^
 A: $uut->str2int('033')^
 E: 27^
ok: 2^

 N: str2int(\'0xFF\')^
 A: $uut->str2int('0xFF')^
 E: 255^
ok: 3^

 N: str2int(\'0b1010\')^
 A: $uut->str2int('0b1010')^
 E: 10^
ok: 4^

 N: str2int(\'255\')^
 A: $uut->str2int('255')^
 E: 255^
ok: 5^

 N: str2int(\'hello\')^
 A: $uut->str2int('hello')^
 E: undef^
ok: 6^

 N: str2integer(1E20)^
 A: $result = $uut->str2integer(1E20)^
 E: undef^
ok: 7^

 N: str2integer(' 78 45 25', ' 512E4 1024 hello world') \@numbers^
 C: my ($strings, @numbers) = str2integer(' 78 45 25', ' 512E4 1024 hello world')^
 A: [@numbers]^
 E: [78,45,25,]^
ok: 8^

 N: str2integer(' 78 45 25', ' 512E4 1024 hello world') \@strings^
 A: join( ' ', @$strings)^
 E: '512E4 1024 hello world'^
ok: 9^

 N: str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') numbers^
 C: ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025  0', ' 512E4 hello world')^
 A: [@numbers]^
 E: [[78,1], [-24,-6], [25,-3], [0, -1], [512,6]]^
ok: 10^

 N: str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') \@strings^
 A: join( ' ', @$strings)^
 E: 'hello world'^
ok: 11^

 N: str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) numbers^
 C: ($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1})^
 A: [@numbers]^
 E: ['78','-2.4E-6','0.0025','255','63','0','512E4']^
ok: 12^

 N: str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) \@strings^
 A: join( ' ', @$strings)^
 E: 'hello world'^
ok: 13^


See_Also: L<Data::Str2Num>^

Copyright:
copyright © 2003 Software Diamonds.

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

HTML: ^


~-~
