#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.04';   # automatically generated file
$DATE = '2004/05/10';
$FILE = __FILE__;


##### Test Script ####
#
# Name: SecsPack.t
#
# UUT: Data::SecsPack
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Data::SecsPack;
#
# Don't edit this test script file, edit instead
#
# t::Data::SecsPack;
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
   plan(tests => 21);

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

    #####
    # Provide a scalar or array context.
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

ok(  $result = $uut->str2int('0xFF'), # actual results
     255, # expected results
     "",
     "str2int(\'0xFF\')");

#  ok:  2

ok(  $result = $uut->str2int('255'), # actual results
     255, # expected results
     "",
     "str2int(\'255\')");

#  ok:  3

ok(  $result = $uut->str2int('hello'), # actual results
     undef, # expected results
     "",
     "str2int(\'hello\')");

#  ok:  4

ok(  $result = $uut->str2int(1E20), # actual results
     undef, # expected results
     "",
     "str2int(1E20)");

#  ok:  5

   # Perl code from C:
my ($strings, @numbers) = str2int(' 78 45 25', ' 512E4 1024 hello world');

ok(  [@numbers], # actual results
     [78,45,25,], # expected results
     "",
     "str2int(' 78 45 25', ' 512E4 1024 hello world') \@numbers");

#  ok:  6

ok(  join( ' ', @$strings), # actual results
     '512E4 1024 hello world', # expected results
     "",
     "str2int(' 78 45 25', ' 512E4 1024 hello world') \@strings");

#  ok:  7

   # Perl code from C:
($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025  0', ' 512E4 hello world');

ok(  [@numbers], # actual results
     [[78,1], [-24,-6], [25,-3], [0, -1], [512,6]], # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') numbers");

#  ok:  8

ok(  join( ' ', @$strings), # actual results
     'hello world', # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') \@strings");

#  ok:  9

   # Perl code from C:
($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1});

ok(  [@numbers], # actual results
     ['78','-2.4E-6','0.0025','255','63','0','512E4'], # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) numbers");

#  ok:  10

ok(  join( ' ', @$strings), # actual results
     'hello world', # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) \@strings");

#  ok:  11

   # Perl code from C:
     my @test_strings = ('78 45 25', '512 1024 100000 hello world');
     my $test_string_text = join ' ',@test_strings;
     my $test_format = 'I';
     my $expected_format = 'U4';
     my $expected_numbers = '0000004e0000002d000000190000020000000400000186a0';
     my $expected_strings = ['hello world'];
     my $expected_unpack = [78, 45, 25, 512, 1024, 100000];

     my ($format, $numbers, @strings) = pack_num('I',@test_strings);

ok(  $format, # actual results
     $expected_format, # expected results
     "",
     "pack_num($test_format, $test_string_text) format");

#  ok:  12

ok(  unpack('H*',$numbers), # actual results
     $expected_numbers, # expected results
     "",
     "pack_num($test_format, $test_string_text) numbers");

#  ok:  13

ok(  [@strings], # actual results
     $expected_strings, # expected results
     "",
     "pack_num($test_format, $test_string_text) \@strings");

#  ok:  14

ok(  ref(my $unpack_numbers = unpack_num($expected_format,$numbers)), # actual results
     'ARRAY', # expected results
     "",
     "unpack_num($expected_format, $test_string_text) error check");

#  ok:  15

ok(  $unpack_numbers, # actual results
     $expected_unpack, # expected results
     "",
     "unpack_num($expected_format, $test_string_text) numbers");

#  ok:  16

   # Perl code from C:
 
     @test_strings = ('78 4.5 .25', '6.45E10 hello world');
     $test_string_text = join ' ',@test_strings;
     $test_format = 'I';
     $expected_format = 'F8';
     $expected_numbers = '405380000000000040120000000000003fd0000000000000422e08ffca000000';
     $expected_strings = ['hello world'];
     my @expected_unpack = (
          '7.800000000000017486E1', 
          '4.500000000000006245E0',
          '2.5E-1',
          '6.4500000000000376452E10'
     );

     ($format, $numbers, @strings) = pack_num('I',@test_strings);

ok(  $format, # actual results
     $expected_format, # expected results
     "",
     "pack_num($test_format, $test_string_text) format");

#  ok:  17

ok(  unpack('H*',$numbers), # actual results
     $expected_numbers, # expected results
     "",
     "pack_num($test_format, $test_string_text) numbers");

#  ok:  18

ok(  [@strings], # actual results
     $expected_strings, # expected results
     "",
     "pack_num($test_format, $test_string_text) \@strings");

#  ok:  19

ok(  ref($unpack_numbers = unpack_num($expected_format,$numbers)), # actual results
     'ARRAY', # expected results
     "",
     "unpack_num($expected_format, $test_string_text) error check");

#  ok:  20

ok(  $unpack_numbers, # actual results
     [@expected_unpack], # expected results
     "",
     "unpack_num($expected_format, $test_string_text) numbers");

#  ok:  21


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

SecsPack.t - test script for Data::SecsPack

=head1 SYNOPSIS

 SecsPack.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

SecsPack.t uses this option to redirect the test results 
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

