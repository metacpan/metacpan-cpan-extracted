#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.07';   # automatically generated file
$DATE = '2004/05/11';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Secs2.t
#
# UUT: Data::Secs2
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Data::Secs2;
#
# Don't edit this test script file, edit instead
#
# t::Data::Secs2;
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
   plan(tests => 34);

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

   # Perl code from QC:
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

skip_tests( 1 ) unless ok(
      $loaded = $fp->is_package_loaded($uut), # actual results
       '1', # expected results
      "",
      "UUT loaded as Part of Test::Tech"); 

#  ok:  1

   # Perl code from C:
$uut->import( 'stringify' );

ok(  stringify( 'string' ), # actual results
     'string', # expected results
     "",
     "stringify a scalar string");

#  ok:  2

ok(  stringify( 2 ), # actual results
     2, # expected results
     "",
     "stringify a scalar number");

#  ok:  3

ok(  stringify( '2', 'hello', 4 ), # actual results
     'U1[1] 80
N 2
A[5] hello
N 4
', # expected results
     "",
     "stringify an array");

#  ok:  4

ok(  stringify( {header => 'To: world', body => 'hello'}), # actual results
     'U1[1] 80
L[6]
  A[0]
  A[4] HASH
  A[4] body
  A[5] hello
  A[6] header
  A[9] To: world
', # expected results
     "",
     "stringify a hash reference");

#  ok:  5

ok(  secsify( listify( ['2', 'hello', 4, 0, undef] ) ), # actual results
     $test_data19, # expected results
     "",
     "ascii secsify lisfication of test_data1 an array reference");

#  ok:  6

ok(  secsify( listify( {header => 'To: world', body => 'hello'}) ), # actual results
     $test_data2, # expected results
     "",
     "ascii secsify lisfication of test_data2 -  a hash reference");

#  ok:  7

ok(  secsify( listify( '2', ['hello', 'world'], 512 ) ), # actual results
     $test_data3, # expected results
     "",
     "ascii secsify lisfication of test_data3 - array with an array ref");

#  ok:  8

   # Perl code from C:
my $obj = bless { To => 'nobody', From => 'nobody'}, 'Class::None';

ok(  secsify( listify( '2', { msg => ['hello', 'world'] , header => $obj } ) ), # actual results
     $test_data4, # expected results
     "",
     "ascii secsify lisfication of test_data4 - array with nested hashes, arrays, objects");

#  ok:  9

ok(      secsify( listify( {msg => ['hello', 'world'] , header => $obj }, 
     {msg => [ 'body' ], header => $obj} ) ), # actual results
     $test_data5, # expected results
     "",
     "ascii secsify lisfication of test_data5 - hash with nested hashes, arrays, common objects");

#  ok:  10

ok(  secsify( listify( perlify( transify($test_data1) ) ) ), # actual results
     $test_data10, # expected results
     "",
     "ascii secsify listifcation perilification transfication of test_data1");

#  ok:  11

ok(  secsify( listify(perlify( transify($test_data2 ) ) ) ), # actual results
     $test_data11, # expected results
     "",
     "ascii secsify listifcation perilification transfication of test_data2");

#  ok:  12

ok(  secsify( listify(perlify( transify($test_data3 )) ) ), # actual results
     $test_data12, # expected results
     "",
     "ascii secsify listifcation perilification transfication of test_data3");

#  ok:  13

ok(  secsify( listify(perlify( transify($test_data4 ))) ), # actual results
     $test_data13, # expected results
     "",
     "ascii secsify listifcation perilification transfication of test_data4");

#  ok:  14

ok(  secsify( listify(perlify( transify($test_data5))) ), # actual results
     $test_data14, # expected results
     "",
     "ascii secsify listifcation perilification transfication of test_data5");

#  ok:  15

ok(  unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary'})), # actual results
     'a50150010541004105' . unpack('H*','ARRAY') . 'a501024105' . unpack('H*','hello') . 'a50104', # expected results
     "",
     "binary secsify an array reference");

#  ok:  16

