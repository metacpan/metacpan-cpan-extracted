package C::Scan::Constants;

use 5.008003;
use strict;
use warnings;
use Carp;

use ExtUtils::Constant;
use ModPerl::CScan;
use File::Temp qw( tempdir );
use File::Copy;
use File::Spec;
use File::Path;
use Data::Dumper;
use IO::File;
use Config;

require Exporter;

our @ISA = qw(Exporter);

# Our functions are pretty uniquely named, and intended for
# calling from Makefile.PL, so we simply export them be default.
our @EXPORT      = qw( extract_constants_from
                       write_constants_module );

our %EXPORT_TAGS = ( 'all' => [ @EXPORT ] );
our @EXPORT_OK   = ( @{ $EXPORT_TAGS{'all'} } );

our $VERSION = "1.020";
$VERSION = eval $VERSION;

# This module was originally written to support a custom pure-Perl
# build system named Blueprint.  If you know of or use Blueprint,
# this section will mean something to you.  If not, ignore it.
my $g_use_blueprint_sections;
BEGIN {
    # Initialize global variable(s)
    $g_use_blueprint_sections = 0;

    eval 'require Blueprint';

    unless ($@) {
        $g_use_blueprint_sections = 1;
    }

    # Now blueprint comment block protection is quietly enabled.
    # This will almost never be turned on.
}

# _get_constant_data_blobs_from()
#
# Internal function.
#
# Returns a two blobs of data from the supplied file:
#   ($defines,   <-- #define macros with no args
#    $typedefs)  <-- #typedef enum constants
sub _get_constant_data_blobs_from {
    my $file_to_relocate = shift;

    if ( ! -f $file_to_relocate ) {
        croak "$file_to_relocate does not appear to be accessible";
    }

    # Create a temp directory here.
    my $temp_scan_dir = tempdir( 'c_scan_const_XXXXX',
                                 DIR     => File::Spec->tmpdir(),
                                 CLEANUP => 1 )
        or die "Internal error: failed to create temp dir";

    # copy the file into it
    my $scan_file_basename = ( File::Spec->splitpath($file_to_relocate) )[2];
    my $relocated_file = File::Spec->catpath( '',
                                              $temp_scan_dir,
                                              $scan_file_basename );
    copy($file_to_relocate, $relocated_file)
        or croak "Could not copy $file_to_relocate to $relocated_file";

    # scan the file
    my $c_header_file = ModPerl::CScan->new( filename => $relocated_file );
    
    if ( !defined( $c_header_file ) ) {
        croak "Could not create ModPerl::CScan obj for $relocated_file";
    }

    # Ugly hack to fix ActivePerl config bomb, i.e. expectation that "cppstdin"
    # is the cpp we'll be using.  This assumes MinGW is installed, which we
    # attempted to enforce in the Makefile.PL.  It probably assumes more than
    # should be safely assumed about the return data structure from Data::Flow,
    # but it seems to work.
    if ( $^O =~ /MSWin/i ) {
        my $cur_cppstdin = $c_header_file->get('Cpp')->{cppstdin};
	my $cur_cc = $Config{cc};
	unless (     $cur_cppstdin =~ /$cur_cc/
	         and $cur_cppstdin =~ /\-E/ ) {
            $c_header_file->get('Cpp')->{cppstdin} = "$cur_cc -E";
	}
    }
    
    # Swallow STDERR temporarily
    open my $OLDERR, ">&", STDERR;
    close(STDERR);

	# Redirect temporarily to the bit bucket, but keep it open
	# to avoid conflicting in a -w environment such as under test.
    # TBD: Make this friendlier for non-*n[u|i]x systems.
    open *STDERR, ">", "/dev/null";

    # We only care about unadorned macros, i.e. "defines"
    my $defs     = $c_header_file->get("defines_no_args");
### These next lines represent possible future functionality ####
#    my $defs2    = $c_header_file->get("defines_maybe");
#    my $defs3    = $c_header_file->get("defines_full");
#    my $defs4    = $c_header_file->get("defines_args");
#    my $defs5    = $c_header_file->get("defines_no_args_full");
#    my $defs6    = $c_header_file->get("Defines");
##################################################################
    my $typedefs = $c_header_file->get("typedef_texts");


### For debugging only ######################################################
### NOTE: need to send STDERR somewhere other than /dev/null for these to
###       work as intended.
###
#    warn sprintf("[$file_to_relocate] defines_no_args = %s", Dumper($defs));
#    warn sprintf("[$file_to_relocate] defines_maybe = %s", Dumper($defs2));
#    warn sprintf("[$file_to_relocate] defines_full = %s", Dumper($defs3));
#    warn sprintf("[$file_to_relocate] defines_args = %s", Dumper($defs4));
#    warn sprintf("[$file_to_relocate] defines_no_args_full = %s", Dumper($defs5));
#    warn sprintf("[$file_to_relocate] Defines = %s", Dumper($defs6));
#    warn sprintf("[$file_to_relocate] enums = %s", Dumper($typedefs));
#############################################################################

    # Restore STDERR and close the temp filehandle for neatness.
    close STDERR;
    open STDERR, ">&", $OLDERR;
	close $OLDERR;

    # Return the file object returned from ModPerl::CScan->new()
    # Note: these may be empty (hashref, arrayref)
    return ($defs, $typedefs);
}




