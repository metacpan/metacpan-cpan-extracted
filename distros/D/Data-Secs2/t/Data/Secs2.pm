#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Data::Secs2;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.06';
$DATE = '2004/05/11';
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


=head1 TITLE PAGE

 Detailed Software Test Description (STD)

 for

 Perl Data::Secs2 Program Module

 Revision: -

 Version: 

 Date: 2004/05/11

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Data::Secs2|Data::Secs2>

The format of this STD is a tailored L<2167A STD DID|Docs::US_DOD::STD>.
in accordance with 
L<Detail STD Format|Test::STDmaker/Detail STD Format>.

#######
#  
#  4. TEST DESCRIPTIONS
#
#  4.1 Test 001
#
#  ..
#
#  4.x Test x
#
#

=head1 TEST DESCRIPTIONS

The test descriptions uses a legend to
identify different aspects of a test description
in accordance with
L<STD FormDB Test Description Fields|Test::STDmaker/STD FormDB Test Description Fields>.

=head2 Test Plan

 T: 34^

=head2 ok: 1


  C:
     use File::Package;
     my $fp = 'File::Package';
     use Data::Secs2 qw(arrayify config listify neuterify numberify perlify 
          perl_typify secsify secs_elementify stringify textify transify);
     my $uut = 'Data::Secs2';
     my ($loaded, $event, $big_secs2);
 my $test_data1 =
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   N 2
   A[5] hello
   N 4
 ';
 my $test_data2 =
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[4] body
   A[5] hello
   A[6] header
   A[9] To: world
 ';
 my $test_data3 =
 'U1[1] 80
 N 2
 L[4]
   A[0]
   A[5] ARRAY
   A[5] hello
   A[5] world
 N 512
 ';
 my $test_data4 =
 'U1[1] 80
 N 2
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 ';
 my $test_data5 =
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[3]
     A[0]
     A[5] Index
     N 10
   A[3] msg
   L[3]
     A[0]
     A[5] ARRAY
     A[4] body
 ';
 my $test_data6 = [ [78,45,25], [512,1024], 100000 ];
 my $test_data7 = 'a50150010541004105' . unpack('H*','ARRAY') . 
                  'a5034e2d19' .  'a90402000400' . 'b104000186a0';
 my $test_data17 = 'a50150010541004105' . unpack('H*','ARRAY') . 
                  'a5034e2d19' .  'a90402000400' . 'b0000186a0';
 ^

 QC:
 #######
 # multicell numberics, Perl Secs Object
 #
 my $test_data8 =
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   U1[3] 78 45 25
   U2[2] 512 1024
   U4[1] 100000
 ';

 #######
 # Strict Perl numberics, Perl Secs Object
 #
 my $test_data9 =
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   N[3] 78 45 25
   N[2] 512 1024
   N 100000
 ';
 my $test_data10 =
 'U1[1] 80
 L[3]
   A[0]
   A[5] ARRAY
   L[5]
     A[0]
     A[5] ARRAY
     N 2
     A[5] hello
     N 4
 ';
 my $test_data11 =
 'U1[1] 80
 L[3]
   A[0]
   A[5] ARRAY
   L[6]
     A[0]
     A[4] HASH
     A[4] body
     A[5] hello
     A[6] header
     A[9] To: world
 ';
 my $test_data12 =
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   N 2
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
   N 512
 ';
 my $test_data13 =
 'U1[1] 80
 L[4]
   A[0]
   A[5] ARRAY
   N 2
   L[6]
     A[0]
     A[4] HASH
     A[6] header
     L[6]
       A[11] Class::None
       A[4] HASH
       A[4] From
       A[6] nobody
       A[2] To
       A[6] nobody
     A[3] msg
     L[4]
       A[0]
       A[5] ARRAY
       A[5] hello
       A[5] world
 ';
 my $test_data14 =
 'U1[1] 80
 L[4]
   A[0]
   A[5] ARRAY
   L[6]
     A[0]
     A[4] HASH
     A[6] header
     L[6]
       A[11] Class::None
       A[4] HASH
       A[4] From
       A[6] nobody
       A[2] To
       A[6] nobody
     A[3] msg
     L[4]
       A[0]
       A[5] ARRAY
       A[5] hello
       A[5] world
   L[6]
     A[0]
     A[4] HASH
     A[6] header
     L[3]
       A[0]
       A[5] Index
       N 16
     A[3] msg
     L[3]
       A[0]
       A[5] ARRAY
       A[4] body
 ';
 my $test_data15 =
 'U1[1] 80
 U1[1] 2
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 ';
 my $test_data16 =
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[6]
     A[11] Class::None
     A[4] HASH
     A[4] From
     A[6] nobody
     A[2] To
     A[6] nobody
   A[3] msg
   L[4]
     A[0]
     A[5] ARRAY
     A[5] hello
     A[5] world
 L[6]
   A[0]
   A[4] HASH
   A[6] header
   L[3]
     A[0]
     A[5] Index
     U1 10
   A[3] msg
   L[3]
     A[0]
     A[5] ARRAY
     A[4] body
 ';

 #######
 # multicell numberics, Perl Secs Object
 #
 my $test_data18 =
 'U1[1] 80
 L[5]
   A[0]
   A[5] ARRAY
   U1[3] 78 45 25
   U2[2] 512 1024
   U4 100000
 ';
 my $test_data19 =
 'U1[1] 80
 L[7]
   A[0]
   A[5] ARRAY
   N 2
   A[5] hello
   N 4
   N 0
   L[0]
 ';
 ^
 VO: ^
  N: UUT loaded as Part of Test::Tech^
  A: $loaded = $fp->is_package_loaded($uut)^
 SE:  '1'^
 ok: 1^

