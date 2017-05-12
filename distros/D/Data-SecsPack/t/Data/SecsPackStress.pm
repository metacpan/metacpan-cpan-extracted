#!perl
#
# The copyright notice and plain old documentation (POD)
# are at the end of this file.
#
package  t::Data::SecsPackStress;

use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE );
$VERSION = '0.02';
$DATE = '2004/05/01';
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

 Perl Data::SecsPack Program Module

 Revision: -

 Version: 

 Date: 2004/04/26

 Prepared for: General Public 

 Prepared by:  http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com

 Classification: None

=head1 SCOPE

This detail STD and the 
L<General Perl Program Module (PM) STD|Test::STD::PerlSTD>
establishes the tests to verify the
requirements of Perl Program Module (PM) L<Data::SecsPack|Data::SecsPack>

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

 T: 104^

=head2 ok: 1


  C:
     use File::Package;
     my $fp = 'File::Package';
     my $uut = 'Data::SecsPack';
     my $loaded;
     ########
     # Force scalar or array context
     #
     my ($result,@result);
 ^
  N: UUT Loaded^
  R: L<DataPort::DataFile/general [1] - load>^
  S: $loaded^

  C:
    my $errors = $fp->load_package($uut, 
        qw(bytes2int float2binary 
           ifloat2binary int2bytes   
           pack_float pack_int pack_num  
           str2float str2int 
           unpack_float unpack_int unpack_num) );
 ^
  A: $errors^
 SE: ''^
 ok: 1^

