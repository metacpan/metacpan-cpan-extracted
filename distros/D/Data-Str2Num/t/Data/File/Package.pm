#!perl
#
# Documentation, copyright and license is at the end of this file.
#

package  File::Package;

use 5.001;
use strict;
use warnings;
use warnings::register;

use vars qw($VERSION $DATE $FILE);
$VERSION = '1.17';
$DATE = '2004/05/19';
$FILE = __FILE__;

use File::Spec;

use vars qw(@ISA @EXPORT_OK);
require Exporter;
@ISA= qw(Exporter);
@EXPORT_OK = qw(load_package is_package_loaded eval_str);
use vars qw(@import);

# use SelfLoader;

# 1;

# __DATA__


######
#
#
sub load_package
{

     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift if UNIVERSAL::isa($_[0],__PACKAGE__);
     local @import;

     (my $program_module, @import) = @_;
     return  "# The package name is empty. There is no package to load.\n"
         unless ($program_module); 

     my $packages = $import[-1] && ref($import[-1]) eq 'ARRAY' ? pop @import : [$program_module];
        
     my $error = '';
     my $restore_warn = $SIG{__WARN__};
     my $restore_croak = \&Carp::croak;
     my $restore_carp = \&Carp::crap;
     unless (File::Package->is_package_loaded( $program_module )) {

         #####
         # Load the module
         #
         # On error when evaluating "require $program_module" only the last
         # line of STDERR, at least on one Perl, is return in $@.
         # Save the entire STDERR to a memory variable by using eval_str
         #
         $error = eval_str ("require $program_module;");
         return "Cannot load $program_module\n\t" . $error if $error;

         #####
         # Verify the package vocabulary is present
         #
         my @package_names = ();
         foreach (@$packages) { 
             push @package_names, $_ unless File::Package->is_package_loaded($_, $program_module );
         }
         return "# $program_module file but package(s) " . (join ',',@package_names) . " absent.\n"
              if @package_names;
     }

     ####
     # Import flagged symbols from load package into current package vocabulary.
     #
     if( @import ) {

         ####
         # Import does not work correctly when running under eval. Import
         # uses the caller stack to determine way to stuff the symbols.
         # The eval messes with the stack. Since not using an eval, need
         # to double check to make sure import does not die.
         
         ####
         # Poor man's eval where trap off the Carp::croak function.
         # The Perl authorities have Core::die locked down tight so
         # it is next to impossible to trap off of Core::die. Lucky 
         # must everyone uses Carp::croak instead of just dieing.
         #
         # Anyway, get the benefit of a lot of stack gyrations to
         # formulate the correct error msg by Exporter::import.
         # 
         $error = '';
         no warnings;
         *Carp::carp = sub {
             $error .= (join '', @_);
             $error .= "\n" unless substr($error,-1,1) eq "\n";
         };
         *Carp::croak = sub {
             $error .= Carp::longmess (join '', @_) if $error;
             $error .= "\n" unless substr($error,-1,1) eq "\n";
             goto IMPORT; # once croak can not continue
         };
         use warnings;
         local $Exporter::ExportLevel = 1;
         if(@import == 1 && defined $import[0] && $import[0] eq '') {
             $program_module->import( );
         }
         else {
             $program_module->import( @import );
         }
         no warnings;
IMPORT:  
         *Carp::croak = $restore_croak;
         *Carp::carp= $restore_carp;

     }
     $SIG{__WARN__} = ref( $restore_warn ) ? $restore_warn : '';
     return $error;
}




#####
# Many times, all the warnings do not get into the $@ string
#
sub eval_str
{
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);
     my ($str) = @_;

     my $restore_warn = $SIG{__WARN__};
     my $error_msg = '';
     $SIG{__WARN__} = sub { $error_msg .= join '', @_; };
     eval $str;
     $SIG{__WARN__} = ref( $restore_warn ) ? $restore_warn : '';

     $error_msg = $@ . $error_msg if $@;
     $error_msg =~ s/\n/\n\t/g if $error_msg;
     $error_msg;
}