=head2 ok: 2

 VO: ^
  N: stringify a scalar string^
  C: $uut->import( 'stringify' )^
  A: stringify( 'string' )^
  E: 'string'^
 ok: 2^

=head2 ok: 3

 VO: ^
  N: stringify a scalar number^
  A: stringify( 2 )^
  E: 2^
 ok: 3^

=head2 ok: 4

  N: stringify an array^
  A: stringify( '2', 'hello', 4 )^

  E:
 'U1[1] 80
 N 2
 A[5] hello
 N 4
 '
 ^
 ok: 4^

=head2 ok: 5

  N: stringify a hash reference^
  A: stringify( {header => 'To: world', body => 'hello'})^

  E:
 'U1[1] 80
 L[6]
   A[0]
   A[4] HASH
   A[4] body
   A[5] hello
   A[6] header
   A[9] To: world
 '
 ^
 ok: 5^

=head2 ok: 6

  N: ascii secsify lisfication of test_data1 an array reference^
  A: secsify( listify( ['2', 'hello', 4, 0, undef] ) )^
  E: $test_data19^
 ok: 6^

=head2 ok: 7

 VO: ^
  N: ascii secsify lisfication of test_data2 -  a hash reference^
  A: secsify( listify( {header => 'To: world', body => 'hello'}) )^
  E: $test_data2^
 ok: 7^

=head2 ok: 8

  N: ascii secsify lisfication of test_data3 - array with an array ref^
  A: secsify( listify( '2', ['hello', 'world'], 512 ) )^
  E: $test_data3^
 ok: 8^

=head2 ok: 9

  A: my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None'^
 VO: ^
  N: ascii secsify lisfication of test_data4 - array with nested hashes, arrays, objects^
  C: my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None'^
  A: secsify( listify( '2', { msg => ['hello', 'world'] , header => $obj } ) )^
  E: $test_data4^
 ok: 9^

=head2 ok: 10

  N: ascii secsify lisfication of test_data5 - hash with nested hashes, arrays, common objects^

  A:
     secsify( listify( {msg => ['hello', 'world'] , header => $obj }, 
      {msg => [ 'body' ], header => $obj} ) )
 ^
  E: $test_data5^
 ok: 10^

