package Alien::TinyCCx;

use strict;
use warnings;

# Follow Golden's Version Rule: http://www.dagolden.com/index.php/369/version-numbers-should-be-boring/
our $VERSION = "0.12";
$VERSION = eval $VERSION;

use File::ShareDir;
use File::Spec;
use Env qw( @PATH );
use Carp;
use Config;

###################################
# Find the Distribution Directory #
###################################

# The prefix will depend on whether or not the thing was finally installed.
# The easiest way to know that is if *this* *module* *file* is in a blib
# directory or not:
my $dist_dir;

my $mod_path = $INC{'Alien/TinyCCx.pm'};
if ($mod_path =~ s/(.*)blib.*/$1share/) {
	$dist_dir = $mod_path;
	croak('Looks like Alien::TinyCCx is being invoked from blib, but I cannot find build-time sharedir!')
		unless -d $dist_dir;
}
else {
	$dist_dir = File::ShareDir::dist_dir('Alien-TinyCCx');
}

############################
# Path retrieval functions #
############################

# First we need to find a number of files of interest. Rather than guess
# at these files' locations, we can perform a simple search for them
# and store the locations that we find.
my %files_to_find = (
	bin => 'tcc',
	lib => 'libtcc.',
	inc => 'libtcc.h'
);
if ($^O =~ /MSWin/) {
	$files_to_find{bin} .= '.exe';
	$files_to_find{lib} .= 'dll';
}
else {
	$files_to_find{lib} .= 'a';
}
my %path_for_file;

# Otherwise go through all dirs and subdirs of dist_dir
my @dirs = $dist_dir;
while (@dirs) {
	# Pull the next directory off the list
	my $dir = shift @dirs;
	
	# Check if any of the unfound files are in this directory
	for my $file_type (keys %files_to_find) {
		if (-f File::Spec->catfile($dir, $files_to_find{$file_type})) {
			delete $files_to_find{$file_type};
			$path_for_file{$file_type} = $dir;
		}
	}
	
	# Otherwise, scan this directory for subdirectories
	opendir (my $dh, $dir) or next;
	CHILD: for my $child (readdir $dh) {
		next CHILD if $child =~ /^\./; # skip dot-files and dot-dirs
		my $full_path = File::Spec->catdir($dir, $child);
		push @dirs, $full_path if -d $full_path;
	}
	close $dh;
}

# Find the path to the tcc executable
sub path_to_tcc { $path_for_file{bin} }

# Modify the PATH environment variable to include tcc's directory
unshift @PATH, path_to_tcc();

# Find the path to the compiled libraries. Note that this is only applicable
# on Unixish systems; Windows simply uses the %PATH%, which was already
# appropriately set.
sub libtcc_library_path { $path_for_file{lib} }

# Add library path on Unixish:
if ($ENV{LD_LIBRARY_PATH}) {
	$ENV{LD_LIBRARY_PATH} = libtcc_library_path() . ':' . $ENV{LD_LIBRARY_PATH};
}
elsif ($^O !~ /MSWin/) {
	$ENV{LD_LIBRARY_PATH} = libtcc_library_path();
}

# Determine path for libtcc.h
sub libtcc_include_path { $path_for_file{inc} }

###########################
# Module::Build Functions #
###########################

sub MB_linker_flags {
	return ('-L' . libtcc_library_path, '-ltcc');
}

#################################
# ExtUtils::MakeMaker Functions #
#################################

sub EUMM_LIBS {
	return (LIBS => ['-L' . libtcc_library_path . '\libtcc -ltcc']) if $^O =~ /MSWin/;
	return;
}

sub EUMM_OBJECT {
	return OBJECT => '$(O_FILES)' if $^O =~ /MSWin/;
	return OBJECT => '$(O_FILES) ' . File::Spec->catdir(libtcc_library_path, 'libtcc'.$Config{lib_ext}),
}

# version

1;

__END__

=head1 NAME

Alien::TinyCCx - retrieve useful information about the Alien installation of tcc with
extended symbol tables

=head1 ALIEN SYNOPSIS

 use Alien::TinyCCx;
 
 
 ## libtcc location functions ##
 
 say 'The libtcc headers can be found in ',
     Alien::TinyCCx->libtcc_include_path;
 say 'The libtcc library can be found in ',
     Alien::TinyCCx->libtcc_library_path;
 
 
 ## tcc functions ##
 
 say 'The tcc executable can be found in ',
     Alien::TinyCCx->path_to_tcc;
 
 # Create a C file
 open my $out_fh, '>', 'test.c';
 print $out_fh <<'EOF';
 #include <stdio.h>
 
 int main() {
     printf("Good to go");
     return 1;
 }
 
 EOF
 close $out_fh;
 
 # Alien::TinyCCx ensures that the tcc executable is
 # in your PATH environment variable, so this Just Works:
 my $output = `tcc -run test.c`;