######
#
#
sub is_package_loaded
{
     ######
     # This subroutine uses no object data; therefore,
     # drop any class or object.
     #
     shift @_ if UNIVERSAL::isa($_[0],__PACKAGE__);

     my ($package, $program_module) = @_;
   
     my $package_hash = $package . "::";
     my $vocabulary = defined %$package_hash;
     my $version = $package . "::VERSION";
     no strict;
     $version = $$version;
     use strict;
     $vocabulary &&= $version && 0 < length($version);
    
     $program_module = $package unless $program_module;
     my $require = File::Spec->catfile( split /::/, $program_module . '.pm');
     my $inc = $INC{$require};

     ####
     # Microsoft cannot make up its mind to use
     # Microsoft \ or Unix / for path separator.
     # 
     # Just in case, running Microsoft, delete
     # Unix mirror name for the file
     #
     my $OS = $^O; 
     unless ($OS) {   # on some perls $^O is not defined
         require Config;
	 $OS = $Config::Config{'osname'};
     } 
     $require =~ s|\\|/|g if $OS eq 'MSWin32';; 
     $inc = $inc || $INC{$require};
     ($vocabulary && $inc) ? 1 : '';
}


1


__END__


=head1 NAME

File::Package - test load a pm and import symbols without eval and $@ misbehavoirs

=head1 SYNOPSIS

 ##########
 # Subroutine interface
 #
 use File::Package qw(is_package_loaded load_package);

 $error = eval_str( $str );

 $yes = is_package_loaded($package, $program_module);

 $error   = load_package($program_module);
 $error   = load_package($program_module, @import);
 $error   = load_package($program_module, [@package_list]);
 $error   = load_package($program_module, @import, [@package_list]);

 ##########
 # Class Interface
 # 
 use File::Package;

 $yes = is_package_loaded($package, $program_module);

 $error   = File::Package->load_package($program_module);
 $error   = File::Package->load_package($program_module, @import);
 $error   = File::Package->load_package($program_module, [@package_list]);
 $error   = File::Package->load_package($program_module, @import, [@package_list]);

 # Note: [@pakage_list] are the same \@package_list to a subroutine

=head1 DESCRIPTION

In a perfect Perl, everything would behave exactly the same
running under C<eval>. 
Many times the reason to use an C<eval> is the anticipation
that the expression may die. 
When that happens, a perfect Perl would have deposited all the output
from the C<warn> and C<die> in C<$@>.
Maybe you have a perfect Perl. 
However, it is shocking that there are some Perls on some platforms out in the wild
that are mutants and are not perfect. 

A C<require> under eval works just fine just to see if a program
will load or not. If working locally, you can simply devise
a quick debug setup and track down the problem. 
However, when running tests remotely, on different remote 
platforms, running continuously unattended where uptime is important,
or any number of situations it is very helpful to have
meaningful error messages when a problem arise.

Thus, the reason to run under C<eval> is not only to avoid
the C<die> but also to pick up the error message
returned by C<eval> in C<$@>.
In certain situations it is extremely critical to obtain reliable error
messages when a failure occurs.

Well, a C<eval "require $program_module"> failure returns a reasonble
looking C<$@> except for one small thing.
Not all the warnings make it to C<$@> at least on one Perl,
probably more. 
And there can be quite a few warnings when loading a broken program module.
It would be nice if everyone could update to a Perl where the
C<eval> deposits all the warnings in C<$@>.
But as the acient proverb says, "If wishes were horses, beggers would ride.".

One workaround is to catch the warnings with C<$SIG{__WARN__}>
when running the C<require> under a C<eval>.
This collects all the warnings which is good. Now when a load fails, the
program does not die, it gracefully collects all the warnings and
logs them or ships back.

Now try the C<import> under C<eval> and pick up the error messages.
The C<import> and C<eval> is big time "failure to communicate" aka
the movie "Cool Hand Luke". 
The C<import> uses the caller stack to determine where to stuff the symbols
and there is a lot of C<Carp> C<croak> gyrations such as making C<import>
look like C<use>, trapping C<warnings> and C<dies>.
The C<eval> takes off on its own caller stack which
to quote President Bush: "is not helpful".