=head2 ok: 2,4,6


  C:
  my @bytes_test =  (
     #  $integer                       @bytes 
     #----------------------------------------------
     [ '32767'                       , 127,255,                              ],
     [ '32768'                       , 128,  0,                              ],
     [ '123456789123456789123456789' , 102,30,253,242,227,177,159,124,4,95,21],
  
   );
   my ($string, $integer, @bytes) = ('',());
   foreach (@bytes_test) {
      ($integer,@bytes) = @$_;
 ^
  N: int2bytes(\"$integer\")^
  A: [int2bytes("$integer")]^
  E: [@bytes]^
 ok: 2,4,6^

=head2 ok: 3,5,7

  N: bytes2int(\"$integer\")^
  C: $string = bytes2int(@bytes)^
  A: "$string"^
  E: "$integer"^
 ok: 3,5,7^

=head2 ok: 8,9


  C:
      
   };
 ^

  C:
  ##############
  # Negative values are special case that Math::BigInt
  # did not handle well before version 1.50
  # 
  @bytes_test =  (
     #  $integer        @bytes 
     #----------------------------------------------
     [  -32767      ,   128,   1,                  ],
     [  -32768      ,   128,   0,                  ],
     
   );
   foreach (@bytes_test) {
      ($integer,@bytes) = @$_;
 ^
  N: int2bytes(\"$integer\")^
  A: [int2bytes("$integer")]^
  E: [@bytes]^
 ok: 8,9^

=head2 ok: 10,12,14,16,18,20


  C:
      
   };
 ^

  C:
  sub binary2hex
  {
      my $magnitude = shift;
      my $sign = $magnitude =~ s/^^(\-)\s*// ? $1 : ''; 
      $magnitude =  unpack 'H*',pack('C*', int2bytes($magnitude));
      "$sign$magnitude";
  };
  my @ifloat_test =  (
     #      test               expected
     # --------------------    ------------------------------    
     # magnitude     exp       magnitude                  exp 
     #--------------------------------------------------------
     [           5 ,   -1,      '010000'                  , -1 ],
     [    59101245 ,   -1,      '012e992f108ec37cc1f27e00', -1 ],
     [        3125 ,   -2,      '010000'                  , -5 ],
     [         105 ,    1,      '01500000'                ,  3 ],
     [        -105 ,    1,     '-01500000'                ,  3 ],
     [        -105 ,   -1,     '-01ae147ae147ae147ae14000', -4 ],
     
   );
   my (@ifloats, $ifloat_name, 
      $ifloat_test_mag, $ifloat_test_exp, $ifloat_expected_mag, $ifloat_expected_exp );
 ########
 # Start of the floating point test loop
 # 
 #
 foreach(@ifloat_test) {
   ($ifloat_test_mag, $ifloat_test_exp, $ifloat_expected_mag, $ifloat_expected_exp ) = @$_;
   $ifloat_name = "ifloat2binary($ifloat_test_mag, $ifloat_test_exp)";
 ^
  N: $ifloat_name magnitude^
  C: @ifloats = ifloat2binary($ifloat_test_mag,$ifloat_test_exp)^
  A: binary2hex($ifloats[0])^
  E: $ifloat_expected_mag^
 ok: 10,12,14,16,18,20^

=head2 ok: 11,13,15,17,19,21

  N: $ifloat_name exponent^
  A: $ifloats[1]^
  E: $ifloat_expected_exp^
 ok: 11,13,15,17,19,21^

=head2 ok: 22,28,34,40,45,51,57,63,68,73,79

  C: };^

  C:
   ###################
   #   F4 Not Rounded  
   # 
   #                                (without implied 1)          implied 1
   #   Test       sign  exponent    significant                  hex               
   #
   #    10.5       1    100 0001 0  0101 0000 0000 0000 0000 000 500000
   #   -10.5       1    100 0001 0  0101 0000 0000 0000 0000 000 500000
   #   63.54       0    100 0010 0  1111 1100 0101 0001 1110 101 fc51ea 
   #   63.54E64    0    111 1111 1  0000 0000 0000 0000 0000 000 000000
   #   63.54E36    0    111 1110 0  0111 1110 0110 1010 1101 111 7e6ade
   #   63.54E-36   0    000 0110 1  0101 0001 1101 0110 0010 101 51d62a
   #  -63.54E-36   1    000 0110 1  0101 0001 1101 0110 0010 101 51d62a 
   #  -63.54E-306  1    000 0000 0  0000 0000 0000 0000 0000 000 000000
   #   0           0    000 0000 0  0000 0000 0000 0000 0000 000 000000
   #  -0           1    000 0000 0  0000 0000 0000 0000 0000 000 000000
   #
   #                                 2**x    significant 
   #   Test         Hex        sign exponent hex    decimal
   #   5.E-1
   #   5.9101245E-1
   #   3.125E-2
   #    10.5        4128 0000   0         3  500000 1.3125
   #   -10.5        C128 0000   1         3  500000 1.3125
   #   63.54        427E 28F5   0         5  fc51ea 1.9856249
   #   63.54E64     7F80 0000   0       128  000000 1.0        (infinity) 
   #   63.54E36     7E3F 356F   0       125  7e6ade 1.4938182    
   #   63.54E-36    06A8 EB15   0      -114  51d62a 1.3196741 
   #  -63.54E-36    86A8 EB15   1      -114  51d62a 1.3196741
   #  -63.54E-306   8000 0000   1      -127  000000 1.0        (underflow)
   #  -63.54E306    7F80 0000   1       128  000000 1.0        (infinity)
   #   0            0000 0000   1      -127  000000 1.0 
   #  -0            8000 0000   1      -127  000000 1.0
   # 
   #   F8 Not Rounded 
   #                                            2**x 
   #   Test         Hex                sign exponent significant
   #   5.E-1
   #   5.9101245E-1
   #   3.125E-2
   #    10.5        4025 0000 0000 0000 0         3  1.3125   
   #   -10.5        C025 0000 0000 0000 1         3  1.3125
   #   63.54        404F C51E B851 EB85 0         5  1.9856249
   #   63.54E64     4D98 2249 9022 2814 0       218  1.5083709364139440 
   #   63.54E36     47C7 E6AD EF57 89B0 0       125  1.4938182210249628
   #   63.54E-36    38D5 1D62 A97A 8965 0      -114  1.3196741695652118
   #  -63.54E-36    B8D5 1D62 A97A 8965 1      -114  1.3196741695652118
   #  -63.54E-306   80C6 4F45 661E 6296 1     -1011  1.3943532933246040
   #   63.54E306    7FD6 9EF9 420B C99B 1      1022  1.4138119296954758
   #   0            0000 0000 0000 0000 0     -1023  1.0
   #  -0            8000 0000 0000 0000 1     -1023  1.0
   #
   #
  my $float_msg1 = "F4 exponent overflow\n\tData::SecsPack::pack_float-3\n";
  my $float_msg2 = "F4 exponent underflow\n\tData::SecsPack::pack_float-4\n";
  my @float_test =  (
     # pack float in       expected pack                                expected unpack
     # --------------     ---------------- -----------------------   -----------------------------------------------
     # magnitude  exp     F4 pack           F8 pack                     F4 unpack                     F8 unpack 
     #-------------------------------------------------------------------------------------------------------------
      [  '105'  ,    '1', 'F4' ,  '41280000', 'F8', '4025000000000000',  '1.05E1'                   ,  '1.0500000000000031225E1'   ],
      [ '-105'  ,    '1', 'F4' ,  'c1280000', 'F8', 'c025000000000000', '-1.05E1'                   , '-1.0500000000000031225E1'   ],
      [  '6354' ,    '1', 'F4' ,  '427e28f5', 'F8', '404fc51eb851eb85',  '6.3539997100830078125E1'  ,  '6.3540000000000393082E1'   ],
      [  '6354' ,   '65', undef, $float_msg1, 'F8', '4d98224990222622',  ''                         ,  '6.3539999999995605128E65'  ],
      [  '6354' ,   '37', 'F4',   '7e3f356f', 'F8', '47c7e6adef5788f6',  '6.3539997568971820731E37' ,  '6.3539999999998501444E37'  ],
      [  '6354' ,  '-35', 'F4',   '06a8eb15', 'F8', '38d51d62a97a8a86',  '6.3539998299848930747E-35',  '6.3540000000003286544E-35' ],
      [ '-6354' ,  '-35', 'F4',   '86a8eb15', 'F8', 'b8d51d62a97a8a86', '-6.3539998299848930747E-35', '-6.3540000000003286544E-35' ],
      [ '-6354' , '-305', undef, $float_msg2, 'F8', '80c64f45661e6e8f',  ''                         , '-6.3540000000031236507E-305'],
      [ ' 6354' ,  '307', undef, $float_msg1, 'F8', '7fd69ef9420bbdfc',  ''                         ,  '6.3539999999970548993E307' ],
      [     '0' ,    '0', 'F4',   '00000000', 'F8', '0000000000000000',  '5.8774717541114375398E-39',  '1.1125369292536006915E-308'],
      [    '-0' ,    '0', 'F4',   '80000000', 'F8', '8000000000000000', '-5.8774717541114375398E-39', '-1.1125369292536006915E-308'],
   );
 my $F4_criteria = 1E-4;
 my $F8_criteria = 1E-4;
 #######
 # Loop the above values for both a F4 and F8 conversions
 #
 my ($float_int, $float_frac, $float_exp, $f4_float_hex, $f8_float_hex);
 my ($f4_format, $f8_format, $f4_float, $f8_float, $format, $numbers);

 ########
 # Start of the floating point test loop
 # 
 #
 foreach $_ (@float_test) {
   ($float_int, $float_exp, $f4_format, $f4_float_hex, $f8_format, $f8_float_hex,  $f4_float, $f8_float) = @$_;
 #####
 # Filling in the above values in the tests
 #
 ^
  N: pack_float('F4', [$float_int,$float_exp]) format^
  C: ($format, $numbers) = pack_float('F4', [$float_int,$float_exp])^
  A: $format^
  E: $f4_format^
 ok: 22,28,34,40,45,51,57,63,68,73,79^

=head2 ok: 23,29,35,46,52,58,74,80


  C:
  ##########
  # If pack was successful
  # 
    if($format) {
 ^
  N: pack_float('F4', [$float_int,$float_exp]) float^
  A: unpack('H*', $numbers)^
  E: $f4_float_hex^
 ok: 23,29,35,46,52,58,74,80^

=head2 ok: 24,30,36,47,53,59,75,81

  N: unpack_float('F4',$f4_float_hex) float^
  S: $format ne 'F4'^
  A: ${unpack_float('F4',$numbers)}[0]^
  E: $f4_float^
 ok: 24,30,36,47,53,59,75,81^

=head2 ok: 41,64,69


  C:
    }
    #########
    # otherwise, pack failed, test for error message
    else {
 ^
  N: pack_float('F4', [$float_int,$float_exp]) float^
  A: $numbers^
  E: $f4_float_hex^
 ok: 41,64,69^

=head2 ok: 25,31,37,42,48,54,60,65,70,76,82

  C: }^
  N: pack_float('F8', [$float_int,$float_exp]) format^
  C: ($format, $numbers) = pack_float('F8', [$float_int,$float_exp])^
  A: $format^
  E: $f8_format^
 ok: 25,31,37,42,48,54,60,65,70,76,82^

=head2 ok: 26,32,38,43,49,55,61,66,71,77,83


  C:
    ##############
    # Pack was successful
    # 
    if($format) {
 ^
  N: pack_float('F8', [$float_int,$float_exp]) float^
  A: unpack('H*', $numbers)^
  E: $f8_float_hex^
 ok: 26,32,38,43,49,55,61,66,71,77,83^

=head2 ok: 27,33,39,44,50,56,62,67,72,78,84

  N: unpack_float('F8',$f8_float_hex) float^
  A: ${unpack_float('F8',$numbers)}[0]^
  E: $f8_float^
 ok: 27,33,39,44,50,56,62,67,72,78,84^

=head2 ok: 


  C:
    }
    #########
    # otherwise, pack failed, test for error message
    #
    else {
 ^
  N: pack_float('F8', [$float_int,$float_exp]) float^
  A: $numbers^
  E: $f8_float_hex^
 ok: ^

=head2 ok: 85,90,95,100


  C:
 }
  ######
  # End of the Floating Point Test Loop
  #######
  };
 ^

  C:
     
  my @pack_int_test =  (
    [                                                           
      ['78 45 25', '512 1024 hello world']                   ,  # test_strings
      'I'                                                    ,  # test_format
      'U2'                                                   ,  # expected_format
      '004e002d001902000400'                                 ,  # expected_numbers  
      ['hello world']                                        ,  # expected_strings  
      [78, 45, 25, 512, 1024]                                ,  # expected_unpack      
    ],
    [
      ['-78 45 -25', 'world']                                ,  # test_strings
      'I'                                                    ,  # test_format
      'S1'                                                   ,  # expected_format
      'b22de7'                                               ,  # expected_numbers  
      ['world']                                              ,  # expected_strings  
      [-78, 45, -25]                                         ,  # expected_unpack      
    ],
    [
      ['-128 128 -127 127']                                  ,  # test_strings
      'I'                                                    ,  # test_format
      'S2'                                                   ,  # expected_format
      'ff800080ff81007f'                                     ,  # expected_numbers  
      ['']                                                   ,  # expected_strings  
      [-128, 128, -127, 127]                                 ,  # expected_unpack      
    ],
    [
      ['-32768 32768 -32767 32767']                          ,  # test_strings
      'I'                                                    ,  # test_format
      'S4'                                                   ,  # expected_format
      'ffff800000008000ffff800100007fff'                     ,  # expected_numbers                                                     ,  # expected_numbers  
      ['']                                                   ,  # expected_strings  
      [-32768,32768,-32767,32767]                            ,  # expected_unpack      
    ],
 );

     my ($test_strings, @test_strings,$test_string_text,$test_format, $expected_format,
         $expected_numbers,$expected_strings, $expected_unpack);
     my (@strings);
 ########
 # Start of the pack int test loop
 # 
 #
 foreach $_ (@pack_int_test) {
     ($test_strings,$test_format, $expected_format,
         $expected_numbers,$expected_strings, $expected_unpack) = @$_;
      @test_strings = @$test_strings;
      $test_string_text = join ' ',@test_strings;
 ^
  N: pack_num($test_format, $test_string_text) format^
  C: ($format, $numbers, @strings) = pack_num('I',@test_strings)^
  A: $format^
  E: $expected_format^
 ok: 85,90,95,100^

=head2 ok: 86,91,96,101

  N: pack_num($test_format, $test_string_text) numbers^
  A: unpack('H*',$numbers)^
  E: $expected_numbers^
 ok: 86,91,96,101^

=head2 ok: 87,92,97,102

  N: pack_num($test_format, $test_string_text) \@strings^
  A: [@strings]^
  E: $expected_strings^
 ok: 87,92,97,102^

=head2 ok: 88,93,98,103

  N: unpack_num($expected_format, $test_string_text) error check^
  A: ref(my $unpack_numbers = unpack_num($expected_format,$numbers))^
  E: 'ARRAY'^
 ok: 88,93,98,103^

=head2 ok: 89,94,99,104

  N: unpack_num($expected_format, $test_string_text) numbers^
  A: $unpack_numbers^
  E: $expected_unpack^
 ok: 89,94,99,104^



#######
#  
#  5. REQUIREMENTS TRACEABILITY
#
#

=head1 REQUIREMENTS TRACEABILITY

  Requirement                                                      Test
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<DataPort::DataFile/general [1] - load>                         L<t::Data::SecsPackStress/ok: 1>


  Test                                                             Requirement
 ---------------------------------------------------------------- ----------------------------------------------------------------
 L<t::Data::SecsPackStress/ok: 1>                                 L<DataPort::DataFile/general [1] - load>


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

L<Data::SecsPack>

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
UUT: Data::SecsPack^
Revision: -^
End_User: General Public^
Author: http://www.SoftwareDiamonds.com support@SoftwareDiamonds.com^
Detail_Template: ^
STD2167_Template: ^
Version: ^
Classification: None^
Temp: temp.pl^
Demo: SecsPackStress.d^
Verify: SecsPackStress.t^


 T: 104^


 C:
    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Data::SecsPack';
    my $loaded;

    ########
    # Force scalar or array context
    #
    my ($result,@result);
^

 N: UUT Loaded^
 R: L<DataPort::DataFile/general [1] - load>^
 S: $loaded^

 C:
   my $errors = $fp->load_package($uut, 
       qw(bytes2int float2binary 
          ifloat2binary int2bytes   
          pack_float pack_int pack_num  
          str2float str2int 
          unpack_float unpack_int unpack_num) );
^

 A: $errors^
SE: ''^
ok: 1^


 C:
 my @bytes_test =  (

    #  $integer                       @bytes 
    #----------------------------------------------
    [ '32767'                       , 127,255,                              ],
    [ '32768'                       , 128,  0,                              ],
    [ '123456789123456789123456789' , 102,30,253,242,227,177,159,124,4,95,21],
 
  );

  my ($string, $integer, @bytes) = ('',());
  foreach (@bytes_test) {
     ($integer,@bytes) = @$_;
^

 N: int2bytes(\"$integer\")^
 A: [int2bytes("$integer")]^
 E: [@bytes]^
ok: 2,4,6^

 N: bytes2int(\"$integer\")^
 C: $string = bytes2int(@bytes)^
 A: "$string"^
 E: "$integer"^
ok: 3,5,7^


 C:
     
  };
^


 C:
 ##############
 # Negative values are special case that Math::BigInt
 # did not handle well before version 1.50
 # 
 @bytes_test =  (

    #  $integer        @bytes 
    #----------------------------------------------
    [  -32767      ,   128,   1,                  ],
    [  -32768      ,   128,   0,                  ],
    
  );

  foreach (@bytes_test) {
     ($integer,@bytes) = @$_;
^

 N: int2bytes(\"$integer\")^
 A: [int2bytes("$integer")]^
 E: [@bytes]^
ok: 8,9^


 C:
     
  };
^


 C:
 sub binary2hex
 {
     my $magnitude = shift;
     my $sign = $magnitude =~ s/^^(\-)\s*// ? $1 : ''; 
     $magnitude =  unpack 'H*',pack('C*', int2bytes($magnitude));
     "$sign$magnitude";
 };

 my @ifloat_test =  (
    #      test               expected
    # --------------------    ------------------------------    
    # magnitude     exp       magnitude                  exp 
    #--------------------------------------------------------
    [           5 ,   -1,      '010000'                  , -1 ],
    [    59101245 ,   -1,      '012e992f108ec37cc1f27e00', -1 ],
    [        3125 ,   -2,      '010000'                  , -5 ],
    [         105 ,    1,      '01500000'                ,  3 ],
    [        -105 ,    1,     '-01500000'                ,  3 ],
    [        -105 ,   -1,     '-01ae147ae147ae147ae14000', -4 ],
    
  );

  my (@ifloats, $ifloat_name, 
     $ifloat_test_mag, $ifloat_test_exp, $ifloat_expected_mag, $ifloat_expected_exp );

########
# Start of the floating point test loop
# 
#
foreach(@ifloat_test) {

  ($ifloat_test_mag, $ifloat_test_exp, $ifloat_expected_mag, $ifloat_expected_exp ) = @$_;
  $ifloat_name = "ifloat2binary($ifloat_test_mag, $ifloat_test_exp)";
^

 N: $ifloat_name magnitude^
 C: @ifloats = ifloat2binary($ifloat_test_mag,$ifloat_test_exp)^
 A: binary2hex($ifloats[0])^
 E: $ifloat_expected_mag^
ok: 10,12,14,16,18,20^

 N: $ifloat_name exponent^
 A: $ifloats[1]^
 E: $ifloat_expected_exp^
ok: 11,13,15,17,19,21^

 C: };^

 C:
  ###################
  #   F4 Not Rounded  
  # 
  #                                (without implied 1)          implied 1
  #   Test       sign  exponent    significant                  hex               
  #
  #    10.5       1    100 0001 0  0101 0000 0000 0000 0000 000 500000
  #   -10.5       1    100 0001 0  0101 0000 0000 0000 0000 000 500000
  #   63.54       0    100 0010 0  1111 1100 0101 0001 1110 101 fc51ea 
  #   63.54E64    0    111 1111 1  0000 0000 0000 0000 0000 000 000000
  #   63.54E36    0    111 1110 0  0111 1110 0110 1010 1101 111 7e6ade
  #   63.54E-36   0    000 0110 1  0101 0001 1101 0110 0010 101 51d62a
  #  -63.54E-36   1    000 0110 1  0101 0001 1101 0110 0010 101 51d62a 
  #  -63.54E-306  1    000 0000 0  0000 0000 0000 0000 0000 000 000000
  #   0           0    000 0000 0  0000 0000 0000 0000 0000 000 000000
  #  -0           1    000 0000 0  0000 0000 0000 0000 0000 000 000000
  #
  #                                 2**x    significant 
  #   Test         Hex        sign exponent hex    decimal
  #   5.E-1
  #   5.9101245E-1
  #   3.125E-2
  #    10.5        4128 0000   0         3  500000 1.3125
  #   -10.5        C128 0000   1         3  500000 1.3125
  #   63.54        427E 28F5   0         5  fc51ea 1.9856249
  #   63.54E64     7F80 0000   0       128  000000 1.0        (infinity) 
  #   63.54E36     7E3F 356F   0       125  7e6ade 1.4938182    
  #   63.54E-36    06A8 EB15   0      -114  51d62a 1.3196741 
  #  -63.54E-36    86A8 EB15   1      -114  51d62a 1.3196741
  #  -63.54E-306   8000 0000   1      -127  000000 1.0        (underflow)
  #  -63.54E306    7F80 0000   1       128  000000 1.0        (infinity)
  #   0            0000 0000   1      -127  000000 1.0 
  #  -0            8000 0000   1      -127  000000 1.0
  # 
  #   F8 Not Rounded 
  #                                            2**x 
  #   Test         Hex                sign exponent significant
  #   5.E-1
  #   5.9101245E-1
  #   3.125E-2
  #    10.5        4025 0000 0000 0000 0         3  1.3125   
  #   -10.5        C025 0000 0000 0000 1         3  1.3125
  #   63.54        404F C51E B851 EB85 0         5  1.9856249
  #   63.54E64     4D98 2249 9022 2814 0       218  1.5083709364139440 
  #   63.54E36     47C7 E6AD EF57 89B0 0       125  1.4938182210249628
  #   63.54E-36    38D5 1D62 A97A 8965 0      -114  1.3196741695652118
  #  -63.54E-36    B8D5 1D62 A97A 8965 1      -114  1.3196741695652118
  #  -63.54E-306   80C6 4F45 661E 6296 1     -1011  1.3943532933246040
  #   63.54E306    7FD6 9EF9 420B C99B 1      1022  1.4138119296954758
  #   0            0000 0000 0000 0000 0     -1023  1.0
  #  -0            8000 0000 0000 0000 1     -1023  1.0
  #
  #
 my $float_msg1 = "F4 exponent overflow\n\tData::SecsPack::pack_float-3\n";
 my $float_msg2 = "F4 exponent underflow\n\tData::SecsPack::pack_float-4\n";

 my @float_test =  (
    # pack float in       expected pack                                expected unpack
    # --------------     ---------------- -----------------------   -----------------------------------------------
    # magnitude  exp     F4 pack           F8 pack                     F4 unpack                     F8 unpack 
    #-------------------------------------------------------------------------------------------------------------
     [  '105'  ,    '1', 'F4' ,  '41280000', 'F8', '4025000000000000',  '1.05E1'                   ,  '1.0500000000000031225E1'   ],
     [ '-105'  ,    '1', 'F4' ,  'c1280000', 'F8', 'c025000000000000', '-1.05E1'                   , '-1.0500000000000031225E1'   ],
     [  '6354' ,    '1', 'F4' ,  '427e28f5', 'F8', '404fc51eb851eb85',  '6.3539997100830078125E1'  ,  '6.3540000000000393082E1'   ],
     [  '6354' ,   '65', undef, $float_msg1, 'F8', '4d98224990222622',  ''                         ,  '6.3539999999995605128E65'  ],
     [  '6354' ,   '37', 'F4',   '7e3f356f', 'F8', '47c7e6adef5788f6',  '6.3539997568971820731E37' ,  '6.3539999999998501444E37'  ],
     [  '6354' ,  '-35', 'F4',   '06a8eb15', 'F8', '38d51d62a97a8a86',  '6.3539998299848930747E-35',  '6.3540000000003286544E-35' ],
     [ '-6354' ,  '-35', 'F4',   '86a8eb15', 'F8', 'b8d51d62a97a8a86', '-6.3539998299848930747E-35', '-6.3540000000003286544E-35' ],
     [ '-6354' , '-305', undef, $float_msg2, 'F8', '80c64f45661e6e8f',  ''                         , '-6.3540000000031236507E-305'],
     [ ' 6354' ,  '307', undef, $float_msg1, 'F8', '7fd69ef9420bbdfc',  ''                         ,  '6.3539999999970548993E307' ],
     [     '0' ,    '0', 'F4',   '00000000', 'F8', '0000000000000000',  '5.8774717541114375398E-39',  '1.1125369292536006915E-308'],
     [    '-0' ,    '0', 'F4',   '80000000', 'F8', '8000000000000000', '-5.8774717541114375398E-39', '-1.1125369292536006915E-308'],
  );

my $F4_criteria = 1E-4;
my $F8_criteria = 1E-4;

#######
# Loop the above values for both a F4 and F8 conversions
#
my ($float_int, $float_frac, $float_exp, $f4_float_hex, $f8_float_hex);
my ($f4_format, $f8_format, $f4_float, $f8_float, $format, $numbers);


########
# Start of the floating point test loop
# 
#
foreach $_ (@float_test) {

  ($float_int, $float_exp, $f4_format, $f4_float_hex, $f8_format, $f8_float_hex,  $f4_float, $f8_float) = @$_;

#####
# Filling in the above values in the tests
#
^

 N: pack_float('F4', [$float_int,$float_exp]) format^
 C: ($format, $numbers) = pack_float('F4', [$float_int,$float_exp])^
 A: $format^
 E: $f4_format^
ok: 22,28,34,40,45,51,57,63,68,73,79^


 C:
 ##########
 # If pack was successful
 # 
   if($format) {
^

 N: pack_float('F4', [$float_int,$float_exp]) float^
 A: unpack('H*', $numbers)^
 E: $f4_float_hex^
ok: 23,29,35,46,52,58,74,80^

 N: unpack_float('F4',$f4_float_hex) float^
 S: $format ne 'F4'^
 A: ${unpack_float('F4',$numbers)}[0]^
 E: $f4_float^
ok: 24,30,36,47,53,59,75,81^


 C:
   }

   #########
   # otherwise, pack failed, test for error message
   else {
^

 N: pack_float('F4', [$float_int,$float_exp]) float^
 A: $numbers^
 E: $f4_float_hex^
ok: 41,64,69^

 C: }^
 N: pack_float('F8', [$float_int,$float_exp]) format^
 C: ($format, $numbers) = pack_float('F8', [$float_int,$float_exp])^
 A: $format^
 E: $f8_format^
ok: 25,31,37,42,48,54,60,65,70,76,82^


 C:
   ##############
   # Pack was successful
   # 
   if($format) {
^

 N: pack_float('F8', [$float_int,$float_exp]) float^
 A: unpack('H*', $numbers)^
 E: $f8_float_hex^
ok: 26,32,38,43,49,55,61,66,71,77,83^

 N: unpack_float('F8',$f8_float_hex) float^
 A: ${unpack_float('F8',$numbers)}[0]^
 E: $f8_float^
ok: 27,33,39,44,50,56,62,67,72,78,84^


 C:
   }

   #########
   # otherwise, pack failed, test for error message
   #
   else {
^

 N: pack_float('F8', [$float_int,$float_exp]) float^
 A: $numbers^
 E: $f8_float_hex^
ok: ^


 C:
}

 ######
 # End of the Floating Point Test Loop
 #######

 };
^


 C:
    
 my @pack_int_test =  (
   [                                                           
     ['78 45 25', '512 1024 hello world']                   ,  # test_strings
     'I'                                                    ,  # test_format
     'U2'                                                   ,  # expected_format
     '004e002d001902000400'                                 ,  # expected_numbers  
     ['hello world']                                        ,  # expected_strings  
     [78, 45, 25, 512, 1024]                                ,  # expected_unpack      
   ],

   [
     ['-78 45 -25', 'world']                                ,  # test_strings
     'I'                                                    ,  # test_format
     'S1'                                                   ,  # expected_format
     'b22de7'                                               ,  # expected_numbers  
     ['world']                                              ,  # expected_strings  
     [-78, 45, -25]                                         ,  # expected_unpack      
   ],

   [
     ['-128 128 -127 127']                                  ,  # test_strings
     'I'                                                    ,  # test_format
     'S2'                                                   ,  # expected_format
     'ff800080ff81007f'                                     ,  # expected_numbers  
     ['']                                                   ,  # expected_strings  
     [-128, 128, -127, 127]                                 ,  # expected_unpack      
   ],

   [
     ['-32768 32768 -32767 32767']                          ,  # test_strings
     'I'                                                    ,  # test_format
     'S4'                                                   ,  # expected_format
     'ffff800000008000ffff800100007fff'                     ,  # expected_numbers                                                     ,  # expected_numbers  
     ['']                                                   ,  # expected_strings  
     [-32768,32768,-32767,32767]                            ,  # expected_unpack      
   ],

);


    my ($test_strings, @test_strings,$test_string_text,$test_format, $expected_format,
        $expected_numbers,$expected_strings, $expected_unpack);

    my (@strings);

########
# Start of the pack int test loop
# 
#
foreach $_ (@pack_int_test) {

    ($test_strings,$test_format, $expected_format,
        $expected_numbers,$expected_strings, $expected_unpack) = @$_;

     @test_strings = @$test_strings;
     $test_string_text = join ' ',@test_strings;
^

 N: pack_num($test_format, $test_string_text) format^
 C: ($format, $numbers, @strings) = pack_num('I',@test_strings)^
 A: $format^
 E: $expected_format^
ok: 85,90,95,100^

 N: pack_num($test_format, $test_string_text) numbers^
 A: unpack('H*',$numbers)^
 E: $expected_numbers^
ok: 86,91,96,101^

 N: pack_num($test_format, $test_string_text) \@strings^
 A: [@strings]^
 E: $expected_strings^
ok: 87,92,97,102^

 N: unpack_num($expected_format, $test_string_text) error check^
 A: ref(my $unpack_numbers = unpack_num($expected_format,$numbers))^
 E: 'ARRAY'^
ok: 88,93,98,103^

 N: unpack_num($expected_format, $test_string_text) numbers^
 A: $unpack_numbers^
 E: $expected_unpack^
ok: 89,94,99,104^


 C:
 ######
 # End of the pack int Test Loop
 #######

 };
^


See_Also: L<Data::SecsPack>^

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