=head2 ok: 11

 VO: ^
  N: ascii secsify listifcation perilification transfication of test_data1^
  A: secsify( listify( perlify( transify($test_data1) ) ) )^
  E: $test_data10^
 ok: 11^

=head2 ok: 12

 VO: ^
  N: ascii secsify listifcation perilification transfication of test_data2^
  A: secsify( listify(perlify( transify($test_data2 ) ) ) )^
  E: $test_data11^
 ok: 12^

=head2 ok: 13

 VO: ^
  N: ascii secsify listifcation perilification transfication of test_data3^
  A: secsify( listify(perlify( transify($test_data3 )) ) )^
  E: $test_data12^
 ok: 13^

=head2 ok: 14

  N: ascii secsify listifcation perilification transfication of test_data4^
  A: secsify( listify(perlify( transify($test_data4 ))) )^
  E: $test_data13^
 ok: 14^

=head2 ok: 15

  N: ascii secsify listifcation perilification transfication of test_data5^
  A: secsify( listify(perlify( transify($test_data5))) )^
  E: $test_data14^
 ok: 15^

=head2 ok: 16

  N: binary secsify an array reference^
  A: unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary'}))^
  E: 'a50150010541004105' . unpack('H*','ARRAY') . 'a501024105' . unpack('H*','hello') . 'a50104'^
 ok: 16^

=head2 ok: 17

  N: binary secsify numeric arrays^
  A: unpack('H*',secsify( listify( $test_data6 ), [type => 'binary']))^
  E: $test_data7^
 ok: 17^

=head2 ok: 18

  N: scalar binary secsify an array reference^
  A: unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary', scalar => 1}))^
  E: 'a50150010541004105' . unpack('H*','ARRAY') . 'a4024105' . unpack('H*','hello') . 'a404'^
 ok: 18^

=head2 ok: 19

  N: scalar binary secsify numeric arrays^
  A: unpack('H*',secsify( listify( $test_data6 ), type => 'binary', scalar => 1))^
  E: $test_data17^
 ok: 19^

=head2 ok: 20

  N: binary secsify array with nested hashes, arrays, objects^

  C:
 $big_secs2 = 
 'a501' . '50' .                       # U1[1] 80  Perl format code 
 'a501' . '02' .                       # U1[1] 2
 '0106' .                              # L[6]
 '4100' .                              #   A[0]
 '4104' . unpack('H*','HASH') .        #   A[4] HASH
 '4106' . unpack('H*','header') .      #   A[6] header
 '0106' .                              #   L[6]
 '410b' . unpack('H*','Class::None') . #     A[11] Class::None
 '4104' . unpack('H*','HASH') .        #     A[4] HASH
 '4104' . unpack('H*','From') .        #     A[4] From
 '4106' . unpack('H*','nobody') .      #     A[6] nobody
 '4102' . unpack('H*','To') .          #     A[2] To
 '4106' . unpack('H*','nobody') .      #     A[6] nobody
 '4103' . unpack('H*','msg') .         #   A[3] msg
 '0104' .                              #   L[4]
 '4100' .                              #     A[0]
 '4105' . unpack('H*','ARRAY') .       #     A[5] ARRAY
 '4105' . unpack('H*','hello') .       #     A[5] hello 
 '4105' . unpack('H*','world');        #     A[5] world
 ^
 VO: ^

  A:
 unpack('H*',
         secsify( listify( '2', { msg => ['hello', 'world'] , header => $obj } ), 
                  {type => 'binary'})
    )
 ^
  E: $big_secs2^
 ok: 20^

=head2 ok: 21

  N: neuterify a big secsii^
  A: secsify(neuterify (pack('H*',$big_secs2)))^
  E: $test_data15^
 ok: 21^

=head2 ok: 22

  N: neuterify binary secsii^
  A: secsify(neuterify (pack('H*',$test_data7)))^
  E: $test_data8^
 ok: 22^