The C<import> uses the C<croak> instead of C<die> directly or
else any efforts to get meaningfull error messages
would be dead on arrival.
Perl is designed so that it is nearly impossible to avoid a
die unless running under a C<eval>. 
A workaround is hooking in a C<croak> that does not die and collecting
the error messages.

=head1 SUBROUTINES

=head2 eval_str

 $error = eval_str( $str );

Runs C<$str> using C<eval>, trapping all the warnings from C<eval> and
returning them as C<$error>.

=head2 is_package_loaded

 $package = is_package_loaded($program_module, $package)

The C<is_package_loaded> subroutine determines if the C<$package>
is present and the C<$progarm_module> loaded. 
If C<$package> is absent, 0 or '', C<$package> is set to the 
C<program_module>.

=head2 load_package

  $error = load_package($program_module, @import, [@package_list]);

The C<load_package> subroutine attempts to capture any load problems by
loading the package with a "require " under an eval and capturing
all the "warn" and $@ messages. 

If the C<$program_module> load is successful, 
the checks that the packages in the @package list are present.
If @package list is absent, the C<$program_module> uses
the C<program_module> name as a list of one package.
Although a program module and package have the same name
syntax, they are entirely different.
A program module is a file. 
A package is a hash of symbols, a symbol table.
The Perl convention is that the names for each are the same
which enhances the appearance that they are the same
when in fact they are different.
Thus, a program module may have a single package
with a different name or many different packages.

Finally the C<$program_module> subroutine will import the symbols
in the C<@import> list.
If C<@import> is absent C<$program_module> subroutine does not
import any symbols; if C<@import> is '', all symbols are imported.
A C<@import> of 0 usually results in an C<$error>.

The C<$program_module> traps all load errors and all import
C<Carp::Crock> errors and returns them in the C<$error> string.

One very useful application of the C<load_package> subroutine is in test scripts. 
If a package does load, it is very helpful that the program does
not die and reports the reason the package did not load. 
This information is readily available when loaded at a local site.
However, it the load occurs at a remote site and the load crashes
Perl, the remote tester usually will not have this information
readily available. 

Other applications include using backup alternative software
if a package does not load. For example if the package
'Compress::Zlib' did not load, an attempt may be made
to use the gzip system command. 

=head1 BUGS

The C<load_package> cannot load program modules whose
name contain the '-' characters. 
The 'eval' function used to trap the die errors
believes it means subtraction.

=head1 REQUIREMENTS

Coming.

=head1 DEMONSTRATION

 #########
 # perl Package.d
 ###

 ~~~~~~ Demonstration overview ~~~~~

Perl code begins with the prompt

 =>

