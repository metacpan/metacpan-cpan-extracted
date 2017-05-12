# This is the Alien::Judy module, a way to ensure that users who don't
# natively have libJudy on their system can still get one. It provides
# libJudy.so and Judy.h at the path $Config{sitearch}/Alien/Judy.
package Alien::Judy;
# ABSTRACT: A wrapper for installing the Judy library

use strict;
use warnings;
use vars qw( $VERSION $DEBUG $HANDLE );
use Config ();
use Cwd ();
use File::Spec ();
use DynaLoader ();

# This module allows users to import its three public functions
# inc_dirs(), lib_dirs(), and dl_load_libjudy().
use Sub::Exporter -setup => {
    exports => [qw( inc_dirs lib_dirs dl_load_libjudy )]
};

# The provided functions inc_dirs() and lib_dirs() are currently
# identical. Initially, they weren't.
*lib_dirs = \&inc_dirs;

# TODO: add literate documentation
sub inc_dirs {
    # Find files from ., $sitearch and @INC.
    my @dirs =
        grep { defined() && length() }
            @Config::Config{qw(sitearchexp sitearch)},
            @INC,
            Cwd::getcwd();

    # But first try to find them in $_/Alien/Judy/
    unshift @dirs,
        map { File::Spec->catdir( $_, 'Alien', 'Judy' ) }
        @dirs;

    # Return the unique-ified list
    my %seen;
    return
        grep { ! $seen{$_}++ }
        @dirs;
}

# This module depends on libJudy from
# http://judy.sourceforge.net. Either I can find it as a
# system-installed library:
#
#   apt-get install libjudydebian1  # for libJudy.so
#   apt-get install libjudy-dev     # for Judy.h
#
# Or I can get it by the perl CPAN module Alien::Judy which builds and
# installs Judy.h and libJudy.so into $Config{sitearch}/Alien/Judy.
#
# CPAN testers however won't have actually installed libJudy so I'll
# need to find it in @INC as set by $ENV{PERL5LIB} with a typical
# value of:
#
#   $INC[...] = '/home/josh/.cpan/build/Alien-Judy-0.01/blib/arch'
#
# but the files Judy.h and libJudy.so are a couple levels deeper at:
#
#   $INC[...] = '/home/josh/.cpan/build/Alien-Judy-0.01/blib/arch/Alien/Judy'
#
sub _libjudy_candidates {
    # Get a list of possible libJudy.so files.
    #
    # When writing this module, I found it would occasionally not only
    # find libJudy.so but also blib/arch/Judy/Judy.so which is the
    # Perl XS module. That was when this -lJudy resolving code was
    # directly in the Judy cpan module though which has a lib/Judy.xs
    # file. It's plausible that it's entirely irrelevant now that this
    # is in Alien::Judy.
    #
    my @candidate_libs = DynaLoader::dl_findfile('-lJudy');
    if ( $DEBUG ) {
        printf STDERR "candidates=@candidate_libs at %s line %d.\n", __FILE__, __LINE__;
    }

    # I found that Solaris would find libJudy.so with DynaLoader but
    # ld.so.1 when loading libJudy.so for Judy.pm would fail to find
    # the right library to link against.
    #
    # I don't particularly understand it however what worked was to
    # attempt to load libJudy.so.1 first.
    my @dot_one =
        grep { -f }
        map { "$_.1" }
        @candidate_libs;

    unshift @candidate_libs, @dot_one;

    return @candidate_libs;
}

sub _dl_load_libjudy {
    my @candidate_libs = @_;

    # The libJudy I find must provide the base functions from the
    # libJudy library. This is to possibly skip "wrong" libJudy
    # libraries.
#    @DynaLoader::dl_require_symbols = 'Judy1Test';

    # Attempt to load each candidate until something succeeds. If one
    # of the candidates happens to be the Perl XS module
    # blib/arch/Judy/Judy.so then I'd like loading to keep trying and
    # not fail. If I know how to predictably filter
    # blib/arch/Judy/Judy.so out of this list I'd do that.
    my $libjudy_loaded;
  CANDIDATE_LIBRARY:
    for my $libjudy_file ( @candidate_libs ) {
        my $ok = eval {
            $HANDLE = DynaLoader::dl_load_file( $libjudy_file, 0x01 );
            1;
        };
        if ( $DEBUG ) {
            my $msgf =
                $ok
                ? "Loaded $libjudy_file at %s line %d.\n"
                : "Couldn't load $libjudy_file: $@ at %s line %d.\n";
            printf STDERR $msgf, __FILE__, __LINE__;
        }

        if ( $ok ) {
            $libjudy_loaded = 1;
            last CANDIDATE_LIBRARY;
        }
    }

    return $libjudy_loaded;
}

sub dl_load_libjudy {
    local @DynaLoader::dl_library_path = (
        @DynaLoader::dl_library_path,
        lib_dirs()
    );

    # Enable DynaLoader debugging along with Judy debugging
    local $DynaLoader::dl_debug = $DynaLoader::dl_debug;
    if ( $DEBUG ) {
        $DynaLoader::dl_debug ||= 1;
    }

    my @libjudy_files = _libjudy_candidates();

    my $ok = _dl_load_libjudy( @libjudy_files );

    return $ok;
}

$VERSION = '0.26';

1;