=head2 ok: 23

  N: neuterify scalar binary secsii, length size error^

  C:
    $event = neuterify (pack('H*',$test_data17));
    $event =~ s/\n\t.*?$//;
    while(chomp($event)) { };
 ^
  A: $event^
  E: 'Format byte length size field is zero.'^
 ok: 23^

=head2 ok: 24

  N: neuterify scalar binary secsii, no error^
  C: $event = neuterify (pack('H*',$test_data17), scalar => 1)^
  A: ref($event)^
  E: 'ARRAY'^
 ok: 24^

=head2 ok: 25

  N: neuterify scalar binary secsii^
  A: secsify($event)^
  E: $test_data18^
 ok: 25^

=head2 ok: 26

  N: transify a free for all secsii input^

  C:
     my $ascii_secsii =
 '
 L
 (
   A \'\' A \'HASH\' A \'header\'
   L [ A "Class::None"  A "HASH" 
       A  "From" A "nobody"
       A  "To" A "nobody"
     ]
   A "msg"
   L,4 A[0] A[5] ARRAY
     A  "hello" A "world"
 )
 L 
 (
   A[0] A "HASH"  A /header/
   L[3] A[0] A \'Index\' U1 10
   A  \'msg\'
   L < A[0] A \'ARRAY\' A  \'body\' >
 )
 '
 ^
  C: my $list = transify ($ascii_secsii, obj_format_code => 'P');^
 DM: $list^
  A: ref($list)^
  E: 'ARRAY'^
 ok: 26^

=head2 ok: 27

  N: secsify transified free style secs text^
  A: ref($list) ? secsify( $list ) : ''^
  E: $test_data16^
 ok: 27^