The selected results from executing the Perl Code 
follow on the next lines. For example,

 => 2 + 2
 4

 ~~~~~~ The demonstration follows ~~~~~

 =>     use File::Package;
 =>     my $uut = 'File::Package';

 => ##################
 => # Good Load
 => # 
 => ###

 => my $error = $uut->load_package( 'File::Basename' )
 ''

 => $error = $uut->load_package( '_File_::BadLoad' )
 'Cannot load _File_::BadLoad
 	syntax error at E:/User/SoftwareDiamonds/installation/t/File/_File_/BadLoad.pm line 13, near "$FILE "
 	Global symbol "$FILE" requires explicit package name at E:/User/SoftwareDiamonds/installation/t/File/_File_/BadLoad.pm line 13.
 	Compilation failed in require at (eval 12) line 1.
 	Scalar found where operator expected at E:/User/SoftwareDiamonds/installation/t/File/_File_/BadLoad.pm line 13, near "$FILE"
 		(Missing semicolon on previous line?)
 	'

 => $uut->load_package( '_File_::BadPackage' )
 '# _File_::BadPackage file but package(s) _File_::BadPackage absent.
 '

 => $uut->load_package( '_File_::Multi' )
 '# _File_::Multi file but package(s) _File_::Multi absent.
 '

 => $error = $uut->load_package( '_File_::Hyphen-Test' )
 'Cannot load _File_::Hyphen-Test
 	syntax error at (eval 15) line 1, near "require _File_::Hyphen-"
 	Warning: Use of "require" without parens is ambiguous at (eval 15) line 1.
 	'

 => ##################
 => # No &File::Find::find import baseline
 => # 
 => ###

 => !defined($main::{'find'})
 '1'

 => ##################
 => # Load File::Find, Import &File::Find::find
 => # 
 => ###

 => $error = $uut->load_package( 'File::Find', 'find', ['File::Find'] )
 ''

 => ##################
 => # &File::Find::find imported
 => # 
 => ###

 => defined($main::{'find'})
 '1'

 => ##################
 => # &File::Find::finddepth not imported
 => # 
 => ###

 => !defined($main::{'finddepth'})
 '1'

 => ##################
 => # Import error
 => # 
 => ###

 => $uut->load_package( 'File::Find', 'Jolly_Green_Giant')
 '"Jolly_Green_Giant" is not exported by the File::Find module
 Can't continue after import errors at D:/Perl/lib/Exporter/Heavy.pm line 127
 	Exporter::heavy_export('File::Find', 'main', 'Jolly_Green_Giant') called at D:/Perl/lib/Exporter.pm line 45
 	Exporter::import('File::Find', 'Jolly_Green_Giant') called at (eval 9) line 81
 	File::Package::load_package('File::Package', 'File::Find', 'Jolly_Green_Giant') called at E:\User\SoftwareDiamonds\installation\t\File\Package.d line 195
 '

 => ##################
 => # &File::Find::finddepth still no imported
 => # 
 => ###

 => !defined($main::{'finddepth'})
 '1'

 => ##################
 => # Import all File::Find functions
 => # 
 => ###

 => $error = $uut->load_package( 'File::Find', '')
 ''

 => ##################
 => # &File::Find::finddepth imported
 => # 
 => ###

 => defined($main::{'finddepth'})
 '1'


=head1 QUALITY ASSURANCE

Running the test script C<package.t> verifies
the requirements for this module.

The <tmake.pl> cover script for L<Test::STDmaker|Test::STDmaker>
automatically generated the
C<package.t> test script, C<package.d> demo script,
and C<t::File::Package> STD program module POD,
from the C<t::File::Package> program module contents.
The  C<t::File::Package> program module
is in the distribution file
F<File-Package-$VERSION.tar.gz>.

=head1 NOTES

=head2 Author

The holder of the copyright and maintainer is

E<lt>support@SoftwareDiamonds.comE<gt>

=head2 Copyright Notice

Copyrighted (c) 2002 Software Diamonds

All Rights Reserved

=head2 Binding Requirements Notice

Binding requirements are indexed with the
pharse 'shall[dd]' where dd is an unique number
for each header section.
This conforms to standard federal
government practices, L<STD490A 3.2.3.6|Docs::US_DOD::STD490A/3.2.3.6>.
In accordance with the License, Software Diamonds
is not liable for any requirement, binding or otherwise.

=head2 License

Software Diamonds permits the redistribution
and use in source and binary forms, with or
without modification, provided that the 
following conditions are met: 

=over 4

=item 1

Redistributions of source code must retain
the above copyright notice, this list of
conditions and the following disclaimer. 

=item 2

Redistributions in binary form must 
reproduce the above copyright notice,
this list of conditions and the following 
disclaimer in the documentation and/or
other materials provided with the
distribution.

=item 3

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


=back

SOFTWARE DIAMONDS, http://www.softwarediamonds.com,
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

=head1 SEE ALSO

=over 4

=item L<Docs::Site_SVD::File_Package|Docs::Site_SVD::File_Package>

=item L<Test::STDmaker|Test::STDmaker> 

=back

=cut

### end of file ###