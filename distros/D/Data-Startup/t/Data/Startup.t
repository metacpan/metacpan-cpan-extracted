#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.02';   # automatically generated file
$DATE = '2004/05/27';
$FILE = __FILE__;


##### Test Script ####
#
# Name: Startup.t
#
# UUT: Data::Startup
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Data::Startup;
#
# Don't edit this test script file, edit instead
#
# t::Data::Startup;
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
   plan(tests => 18);

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
    my $uut = 'Data::Startup';

    my ($result,@result); # provide scalar and array context
    my ($default_options,$options) = ('$default_options','$options');



   # Perl code from QC:
my $expected1 = 
'U1[1] 80
L[10]
  A[13] Data::Startup
  A[4] HASH
  A[14] Data::SecsPack
  L[2]
    A[0]
    A[4] HASH
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[9] multicell
  A[4] type
  A[5] ascii
';



my $expected2 = 
'U1[1] 80
L[10]
  A[13] Data::Startup
  A[4] HASH
  A[14] Data::SecsPack
  L[2]
    A[0]
    A[4] HASH
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[9] multicell
  A[4] type
  A[6] binary
';

my $expected3 = 
'U1[1] 80
L[10]
  A[13] Data::Startup
  A[4] HASH
  A[14] Data::SecsPack
  L[2]
    A[0]
    A[4] HASH
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[6] strict
  A[4] type
  A[6] binary
';

my $expected4 = 
'U1[1] 80
L[10]
  A[13] Data::Startup
  A[4] HASH
  A[14] Data::SecsPack
  L[4]
    A[0]
    A[4] HASH
    A[23] decimal_fraction_digits
    N 30
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[6] strict
  A[4] type
  A[6] binary
';


my $expected5 = 
'U1[1] 80
L[10]
  A[0]
  A[4] HASH
  A[14] Data::SecsPack
  L[2]
    A[0]
    A[4] HASH
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[9] multicell
  A[4] type
  A[5] ascii
';


my $expected6 = 
'U1[1] 80
L[10]
  A[0]
  A[4] HASH
  A[14] Data::SecsPack
  L[2]
    A[0]
    A[4] HASH
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[9] multicell
  A[4] type
  A[6] binary
';

my $expected7 = 
'U1[1] 80
L[10]
  A[0]
  A[4] HASH
  A[14] Data::SecsPack
  L[4]
    A[0]
    A[4] HASH
    A[23] decimal_fraction_digits
    N 30
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[9] multicell
  A[4] type
  A[5] ascii
';


my $expected8 = 
'U1[1] 80
L[10]
  A[0]
  A[4] HASH
  A[14] Data::SecsPack
  L[2]
    A[0]
    A[4] HASH
  A[6] indent
  A[0]
  A[17] perl_secs_numbers
  A[6] strict
  A[4] type
  A[5] ascii
';




####
# verifies requirement(s):
# L<DataPort::DataFile/general [1] - load>
# 

#####
skip_tests( 1 ) unless
  ok(  File::Package->load_package($uut), # actual results
     '', # expected results
     "",
     "UUT loaded");

#  ok:  1

ok(  ($default_options = new $uut(
       perl_secs_numbers => 'multicell',
       type => 'ascii',   
       indent => '',
       'Data::SecsPack' => {}
   )), # actual results
     $expected1, # expected results
     "",
     "create a Data::Startup default options");

#  ok:  2

ok(  [$default_options->config('perl_secs_numbers')], # actual results
     ['perl_secs_numbers','multicell'], # expected results
     "",
     "read perl_secs_numbers default option");

#  ok:  3

ok(  [$default_options->config(perl_secs_numbers => 'strict')], # actual results
     ['perl_secs_numbers','multicell'], # expected results
     "",
     "write perl_secs_numbers default option");

#  ok:  4

ok(  [$default_options->config(perl_secs_numbers => 'multicell')], # actual results
     ['perl_secs_numbers','strict'], # expected results
     "",
     "restore perl_secs_numbers default option");

#  ok:  5

ok(  $options = $default_options->override(type => 'binary'), # actual results
     $expected2, # expected results
     "",
     "create options copy of default options");

#  ok:  6

ok(  $default_options, # actual results
     $expected1, # expected results
     "",
     "verify default options unchanged");

#  ok:  7

ok(  [@result = $options->config([perl_secs_numbers => 'strict'])], # actual results
     ['perl_secs_numbers','multicell'], # expected results
     "",
     "array reference option config");

#  ok:  8

ok(  $options, # actual results
     $expected3, # expected results
     "",
     "array reference option config");

#  ok:  9

ok(  [@result = $options->config({'Data::SecsPack'=> {decimal_fraction_digits => 30} })], # actual results
     ['Data::SecsPack',{}], # expected results
     "",
     "hash reference option config");

#  ok:  10

ok(  $options, # actual results
     $expected4, # expected results
     "",
     "hash reference option config");

#  ok:  11

ok(  $default_options, # actual results
     $expected1, # expected results
     "",
     "verify default options still unchanged");

#  ok:  12

   # Perl code from C:
  my %default_hash = (
       perl_secs_numbers => 'multicell',
       type => 'ascii',   
       indent => '',
       'Data::SecsPack' => {}
   );



ok(  $default_options = \%default_hash, # actual results
     $expected5, # expected results
     "",
     "create a hash default options");

#  ok:  13

ok(  Data::Startup::override($default_options, type => 'binary'), # actual results
     $expected6, # expected results
     "",
     "override default_hash with an option array");

#  ok:  14

ok(  Data::Startup::override($default_options, {'Data::SecsPack'=> {decimal_fraction_digits => 30}}), # actual results
     $expected7, # expected results
     "",
     "override default_hash with a reference to a hash");

#  ok:  15

ok(  Data::Startup::override($default_options, [perl_secs_numbers => 'strict']), # actual results
     $expected8, # expected results
     "",
     "override default_hash with a reference to an array");

#  ok:  16

ok(  [@result = Data::Startup::config($default_options, [perl_secs_numbers => 'strict'])], # actual results
     ['perl_secs_numbers', 'multicell'], # expected results
     "",
     "return from config default_hash with a reference to an array");

#  ok:  17

ok(  $default_options, # actual results
     $expected8, # expected results
     "",
     "default_hash from config default_hash with a reference to an array");

#  ok:  18


    finish();

__END__

=head1 NAME

Startup.t - test script for Data::Startup

=head1 SYNOPSIS

 Startup.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

Startup.t uses this option to redirect the test results 
from the standard output to a log file.

=back

=head1 COPYRIGHT

copyright © 2004 Software Diamonds.

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

=cut

## end of test script file ##