=head2 ok: 28

  N: transify a bad free for all secsii input^

  C:
     $ascii_secsii =
 '
 L
 ( 
   A "msg"
   L,4 A[0] A[5] world
 '
 ^
  C: $list = transify ($ascii_secsii);^
  A: ref($list)^
  E: 'SCALAR'^
 ok: 28^

=head2 ok: 29

 DO: ^
  A: $list^
  N: Perl listify numeric arrays^
  A: ref(my $number_list = Data::Secs2->new(perl_secs_numbers => 'strict')->listify( $test_data6 ))^
  E: 'ARRAY'^
 ok: 29^

=head2 ok: 30

  N: secify Perl  listified numberic arrays^
  A: secsify($number_list)^
  E: $test_data9^
 ok: 30^

=head2 ok: 31

  N: read configuration^
  A: [config('type')]^
  E: ['type','ascii']^
 ok: 31^

=head2 ok: 32

  N: write configuration^
  A: [config('type','binary')]^
  E: ['type','ascii']^
 ok: 32^

=head2 ok: 33

  N: verify write configuration^
  A: [config('type')]^
  E: ['type','binary']^
 ok: 33^

=head2 ok: 34

  N: restore configuration^
  A: [config('type','ascii')]^
  E: ['type','binary']^
 ok: 34^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------


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
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>

=cut

__DATA__

File_Spec: Unix^
UUT: Data::Secs2^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: Secs2.d^
Verify: Secs2.t^


 T: 34^


 C:
    use File::Package;
    my $fp = 'File::Package';

    use Data::Secs2 qw(arrayify config listify neuterify numberify perlify 
         perl_typify secsify secs_elementify stringify textify transify);

    my $uut = 'Data::Secs2';
    my ($loaded, $event, $big_secs2);

my $test_data1 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  N 2
  A[5] hello
  N 4
';

my $test_data2 =
'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[4] body
  A[5] hello
  A[6] header
  A[9] To: world
';

my $test_data3 =
'U1[1] 80
N 2
L[4]
  A[0]
  A[5] ARRAY
  A[5] hello
  A[5] world
N 512
';

my $test_data4 =
'U1[1] 80
N 2
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
';

my $test_data5 =
'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[3]
    A[0]
    A[5] Index
    N 10
  A[3] msg
  L[3]
    A[0]
    A[5] ARRAY
    A[4] body
';

my $test_data6 = [ [78,45,25], [512,1024], 100000 ];

my $test_data7 = 'a50150010541004105' . unpack('H*','ARRAY') . 
                 'a5034e2d19' .  'a90402000400' . 'b104000186a0';

my $test_data17 = 'a50150010541004105' . unpack('H*','ARRAY') . 
                 'a5034e2d19' .  'a90402000400' . 'b0000186a0';
^


QC:
#######
# multicell numberics, Perl Secs Object
#
my $test_data8 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  U1[3] 78 45 25
  U2[2] 512 1024
  U4[1] 100000
';


#######
# Strict Perl numberics, Perl Secs Object
#
my $test_data9 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  N[3] 78 45 25
  N[2] 512 1024
  N 100000
';

my $test_data10 =
'U1[1] 80
L[3]
  A[0]
  A[5] ARRAY
  L[5]
    A[0]
    A[5] ARRAY
    N 2
    A[5] hello
    N 4
';

my $test_data11 =
'U1[1] 80
L[3]
  A[0]
  A[5] ARRAY
  L[6]
    A[0]
    A[4] HASH
    A[4] body
    A[5] hello
    A[6] header
    A[9] To: world
';

my $test_data12 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  N 2
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
  N 512
';

my $test_data13 =
'U1[1] 80
L[4]
  A[0]
  A[5] ARRAY
  N 2
  L[6]
    A[0]
    A[4] HASH
    A[6] header
    L[6]
      A[11] Class::None
      A[4] HASH
      A[4] From
      A[6] nobody
      A[2] To
      A[6] nobody
    A[3] msg
    L[4]
      A[0]
      A[5] ARRAY
      A[5] hello
      A[5] world
';

my $test_data14 =
'U1[1] 80
L[4]
  A[0]
  A[5] ARRAY
  L[6]
    A[0]
    A[4] HASH
    A[6] header
    L[6]
      A[11] Class::None
      A[4] HASH
      A[4] From
      A[6] nobody
      A[2] To
      A[6] nobody
    A[3] msg
    L[4]
      A[0]
      A[5] ARRAY
      A[5] hello
      A[5] world
  L[6]
    A[0]
    A[4] HASH
    A[6] header
    L[3]
      A[0]
      A[5] Index
      N 16
    A[3] msg
    L[3]
      A[0]
      A[5] ARRAY
      A[4] body
';

my $test_data15 =
'U1[1] 80
U1[1] 2
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
';

my $test_data16 =
'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[6]
    A[11] Class::None
    A[4] HASH
    A[4] From
    A[6] nobody
    A[2] To
    A[6] nobody
  A[3] msg
  L[4]
    A[0]
    A[5] ARRAY
    A[5] hello
    A[5] world
L[6]
  A[0]
  A[4] HASH
  A[6] header
  L[3]
    A[0]
    A[5] Index
    U1 10
  A[3] msg
  L[3]
    A[0]
    A[5] ARRAY
    A[4] body
';


#######
# multicell numberics, Perl Secs Object
#
my $test_data18 =
'U1[1] 80
L[5]
  A[0]
  A[5] ARRAY
  U1[3] 78 45 25
  U2[2] 512 1024
  U4 100000
';

my $test_data19 =
'U1[1] 80
L[7]
  A[0]
  A[5] ARRAY
  N 2
  A[5] hello
  N 4
  N 0
  L[0]
';
^

VO: ^
 N: UUT loaded as Part of Test::Tech^
 A: $loaded = $fp->is_package_loaded($uut)^
SE:  '1'^
ok: 1^

VO: ^
 N: stringify a scalar string^
 C: $uut->import( 'stringify' )^
 A: stringify( 'string' )^
 E: 'string'^
ok: 2^

VO: ^
 N: stringify a scalar number^
 A: stringify( 2 )^
 E: 2^
ok: 3^

 N: stringify an array^
 A: stringify( '2', 'hello', 4 )^

 E:
'U1[1] 80
N 2
A[5] hello
N 4
'
^

ok: 4^

 N: stringify a hash reference^
 A: stringify( {header => 'To: world', body => 'hello'})^

 E:
'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[4] body
  A[5] hello
  A[6] header
  A[9] To: world
'
^

ok: 5^

 N: ascii secsify lisfication of test_data1 an array reference^
 A: secsify( listify( ['2', 'hello', 4, 0, undef] ) )^
 E: $test_data19^
ok: 6^

VO: ^
 N: ascii secsify lisfication of test_data2 -  a hash reference^
 A: secsify( listify( {header => 'To: world', body => 'hello'}) )^
 E: $test_data2^
ok: 7^

 N: ascii secsify lisfication of test_data3 - array with an array ref^
 A: secsify( listify( '2', ['hello', 'world'], 512 ) )^
 E: $test_data3^
ok: 8^

 A: my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None'^
VO: ^
 N: ascii secsify lisfication of test_data4 - array with nested hashes, arrays, objects^
 C: my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None'^
 A: secsify( listify( '2', { msg => ['hello', 'world'] , header => $obj } ) )^
 E: $test_data4^
ok: 9^

 N: ascii secsify lisfication of test_data5 - hash with nested hashes, arrays, common objects^

 A:
    secsify( listify( {msg => ['hello', 'world'] , header => $obj }, 
     {msg => [ 'body' ], header => $obj} ) )
^

 E: $test_data5^
ok: 10^

VO: ^
 N: ascii secsify listifcation perilification transfication of test_data1^
 A: secsify( listify( perlify( transify($test_data1) ) ) )^
 E: $test_data10^
ok: 11^

VO: ^
 N: ascii secsify listifcation perilification transfication of test_data2^
 A: secsify( listify(perlify( transify($test_data2 ) ) ) )^
 E: $test_data11^
ok: 12^

VO: ^
 N: ascii secsify listifcation perilification transfication of test_data3^
 A: secsify( listify(perlify( transify($test_data3 )) ) )^
 E: $test_data12^
ok: 13^

 N: ascii secsify listifcation perilification transfication of test_data4^
 A: secsify( listify(perlify( transify($test_data4 ))) )^
 E: $test_data13^
ok: 14^

 N: ascii secsify listifcation perilification transfication of test_data5^
 A: secsify( listify(perlify( transify($test_data5))) )^
 E: $test_data14^
ok: 15^

 N: binary secsify an array reference^
 A: unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary'}))^
 E: 'a50150010541004105' . unpack('H*','ARRAY') . 'a501024105' . unpack('H*','hello') . 'a50104'^
ok: 16^

 N: binary secsify numeric arrays^
 A: unpack('H*',secsify( listify( $test_data6 ), [type => 'binary']))^
 E: $test_data7^
ok: 17^

 N: scalar binary secsify an array reference^
 A: unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary', scalar => 1}))^
 E: 'a50150010541004105' . unpack('H*','ARRAY') . 'a4024105' . unpack('H*','hello') . 'a404'^
ok: 18^

 N: scalar binary secsify numeric arrays^
 A: unpack('H*',secsify( listify( $test_data6 ), type => 'binary', scalar => 1))^
 E: $test_data17^
ok: 19^

 N: binary secsify array with nested hashes, arrays, objects^

 C:
$big_secs2 = 
'a501' . '50' .                       # U1[1] 80  Perl format code 
'a501' . '02' .                       # U1[1] 2
'0106' .                              # L[6]
'4100' .                              #   A[0]
'4104' . unpack('H*','HASH') .        #   A[4] HASH
'4106' . unpack('H*','header') .      #   A[6] header
'0106' .                              #   L[6]
'410b' . unpack('H*','Class::None') . #     A[11] Class::None
'4104' . unpack('H*','HASH') .        #     A[4] HASH
'4104' . unpack('H*','From') .        #     A[4] From
'4106' . unpack('H*','nobody') .      #     A[6] nobody
'4102' . unpack('H*','To') .          #     A[2] To
'4106' . unpack('H*','nobody') .      #     A[6] nobody
'4103' . unpack('H*','msg') .         #   A[3] msg
'0104' .                              #   L[4]
'4100' .                              #     A[0]
'4105' . unpack('H*','ARRAY') .       #     A[5] ARRAY
'4105' . unpack('H*','hello') .       #     A[5] hello 
'4105' . unpack('H*','world');        #     A[5] world
^

VO: ^

 A:
unpack('H*',
        secsify( listify( '2', { msg => ['hello', 'world'] , header => $obj } ), 
                 {type => 'binary'})
   )
^

 E: $big_secs2^
ok: 20^

 N: neuterify a big secsii^
 A: secsify(neuterify (pack('H*',$big_secs2)))^
 E: $test_data15^
ok: 21^

 N: neuterify binary secsii^
 A: secsify(neuterify (pack('H*',$test_data7)))^
 E: $test_data8^
ok: 22^

 N: neuterify scalar binary secsii, length size error^

 C:
   $event = neuterify (pack('H*',$test_data17));
   $event =~ s/\n\t.*?$//;
   while(chomp($event)) { };
^

 A: $event^
 E: 'Format byte length size field is zero.'^
ok: 23^

 N: neuterify scalar binary secsii, no error^
 C: $event = neuterify (pack('H*',$test_data17), scalar => 1)^
 A: ref($event)^
 E: 'ARRAY'^
ok: 24^

 N: neuterify scalar binary secsii^
 A: secsify($event)^
 E: $test_data18^
ok: 25^

 N: transify a free for all secsii input^

 C:
    my $ascii_secsii =
'
L
(
  A \'\' A \'HASH\' A \'header\'
  L [ A "Class::None"  A "HASH" 
      A  "From" A "nobody"
      A  "To" A "nobody"
    ]
  A "msg"
  L,4 A[0] A[5] ARRAY
    A  "hello" A "world"
)

L 
(
  A[0] A "HASH"  A /header/
  L[3] A[0] A \'Index\' U1 10
  A  \'msg\'
  L < A[0] A \'ARRAY\' A  \'body\' >
)

'
^

 C: my $list = transify ($ascii_secsii, obj_format_code => 'P');^
DM: $list^
 A: ref($list)^
 E: 'ARRAY'^
ok: 26^

 N: secsify transified free style secs text^
 A: ref($list) ? secsify( $list ) : ''^
 E: $test_data16^
ok: 27^

 N: transify a bad free for all secsii input^

 C:
    $ascii_secsii =
'
L
( 
  A "msg"
  L,4 A[0] A[5] world
'
^

 C: $list = transify ($ascii_secsii);^
 A: ref(\$list)^
 E: 'SCALAR'^
ok: 28^

DO: ^
 A: $list^
 N: Perl listify numeric arrays^
 A: ref(my $number_list = Data::Secs2->new(perl_secs_numbers => 'strict')->listify( $test_data6 ))^
 E: 'ARRAY'^
ok: 29^

 N: secify Perl  listified numberic arrays^
 A: secsify($number_list)^
 E: $test_data9^
ok: 30^

 N: read configuration^
 A: [config('type')]^
 E: ['type','ascii']^
ok: 31^

 N: write configuration^
 A: [config('type','binary')]^
 E: ['type','ascii']^
ok: 32^

 N: verify write configuration^
 A: [config('type')]^
 E: ['type','binary']^
ok: 33^

 N: restore configuration^
 A: [config('type','ascii')]^
 E: ['type','binary']^
ok: 34^


See_Also: ^

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


HTML:
<hr>
<p><br>
<!-- BLK ID="NOTICE" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="OPT-IN" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="EMAIL" -->
<!-- /BLK -->
<p><br>
<!-- BLK ID="LOG_CGI" -->
<!-- /BLK -->
<p><br>
^



~-~
