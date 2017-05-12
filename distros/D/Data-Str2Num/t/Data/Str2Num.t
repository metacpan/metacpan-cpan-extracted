#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.04';   # automatically generated file
$DATE = '2004/05/19';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Str2Num.t
#
# UUT: Data::Str2Num
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Data::Str2Num;
#
# Don't edit this test script file, edit instead
#
# t::Data::Str2Num;
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
   Test::Tech->import( qw(finish is_skip ok ok_sub plan skip 
                          skip_sub skip_tests tech_config) );
   plan(tests => 13);

}


END {
 
   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @lib::ORIG_INC;
   chdir $__restore_dir__;
}




   # Perl code from C:
    use File::Package;
    my $fp = 'File::Package';

    my $uut = 'Data::Str2Num';
    my $loaded;
    my ($result,@result); # force a context;

   # Perl code from C:
my $errors = $fp->load_package($uut, 'str2float','str2int','str2integer',);


####
# verifies requirement(s):
# L<DataPort::DataFile/general [1] - load>
# 

#####
skip_tests( 1 ) unless
  skip( $loaded, # condition to skip test   
      $errors, # actual results
      '', # expected results
      "",
      "Load UUT");

#  ok:  1

ok(  $uut->str2int('033'), # actual results
     27, # expected results
     "",
     "str2int(\'033\')");

#  ok:  2

ok(  $uut->str2int('0xFF'), # actual results
     255, # expected results
     "",
     "str2int(\'0xFF\')");

#  ok:  3

ok(  $uut->str2int('0b1010'), # actual results
     10, # expected results
     "",
     "str2int(\'0b1010\')");

#  ok:  4

ok(  $uut->str2int('255'), # actual results
     255, # expected results
     "",
     "str2int(\'255\')");

#  ok:  5

ok(  $uut->str2int('hello'), # actual results
     undef, # expected results
     "",
     "str2int(\'hello\')");

#  ok:  6

ok(  $result = $uut->str2integer(1E20), # actual results
     undef, # expected results
     "",
     "str2integer(1E20)");

#  ok:  7

   # Perl code from C:
my ($strings, @numbers) = str2integer(' 78 45 25', ' 512E4 1024 hello world');

ok(  [@numbers], # actual results
     [78,45,25,], # expected results
     "",
     "str2integer(' 78 45 25', ' 512E4 1024 hello world') \@numbers");

#  ok:  8

ok(  join( ' ', @$strings), # actual results
     '512E4 1024 hello world', # expected results
     "",
     "str2integer(' 78 45 25', ' 512E4 1024 hello world') \@strings");

#  ok:  9

   # Perl code from C:
($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025  0', ' 512E4 hello world');

ok(  [@numbers], # actual results
     [[78,1], [-24,-6], [25,-3], [0, -1], [512,6]], # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') numbers");

#  ok:  10

ok(  join( ' ', @$strings), # actual results
     'hello world', # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0', ' 512E4 hello world') \@strings");

#  ok:  11

   # Perl code from C:
($strings, @numbers) = str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1});

ok(  [@numbers], # actual results
     ['78','-2.4E-6','0.0025','255','63','0','512E4'], # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) numbers");

#  ok:  12

ok(  join( ' ', @$strings), # actual results
     'hello world', # expected results
     "",
     "str2float(' 78 -2.4E-6 0.0025 0xFF 077 0', ' 512E4 hello world', {ascii_float => 1}) \@strings");

#  ok:  13


    finish();

__END__

=head1 NAME

Str2Num.t - test script for Data::Str2Num

=head1 SYNOPSIS

 Str2Num.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Str2Num.t uses this option to redirect the test results 
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