ok(  unpack('H*',secsify( listify( $test_data6 ), [type => 'binary'])), # actual results
     $test_data7, # expected results
     "",
     "binary secsify numeric arrays");

#  ok:  17

ok(  unpack('H*',secsify( listify( ['2', 'hello', 4] ), {type => 'binary', scalar => 1})), # actual results
     'a50150010541004105' . unpack('H*','ARRAY') . 'a4024105' . unpack('H*','hello') . 'a404', # expected results
     "",
     "scalar binary secsify an array reference");

#  ok:  18

ok(  unpack('H*',secsify( listify( $test_data6 ), type => 'binary', scalar => 1)), # actual results
     $test_data17, # expected results
     "",
     "scalar binary secsify numeric arrays");

#  ok:  19

   # Perl code from C:
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
'4105' . unpack('H*','world');        #     A[5] world;

ok(  unpack('H*',
        secsify( listify( '2', { msg => ['hello', 'world'] , header => $obj } ), 
                 {type => 'binary'})
   ), # actual results
     $big_secs2, # expected results
     "",
     "binary secsify array with nested hashes, arrays, objects");

#  ok:  20

ok(  secsify(neuterify (pack('H*',$big_secs2))), # actual results
     $test_data15, # expected results
     "",
     "neuterify a big secsii");

#  ok:  21

ok(  secsify(neuterify (pack('H*',$test_data7))), # actual results
     $test_data8, # expected results
     "",
     "neuterify binary secsii");

#  ok:  22

   # Perl code from C:
   $event = neuterify (pack('H*',$test_data17));
   $event =~ s/\n\t.*?$//;
   while(chomp($event)) { };

ok(  $event, # actual results
     'Format byte length size field is zero.', # expected results
     "",
     "neuterify scalar binary secsii, length size error");

#  ok:  23

   # Perl code from C:
$event = neuterify (pack('H*',$test_data17), scalar => 1);

ok(  ref($event), # actual results
     'ARRAY', # expected results
     "",
     "neuterify scalar binary secsii, no error");

#  ok:  24

ok(  secsify($event), # actual results
     $test_data18, # expected results
     "",
     "neuterify scalar binary secsii");

#  ok:  25

   # Perl code from C:
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

';

   # Perl code from C:
my $list = transify ($ascii_secsii, obj_format_code => 'P');

ok(  ref($list), # actual results
     'ARRAY', # expected results
     "$list",
     "transify a free for all secsii input");

#  ok:  26

ok(  ref($list) ? secsify( $list ) : '', # actual results
     $test_data16, # expected results
     "",
     "secsify transified free style secs text");

#  ok:  27

   # Perl code from C:
    $ascii_secsii =
'
L
( 
  A "msg"
  L,4 A[0] A[5] world
';

   # Perl code from C:
$list = transify ($ascii_secsii);

ok(  ref(\$list), # actual results
     'SCALAR', # expected results
     "",
     "transify a bad free for all secsii input");

#  ok:  28

ok(  ref(my $number_list = Data::Secs2->new(perl_secs_numbers => 'strict')->listify( $test_data6 )), # actual results
     'ARRAY', # expected results
     "",
     "Perl listify numeric arrays");

#  ok:  29

ok(  secsify($number_list), # actual results
     $test_data9, # expected results
     "",
     "secify Perl  listified numberic arrays");

#  ok:  30

ok(  [config('type')], # actual results
     ['type','ascii'], # expected results
     "",
     "read configuration");

#  ok:  31

ok(  [config('type','binary')], # actual results
     ['type','ascii'], # expected results
     "",
     "write configuration");

#  ok:  32

ok(  [config('type')], # actual results
     ['type','binary'], # expected results
     "",
     "verify write configuration");

#  ok:  33

ok(  [config('type','ascii')], # actual results
     ['type','binary'], # expected results
     "",
     "restore configuration");

#  ok:  34


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

Secs2.t - test script for Data::Secs2

=head1 SYNOPSIS

 Secs2.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Secs2.t uses this option to redirect the test results 
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