=head1 XS SYNOPSIS

If you want to build against F<libtcc>, then in your F<Build.PL> file you
should have something like this:

 use Module::Build;
 use Alien::TinyCCx;
 Module::Build->new(
     ...
	 configure_requires => {
         'Alien::TinyCCx' => 0,
         ...
	 },
     build_requires => {
         'Alien::TinyCCx' => 0,
         ...
     },
     requires => {
         'Alien::TinyCCx' => 0,
         ...
     },
     needs_compiler => 1,
     dynamic_config => 1,
     include_dirs => [Alien::TinyCCx->libtcc_include_path],
     extra_linker_flags => [Alien::TinyCCx->MB_linker_flags],
 )->create_build_script

At the top of the Perl module that provides the Perl libtcc interface:

 # My/C/Tiny/Interface.pm
 use Alien::TinyCCx;  # set LD_LIBRARY_PATH, PATH, etc
 
 BEGIN {
     our $VERSION = '0.02';
     use XSLoader;
     XSLoader::load 'My::C::Tiny::Interface', $VERSION;
 }

In your XS file that interfaces with libtcc:

 /* Usual Perl XS suspects */
 #include "EXTERN.h"
 #include "perl.h"
 #include "XSUB.h"
 #include "ppport.h"
 
 /* This is the important one */
 #include "libtcc.h"

=head1 DESCRIPTION

This module ensures that you have a copy of the Tiny C Compiler with
extended symbol table management accessible
to your Perl code, ensures that F<tcc> is in your path after saying
C<use Alien::TinyCCx>, ensures that F<libtcc> is in your C<LD_LIBRARY_PATH>
for Unixen and C<PATH> for Windows, and provides some functions for
identifying those paths and building against them.

This module is blissfully unaware of any other F<tcc> installations on your
system and it does not install F<tcc> into a generically usable location.
Rather, it installs it into a Perl-specific location. The basic idea is that
this Perl module should not interfere with your non-Perl stuff.

The provided path functions include:

=over

=item path_to_tcc

gives the full path to the directory containing the F<tcc> executable

=item libtcc_include_path

gives the full path to the diretory containing F<libtcc.h>

=item libtcc_library_path

gives the full path to the directory containing F<libtcc.dll> or F<libtcc.a>

=back

If you want to link against F<libtcc>, you will need to include C<Alien::TinyCC>
in your F<.pm> file that loads your XS bindings, to ensure that the
C<PATH> or C<LD_LIBRARY_PATH> is properly set. Then, in your F<Build.PL>
file, you can use

=over

=item MB_linker_flags

gives the proper list of arguments to link against F<libtcc>.

=back

=head1 SEE ALSO

This module provides the Tiny C Compiler. To learn more about this great
project, see L<http://bellard.org/tcc/> and
L<http://savannah.nongnu.org/projects/tinycc>.

To learn more about Alien Perl distributions in general, read the L<Alien>
manifesto.

This library was built to distributed my fork of the Tiny C Compiler with
extended symbol tables, which I needed to implement L<C::Blocks>.

This library is based on C<Alien::TinyCC>.

=head1 AUTHOR

David Mertens (dcmertens.perl@gmail.com)

=head1 BUGS

Please report any bugs or feature requests for the Alien bindings at the
project's main github page:
L<http://github.com/run4flat/Alien-TinyCCx/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Alien::TinyCCx

You can also look for information at:

=over 4

=item * The Github issue tracker (report bugs here)

L<http://github.com/run4flat/Alien-TinyCCx/issues>

=item * My fork or TCC packaged with this distribution

L<http://github.com/run4flat/tinycc>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Alien-TinyCCx>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Alien-TinyCCx>

=item * Search CPAN

L<http://p3rl.org/Alien::TinyCCx>
L<http://search.cpan.org/dist/Alien-TinyCCx/>

=item * Stack Overflow

L<//http://stackoverflow.com/questions/tagged/tcc>

=back

=head1 ACKNOWLEDGEMENTS

The tcc developers have made this a very easy project to wrap up. They even
had the Windows install command nicely packaged up! How amazing!

=head1 LICENSE AND COPYRIGHT

Code copyright 2013, 2015 Dickinson College. Documentation copyright 2013, 2015 David
Mertens.

Everything not contained in the F<src/> directory is free software, the
distribution and/or modification of which is governed by the terms of
either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=head1 TINY C COMPILER LICENSE AND COPYRIGHT

This distribution distributes the source for the Tiny C Compiler project
under the src/ directory, for which the following notice is in effect:

 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
 * THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.

=cut