# extract_constants_from()
#
# Exported function.
#
# This function takes a list of C header (.h) files and returns a list
# of constants information suitable for supplying as the NAME parameter
# to ExtUtils::Constant.
sub extract_constants_from {
    my @c_header_paths = @_;         # full paths to each .h file to scan

    my @all_constants;

    C_HEADER_FILE:
    foreach my $c_header_file ( @c_header_paths ) {
        my ($defs,
            $typedefs) = _get_constant_data_blobs_from( $c_header_file );

        if ( ( !defined $defs ||
               (defined $defs && scalar( keys %$defs ) == 0) ) and
             ( !defined $typedefs ||
               (defined $typedefs && scalar @$typedefs == 0) ) ) {
            warn "WARNING: Found no constants in $c_header_file.";
            next C_HEADER_FILE;
        }

        # Do the messy enum extraction
        my @enums = _extract_enum_constants_from( $typedefs );

        # We convert the base filename into something we can use
        # to avoid the error of throwing away the "filename constant"
	# e.g.  #ifndef FOO_H_
	#       #define FOO_H_
	my $all_caps_basename = uc ( ( File::Spec->splitpath($c_header_file) )[2] );
	$all_caps_basename =~ s/[.]/_/g;

        # Consolidate all names found into a single list.
        # Note that we discard string constants.
        my @constant_names = ( @enums,
                               grep {
                                   my $defn = $_;

                                   # Toss header file identifiers, but only
				   # when they are *really* header file identifiers.
                                   ( $defn !~ /_H[_]?$/
				     or ($defn =~ /_H[_]?$/
					 and $all_caps_basename !~ /[_]?$defn[_]?/) )

				   # Toss things ending in underscore (may not
				   # be a good idea, but we'll wait to be convinced...)
                                   and $defn !~ /_$/

                                   # Toss string constants.
                                   and $defs->{$defn} !~ /^["]/
                               } keys %{$defs} );

        # Add these to the output
        push @all_constants, @constant_names;
    }

    return @all_constants;
}




# _extract_enum_constants_from()
#
# Internal function.
#
# Does some heinous massaging on a "typedef blob" returned from the
# ModPerl::CScan::get() macro, ultimately spitting out a hashref for each
# enumerated constant of the following form:
#
#  { name  => $enumerated_constant_name,
#    macro => 1 }
#
# See C::Scan for more details on the "typedef blob".
sub _extract_enum_constants_from {

    my $typedefs = shift;

    # enums will live in the @$typedefs array as follows:
    #  ' enum
    #      {
    #              FOO_TYPE_A, FOO_TYPE_B, FOO_TYPE_C,
    #              FOO_TYPE_D, FOO_TYPE_E, FOO_TYPE_F,
    #              FOO_TYPE_INVALID
    #      } foo_type_e'
    # We want to remove all the extraneous stuff and output the
    # following for each enum constant:
    #     { name => $constant, macro => 1 }
    # This can then be fed into the NAMES parameter of WriteConstant
    # and have it do the right thing.
    my @enums =  map { { name => "$_", macro => 1 } } # 7) assemble hashrefs
                                                      #      for
                                                      #      WriteConstants()
                 map { s/[=][^\s]+//; $_ }            # 6) discard explicit
                                                      #      val settings
                 map { split ',' }                    # 5) split into consts
                 map { s/^\s*enum.+[{]\s*//s;    # 2) strip chars up
                                                 #      to 1st constant
                       s/\s*[}].+_e$//s;         # 3) strip chars after
                                                 #      last constant
                       s/\s//sg;                 # 4) strip all other
                                                 #      whitespace
                       $_ }
                 grep { /enum/ } @{$typedefs};   # 1) find "enum" typedefs

    return @enums;
}




# _const_mod_header_text()
#
# Internal function.
#
# Return the block of code to be written to the top of the Symbols.pm
# module.
sub _const_mod_header_text {
    my $sub_pkg_name    = shift;

    return <<"END_OF_MODULE_HEADER";
package $sub_pkg_name;

use 5.008003;
use strict;
use warnings;

use base 'Exporter';

our \@EXPORT = qw( \@ALL );

our \@ALL = qw(
END_OF_MODULE_HEADER
}




# _const_mod_symbol_names()
#
# Internal function.
#
# Return symbol names found in a list such as that which is returned
# from extract_constants_from().  This function is typically used
# to get text for writing to the middle portion of the Symbols.pm
# module.
sub _const_mod_symbol_names {
    my $names_ref       = shift;

    my $symbol_names_str = "";
    for my $symbol (@$names_ref) {
        if (ref $symbol) {
            $symbol_names_str .= join q{}, ' 'x4,
                                           $symbol->{name},
                                           "\n";
        }
        else {
            $symbol_names_str .= join q{}, ' 'x4,
                                           $symbol,
                                           "\n";
        }
    }

    return $symbol_names_str;
}




# _const_mod_trailer_text()
#
# Internal function.
#
# Return the block of code to be written to the bottom of the Symbols.pm
# module.
sub _const_mod_trailer_text {
    return <<"END_OF_MODULE_TRAILER";
);

1;
END_OF_MODULE_TRAILER
}



# write_constants_module()
#
# Exported function.
#
# This function writes a Constants/C/Symbols.pm submodule into the
# invoking Makefile.PL module's namespace.
sub write_constants_module {
    my $pkg_name         = shift;
    my @c_constants      = @_;    # array of symbol name blobs

    # This is the canonical name of the submodule exporting the C symbols
    my $const_mod_base_name    = 'Symbols.pm';
    my $fwd_decl_base_name     = 'ForwardDecls.pm';
    my @const_mod_subdir_elems = qw(Constants C);

    # turn the current package name into a directory path, creating
    # subordinate paths if needed
    my $const_mod_dir_name
        = join "/", ( 'lib',
                      split( "::", $pkg_name ),
                      @const_mod_subdir_elems,
                    );

    my $const_mod_base_full_name
        = join '/', ( $const_mod_dir_name,
                      $const_mod_base_name,
                    );
    my $fwd_decl_base_full_name
        = join '/', ( $const_mod_dir_name,
                      $fwd_decl_base_name,
                    );


    # Create directory in which to place the module
    unless (-d "$const_mod_dir_name") {
        mkpath( $const_mod_dir_name, 0, 0755) or die "mkpath failed: $!";
    }

    # Create the module file to house the list of constants, as
    # well as the forward declarations file.
    open my $const_mod_fh, ">", "$const_mod_base_full_name"
        or die "Could not open $const_mod_base_name for writing: $!";
    open my $fwd_decl_fh, ">", "$fwd_decl_base_full_name"
        or die "Could not open $fwd_decl_base_full_name for writing: $!";

    # Common arg list for the next threee functions
    (my $const_mod_name_prefix = $const_mod_base_name) =~ s/[.]pm$//;
    my $sub_pkg_name = join "::", ($pkg_name,
                                   @const_mod_subdir_elems,
                                   $const_mod_name_prefix);

    # Write file contents.
    print {$const_mod_fh} _const_mod_header_text(  $sub_pkg_name );
    print {$const_mod_fh} _const_mod_symbol_names( \@c_constants );
    print {$const_mod_fh} _const_mod_trailer_text(               );

    # Close file.
    close $const_mod_fh;

    # Write forward declarations
    my @sym_names = split /\s+/, _const_mod_symbol_names( \@c_constants );
    for my $sym (grep { ! /^\s*$/ } @sym_names) {
        print {$fwd_decl_fh} "sub $sym();\n";
    }
    print {$fwd_decl_fh} "\n1;\n";

    # Close file.
    close $fwd_decl_fh;

    # Now write the XS stuff.  This is overly simplistic.  For example,
    # string constants will not be handled correctly this way.
    ExtUtils::Constant::WriteConstants(
        NAME         => $pkg_name,
        NAMES        => \@c_constants,
        DEFAULT_TYPE => 'IV',
        C_FILE       => 'const-c.inc',
        XS_FILE      => 'const-xs.inc',
    );

    # We've now written the file, but we need to modify handling of IVs
    # to avoid seg faults on C constant access.
    open CONST_XS_IN, "const-xs.inc"
        or die "Failed to open autogen'd const-xs.inc file for mods: $!";
    my @in_code_lines = <CONST_XS_IN>;
    close CONST_XS_IN;

    # Make the modification.  Basically we assure that returned IVs have
    # refcounts of 1 vs. leaving it up to Perl to decide.
    my @out_code_lines;
    for my $line (@in_code_lines) {
        if ($line =~ /PUSHi[(]iv[)]/) {
            $line = "          PUSHs(sv_2mortal(newSViv(iv)));\n";
        }
        push @out_code_lines, $line;
    }

    # Write out the modified file.  Only one line should differ from
    # the original.
    open CONST_XS_OUT, ">const-xs.inc"
        or die "Failed to open const-xs.inc for writing, post mods: $!";
    for my $line (@out_code_lines) {
        print CONST_XS_OUT $line;
    }
    close CONST_XS_OUT;

    # Help the user out.  They will need to modify their code.
    print {*STDERR} _suggested_code_snippets($pkg_name);

    return;
}



# _suggested_code_snippets()
#
# Internal function.
#
# Returns a block of text that provides helpful direction to
# someone who has just run C::Scan::Constants code, via "perl Makefile.PL"
# so that the next time they do that they'll actually get all the
# goodies wired into their code.
sub _suggested_code_snippets {
    my $pkg_name = shift;

    # Set up for extra decoration if needed to help out a build system
    my ($header,$trailer);

    # As mentioned above, we include support for a custom pure-Perl
    # build system named Blueprint.  If you know of or use Blueprint,
    # the "if" clause here will mean something to you.  If not, ignore it.
    if ($g_use_blueprint_sections) {
        $header  = "##### (BLUEPRINT: BEGIN EXPECTED OUTPUT) #####\n";
        $trailer = "##### (BLUEPRINT: END EXPECTED OUTPUT) #####\n";
    }
    else {
        # The most common situation
        $header  = q{};
        $trailer = q{};
    }

    return <<"END_BEGIN_SNIPPET";
$header

You will need to add some code to your YourPkgName.pm and YourPkgName.xs
files in order to make use of the code that has just been autogenerated
via C::Scan::Constants.

If you've already added the code, just ignore this message.

Otherwise, do some cut-and-paste of the following snippets,
substituting "YourPkgName" with your actual module name
everywhere you see it in the snippets.

Then, simply "make" and test!  It's that easy.

#------------- start of .pm snippet ----------------------

# Do we have C symbols in  a YourPkgName::Constants::C::Symbols module?
my \$_symbols_present;

# Check for (and note) the existence of the C constants module.
BEGIN {
    eval "require YourPkgName::Constants::C::Symbols";
    \$_symbols_present = 1 unless \$\@;

    eval "require YourPkgName::Constants::C::ForwardDecls";
}

# (Later, in your exports definition section...)

# Bring in the whole lot of C constants that are available. Your mileage
# of course, may vary, e.g. alternatively do this via \@EXPORT_OK.
our \@EXPORT = (

                # any other symbols you are exporting, plus:

                \$_symbols_present ? \@YourPkgName::Constants::C::Symbols::ALL
                                  : (),
              );

# Make sure to have a $VERSION defined.

# Then, prior to subroutine definitions, insert the following.  Note
# that if you left autoloading turned on when you created your module
# skeleton with h2xs (i.e. you did *not* specify -A when you ran it),
# you already have this code in place.

use Carp;
use AutoLoader;

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my \$constname;
    our \$AUTOLOAD;
    (\$constname = \$AUTOLOAD) =~ s/.*:://;
    croak "&YourPkgName::constant not defined" if \$constname eq 'constant'
;
    my (\$error, \$val) = constant(\$constname);
    if (\$error) { croak \$error; }
    {
        no strict 'refs';
        *\$AUTOLOAD = sub { \$val };
    }
    goto &\$AUTOLOAD;
}
require XSLoader;
XSLoader::load('YourPkgName', \$VERSION);

#------------- start of .pm snippet ----------------------

#------------- start of .xs snippet ----------------------

# In YourPkgName.xs, make sure to add the following lines.

/* Before "MODULE =" line: */

/* Specific .h files to scan */
#include "header_file_a.h"
#include "header_file_b.h"
/* ... */
#include "header_file_c.h"

/*
 * Note that if you left autoloading turned on when you created your module
 * skeleton with h2xs (i.e. you did *not* specify -A when you ran it),
 * you probably already have the code below in place and ready to use.
 */

/* Reference to autogenerated C-side binding file */
#include "const-c.inc"

/* After "MODULE =" line: */

# Reference to autogenerated xs-side binding file.
INCLUDE: const-xs.inc

#------------- end of .xs snippet ------------------------

$trailer
END_BEGIN_SNIPPET

}

1;
__END__

=head1 NAME

C::Scan::Constants - Slurp constants from specified C header (.h) files

=head1 VERSION

This documentation refers to C::Scan::Constants version 1.020.

=head1 SYNOPSIS

  ## Intended for use in your module's Makefile.PL file, to
  ## add DWIMery to use of C constants within your module.

  use C::Scan::Constants;

  my @hdr_files = (
      "/path/to/first_header.h",
      "/path/to/second_header.h",
  );

  ## Slurp a list of constant information from C headers
  my @constants = extract_constants_from( @hdr_files );

  ## Create the C, XS, and pure-Perl machinery needed to
  ## provide automagical access to C constants at runtime.
  write_constants_module( "Your::Module", @constants );

=head1 DESCRIPTION

This module provides an alternative to using the B<h2ph> command
to generate Perl header (.ph) files that are then subsequently
C<require>d by your module code.  When you need access to C
numeric and enumerated type constants,
especially in a dynamic source tree environment, there are times
when you'd like something a little more automagical and closely
tailored to what you actually need.  Now you have it, in this module.

C::Scan::Constants was born out of a recognition that ModPerl::CScan
and ExtUtils::Constant provide a wealth of capabilities in the
area of C code parsing and autogenerated XS access to C constants,
but that the actual mechanisms for harnessing them to do those
things were really rather opaque.  This module should help
take (most of) the mystery out of those activities.

Here's a brief overview of the module:

=over 4

=item *

Provides a function, L<"extract_constants_from()">, that extracts
a list of information relating to L<#define> constants and
L<#typedef enum> style constants found in a supplied list of
C header (.h) files.

=item *

Provides a function, L<"write_constants_module()">, that generates
three files:

        const-c.inc
        const-xs.inc
        lib/Your/ModuleName/Constants/C/Symbols.pm

that are ready to be dropped into your module's build machinery
to give your module runtime access to those constants.

=item *

Gives hints at C<perl Makefile.PL> time about the code you need
to add to files in your module's source tree to assure that
all the tracks line up at module build time.

=back

=head1 SUBROUTINES

The following two subroutines are exported by default.

=head2 @blobs = extract_constants_from( @header_paths )

=over

Takes a list of C header (.h) files and returns a list
of constants information suitable for supplying as the NAME parameter
to ExtUtils::Constant.

Returns an array of constant name "blobs" suitable for feeding
into ExtUtils::Constant::WriteConstants() as the value of
the NAME parameter.

=back

=head2 write_constants_module( $pkg_name, @c_constants )

=over

Writes a Constants/C/Symbols.pm submodule into the
invoking Makefile.PL module's namespace.  Really just a value-added
wrapper around ExtUtils::Constant::WriteConstants().

No return value -- call for side-effects only.

=back

=head1 DIAGNOSTICS

TBD.  I owe you a list of error and warning messages you might see
when invoking functions from C::Scan::Constants.

=head1 CONFIGURATION AND ENVIRONMENT

TBD.  If/when populated, this section will describe
in detail how/where to add the
necessary extra code to wire in the autogenerated files to your
module.  It will also describe what you need in your Makefile.PL
to assure that the autogenerated stuff goes away at C<make clean>
time.

For the time being, write_constants_module() outputs to STDERR
a number of hints that should provide the needed answers to these
types of questions.

=head1 DEPENDENCIES

For the program proper:

=over 4

Carp, Data::Flow, ExtUtils::Constants,
ModPerl::CScan, C::Scan, File::Temp, File::Copy,
File::Spec, File::Path, Exporter

=back

Additional modules needed for tests (over and above Test::More):

=over 4

Scalar::Util, List::MoreUtils, Cwd

=back

=head1 COMPATIBILITY NOTES

This version of C::Scan::Constants is known to work with
ExtUtil::Constants versions 0.14 - 0.16.  It may not work
properly with earlier or later versions.  I welcome your comments
and patches to assure continued compatibility going forward.

=head1 BUGS AND LIMITATIONS

The amount of code you are currently required to add to your module
to make use of the files C::Scan::Constants generates seems rather
too much.  It would be highly useful to provide a more streamlined
usage, or to provide scripts that would assist you in inserting the
needed code into your module.

Also, the tests are incomplete.  The runtime usability of constants
generated by the module is not tested at all.  I need to set up some
tests that actually create a new module, invoke the C::Scan::Constants
functionality, and then do a

    perl Makefile.PL
    make
    make test

regimen on that module in order to accomplish this.   That's pretty
tricky, so I haven't tackled it yet.

Finally (well probably not), it would be nice to be able to specify
whether B<cpp> should "follow" C<#include> statements in C header files.
Sometimes, that's what you really want.  This version of
C::Scan::Constants suppresses all such "following" behavior.

Other than that, there are no known bugs in this module.

Please report problems to Philip Monsen (philip.monsen@gmail.com).
Patches are especially welcome.

=head1 AUTHOR

Philip Monsen (philip.monsen@gmail.com)

=head1 COPYRIGHT AND LICENSE

I<ModPerl::CScan>

ModPerl::CScan is provided with this module for convenience for those
users who do not wish to install mod_perl as a whole.  This version
is 0.75 from the mod_perl-2.0.1 distro.

Copyright (C) 2005 by Doug MacEachern.

Licensed under the Apache License, Version 2.0; you may not
use this file except in compliance with the License.  A current
copy of the license is available at

     http://www.apache.org/licenses/LICENSE-2.0

See also contrib/LICENSE for a Jan. 2004 copy of the license text.

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.


I<All else>

Copyright (C) 2005-11 by Philip Monsen.

This module is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.3 or,
at your option, any later version of Perl 5 you may have available.
See L<perlartistic>.

This module is distributed in the hope that it will be useful,
and is provided on an "AS-IS" basis,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
or implied, including, without limitation, any warranties or
conditions of TITLE, NON-INFRINGEMENT, MERCHANTABILITY, or
FITNESS FOR A PARTICULAR PURPOSE.

=cut
