#!perl
#
#
use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '0.03';   # automatically generated file
$DATE = '2004/05/14';
$FILE = __FILE__;


##### Test Script ####
#
# Name: TarGzip.t
#
# UUT: Archive::TarGzip
#
# The module Test::STDmaker generated this test script from the contents of
#
# t::Archive::TarGzip;
#
# Don't edit this test script file, edit instead
#
# t::Archive::TarGzip;
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
   plan(tests => 12);

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
    use File::AnySpec;
    use File::SmartNL;
    use File::Spec;
    use File::Path;

    my $fp = 'File::Package';
    my $snl = 'File::SmartNL';
    my $uut = 'Archive::TarGzip'; # Unit Under Test
    my $loaded;

ok(  $loaded = $fp->is_package_loaded($uut), # actual results
      '', # expected results
     "",
     "UUT not loaded");

#  ok:  1

   # Perl code from C:
my $errors = $fp->load_package($uut);

skip_tests( 1 ) unless
  skip( $loaded, # condition to skip test   
      $errors, # actual results
      '', # expected results
      "",
      "Load UUT");

#  ok:  2

   # Perl code from C:
     my @files = qw(
         lib/Data/Str2Num.pm
         lib/Docs/Site_SVD/Data_Str2Num.pm
         Makefile.PL
         MANIFEST
         README
         t/Data/Str2Num.d
         t/Data/Str2Num.pm
         t/Data/Str2Num.t
     );
     my $file;
     foreach $file (@files) {
         $file = File::AnySpec->fspec2os( 'Unix', $file );
     }
     my $src_dir = File::Spec->catdir('TarGzip', 'expected');

    unlink 'TarGzip.tar.gz';
    rmtree (File::Spec->catfile('TarGzip', 'Data-Str2Num-0.02'));

ok(  Archive::TarGzip->tar( @files, {tar_file => 'TarGzip.tar.gz', src_dir  => $src_dir,
            dest_dir => 'Data-Str2Num-0.02', compress => 1} ), # actual results
     'TarGzip.tar.gz', # expected results
     "",
     "tar files into compressed archive");

#  ok:  3

ok(  Archive::TarGzip->untar( {dest_dir=>'TarGzip', tar_file=>'TarGzip.tar.gz', compress => 1, umask => 0} ), # actual results
     1, # expected results
     "",
     "Untar compressed archive");

#  ok:  4

   # Perl code from C:
foreach $file (@files) {;

ok(  $snl->fin(File::Spec->catfile('TarGzip', 'Data-Str2Num-0.02', $file), {binary => 1}), # actual results
     $snl->fin(File::Spec->catfile('TarGzip', 'expected', $file), {binary => 1}), # expected results
     "",
     "Compare $file");

#  ok:  5,6,7,8,9,10,11,12

   # Perl code from C:
};

   # Perl code from C:
unlink 'TarGzip.tar.gz';
    rmtree (File::Spec->catfile('TarGzip', 'Data-Str2Num-0.02'));


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

TarGzip.t - test script for Archive::TarGzip

=head1 SYNOPSIS

 TarGzip.t -log=I<string>

=head1 OPTIONS

All options may be abbreviated with enough leading characters
to distinguish it from the other options.

=over 4

=item C<-log>

TarGzip.t uses this option to redirect the test results 
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

