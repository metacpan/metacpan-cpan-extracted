#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.02';   # automatically generated file
$DATE = '2004/05/01';
$FILE = __FILE__;


##### Test Script ####
#
# Name: SecsPackStress.t
#
# UUT: Data::SecsPack
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Data::SecsPackStress;
#
# Don't edit this test script file, edit instead
#
# t::Data::SecsPackStress;
#
#	ANY CHANGES MADE HERE TO THIS SCRIPT FILE WILL BE LOST
#
#       the next time Test::STDmaker generates this script file.
#
#

######
#
# T:
#
# use a BEGIN block so we print our plan before Module Under Test is loaded
#
BEGIN { 

   use FindBin;
   use File::Spec;
   use Cwd;

   ########
   # The working directory for this script file is the directory where
   # the test script resides. Thus, any relative files written or read
   # by this test script are located relative to this test script.
   #
   use vars qw( $__restore_dir__ );
   $__restore_dir__ = cwd();
   my ($vol, $dirs) = File::Spec->splitpath($FindBin::Bin,'nofile');
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Pick up any testing program modules off this test script.
   #
   # When testing on a target site before installation, place any test
   # program modules that should not be installed in the same directory
   # as this test script. Likewise, when testing on a host with a @INC
   # restricted to just raw Perl distribution, place any test program
   # modules in the same directory as this test script.
   #
   use lib $FindBin::Bin;

   ########
   # Using Test::Tech, a very light layer over the module "Test" to
   # conduct the tests.  The big feature of the "Test::Tech: module
   # is that it takes expected and actual references and stringify
   # them by using "Data::Secs2" before passing them to the "&Test::ok"
   # Thus, almost any time of Perl data structures may be
   # compared by passing a reference to them to Test::Tech::ok
   #
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(finish is_skip ok plan skip skip_tests tech_config) );
   plan(tests => 104);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}


=head1 comment_out

###
# Have been problems with debugger with trapping CARP
#

####
# Poor man's eval where the test script traps off the Carp::croak 
# Carp::confess functions.
#
# The Perl authorities have Core::die locked down tight so
# it is next to impossible to trap off of Core::die. Lucky 
# must everyone uses Carp to die instead of just dieing.
#
use Carp;
use vars qw($restore_croak $croak_die_error $restore_confess $confess_die_error);
$restore_croak = \&Carp::croak;
$croak_die_error = '';
$restore_confess = \&Carp::confess;
$confess_die_error = '';
no warnings;
*Carp::croak = sub {
   $croak_die_error = '# Test Script Croak. ' . (join '', @_);
   $croak_die_error .= Carp::longmess (join '', @_);
   $croak_die_error =~ s/\n/\n#/g;
       goto CARP_DIE; # once croak can not continue
};
*Carp::confess = sub {
   $confess_die_error = '# Test Script Confess. ' . (join '', @_);
   $confess_die_error .= Carp::longmess (join '', @_);
   $confess_die_error =~ s/\n/\n#/g;
       goto CARP_DIE; # once confess can not continue

};
use warnings;
=cut


   # Perl code from C:
    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Data::SecsPack';
    my $loaded;

    ########
    # Force scalar or array context
    #
    my ($result,@result);

   # Perl code from C:
   my $errors = $fp->load_package($uut, 
       qw(bytes2int float2binary 
          ifloat2binary int2bytes   
          pack_float pack_int pack_num  
          str2float str2int 
          unpack_float unpack_int unpack_num) );


####
# verifies requirement(s):
# L<DataPort::DataFile/general [1] - load>
# 

#####
skip_tests( 1 ) unless skip(
      $loaded, # condition to skip test   
      $errors, # actual results
      '',  # expected results
      "",
      "UUT Loaded");
 
#  ok:  1

   # Perl code from C:
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

ok(  [int2bytes("$integer")], # actual results
     [@bytes], # expected results
     "",
     "int2bytes(\"$integer\")");

#  ok:  2,4,6

   # Perl code from C:
$string = bytes2int(@bytes);

ok(  "$string", # actual results
     "$integer", # expected results
     "",
     "bytes2int(\"$integer\")");

#  ok:  3,5,7

   # Perl code from C:
     
  };

   # Perl code from C:
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

ok(  [int2bytes("$integer")], # actual results
     [@bytes], # expected results
     "",
     "int2bytes(\"$integer\")");

#  ok:  8,9

   # Perl code from C:
     
  };

   # Perl code from C:
 sub binary2hex
 {
     my $magnitude = shift;
     my $sign = $magnitude =~ s/^(\-)\s*// ? $1 : ''; 
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

   # Perl code from C:
@ifloats = ifloat2binary($ifloat_test_mag,$ifloat_test_exp);

ok(  binary2hex($ifloats[0]), # actual results
     $ifloat_expected_mag, # expected results
     "",
     "$ifloat_name magnitude");

#  ok:  10,12,14,16,18,20

ok(  $ifloats[1], # actual results
     $ifloat_expected_exp, # expected results
     "",
     "$ifloat_name exponent");

#  ok:  11,13,15,17,19,21

   # Perl code from C:
};

   # Perl code from C:
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
#;

   # Perl code from C:
