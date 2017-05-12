#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.01';   # automatically generated file
$DATE = '2003/08/04';
$FILE = __FILE__;

use Test::Tech;
use Getopt::Long;
use Cwd;
use File::Spec;
use File::TestPath;

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
   use vars qw( $__restore_dir__ @__restore_inc__);

   ########
   # Working directory is that of the script file
   #
   $__restore_dir__ = cwd();
   my ($vol, $dirs, undef) = File::Spec->splitpath(__FILE__);
   chdir $vol if $vol;
   chdir $dirs if $dirs;

   #######
   # Add the library of the unit under test (UUT) to @INC
   #
   @__restore_inc__ = File::TestPath->test_lib2inc();

   unshift @INC, File::Spec->catdir( cwd(), 'lib' ); 

   ##########
   # Pick up a output redirection file and tests to skip
   # from the command line.
   #
   my $test_log = '';
   GetOptions('log=s' => \$test_log);

   ########
   # Create the test plan by supplying the number of tests
   # and the todo tests
   #
   require Test::Tech;
   Test::Tech->import( qw(plan ok skip skip_tests tech_config) );
   plan(tests => 7);

}



END {

   #########
   # Restore working directory and @INC back to when enter script
   #
   @INC = @__restore_inc__;
   chdir $__restore_dir__;
}

   # Perl code from C:
    use File::Package;
    my $fp = 'File::Package';

    my $s2n = 'Data::Str2Num';
    my $loaded;

ok(  $loaded = $fp->is_package_loaded($s2n), # actual results
      '', # expected results
     '',
     'UUT not loaded');

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($s2n);


####
# verifies requirement(s):
# L<DataPort::DataFile/general [1] - load>
# 

#####
skip_tests( 1 ) unless skip(
      $loaded, # condition to skip test   
      $errors, # actual results
      '',  # expected results
      '',
      'Load UUT');
 
#  ok:  2

ok(  $s2n->str2int('033'), # actual results
     27, # expected results
     '',
     'num2dec(\'033\')');

#  ok:  3

ok(  $s2n->str2int('0xFF'), # actual results
     255, # expected results
     '',
     'num2dec(\'0xFF\')');

#  ok:  4

ok(  $s2n->str2int('0b1010'), # actual results
     10, # expected results
     '',
     'num2dec(\'0b1010\')');

#  ok:  5

ok(  $s2n->str2int('255'), # actual results
     255, # expected results
     '',
     'num2dec(\'255\')');

#  ok:  6

ok(  $s2n->str2int('hello'), # actual results
     undef, # expected results
     '',
     'num2dec(\'hello\')');

#  ok:  7


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

=cut

## end of test script file ##