($format, $numbers) = pack_float('F4', [$float_int,$float_exp]);

ok(  $format, # actual results
     $f4_format, # expected results
     "",
     "pack_float('F4', [$float_int,$float_exp]) format");

#  ok:  22,28,34,40,45,51,57,63,68,73,79

   # Perl code from C:
 ##########
 # If pack was successful
 # 
   if($format) {;

ok(  unpack('H*', $numbers), # actual results
     $f4_float_hex, # expected results
     "",
     "pack_float('F4', [$float_int,$float_exp]) float");

#  ok:  23,29,35,46,52,58,74,80

skip( $format ne 'F4', # condition to skip test   
      ${unpack_float('F4',$numbers)}[0], # actual results
      $f4_float, # expected results
      "",
      "unpack_float('F4',$f4_float_hex) float");

#  ok:  24,30,36,47,53,59,75,81

   # Perl code from C:
   }

   #########
   # otherwise, pack failed, test for error message
   else {;

ok(  $numbers, # actual results
     $f4_float_hex, # expected results
     "",
     "pack_float('F4', [$float_int,$float_exp]) float");

#  ok:  41,64,69

   # Perl code from C:
};

   # Perl code from C:
($format, $numbers) = pack_float('F8', [$float_int,$float_exp]);

ok(  $format, # actual results
     $f8_format, # expected results
     "",
     "pack_float('F8', [$float_int,$float_exp]) format");

#  ok:  25,31,37,42,48,54,60,65,70,76,82

   # Perl code from C:
   ##############
   # Pack was successful
   # 
   if($format) {;

ok(  unpack('H*', $numbers), # actual results
     $f8_float_hex, # expected results
     "",
     "pack_float('F8', [$float_int,$float_exp]) float");

#  ok:  26,32,38,43,49,55,61,66,71,77,83

ok(  ${unpack_float('F8',$numbers)}[0], # actual results
     $f8_float, # expected results
     "",
     "unpack_float('F8',$f8_float_hex) float");

#  ok:  27,33,39,44,50,56,62,67,72,78,84

   # Perl code from C:
   }

   #########
   # otherwise, pack failed, test for error message
   #
   else {;

ok(  $numbers, # actual results
     $f8_float_hex, # expected results
     "",
     "pack_float('F8', [$float_int,$float_exp]) float");

#  ok:  

   # Perl code from C:
}

 ######
 # End of the Floating Point Test Loop
 #######

 };

   # Perl code from C:
    
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

   # Perl code from C:
($format, $numbers, @strings) = pack_num('I',@test_strings);

ok(  $format, # actual results
     $expected_format, # expected results
     "",
     "pack_num($test_format, $test_string_text) format");

#  ok:  85,90,95,100

ok(  unpack('H*',$numbers), # actual results
     $expected_numbers, # expected results
     "",
     "pack_num($test_format, $test_string_text) numbers");

#  ok:  86,91,96,101

ok(  [@strings], # actual results
     $expected_strings, # expected results
     "",
     "pack_num($test_format, $test_string_text) \@strings");

#  ok:  87,92,97,102

ok(  ref(my $unpack_numbers = unpack_num($expected_format,$numbers)), # actual results
     'ARRAY', # expected results
     "",
     "unpack_num($expected_format, $test_string_text) error check");

#  ok:  88,93,98,103

ok(  $unpack_numbers, # actual results
     $expected_unpack, # expected results
     "",
     "unpack_num($expected_format, $test_string_text) numbers");

#  ok:  89,94,99,104

   # Perl code from C:
 ######
 # End of the pack int Test Loop
 #######

 };


=head1 comment out

# does not work with debugger
CARP_DIE:
    if ($croak_die_error || $confess_die_error) {
        print $Test::TESTOUT = "not ok $Test::ntest\n";
        $Test::ntest++;
        print $Test::TESTERR $croak_die_error . $confess_die_error;
        $croak_die_error = '';
        $confess_die_error = '';
        skip_tests(1, 'Test invalid because of Carp die.');
    }
    no warnings;
    *Carp::croak = $restore_croak;    
    *Carp::confess = $restore_confess;
    use warnings;
=cut

    finish();

__END__

=head1 NAME

SecsPackStress.t - test script for Data::SecsPack

=head1 SYNOPSIS

 SecsPackStress.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

SecsPackStress.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

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

=cut

## end of test script file ##

