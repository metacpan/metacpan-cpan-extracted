use strict;
use warnings;

package BSONConfig;

use Config;
use Config::AutoConf 0.22;
use Path::Tiny 0.052;
use File::Spec::Functions qw/catdir/;
use Cwd;

use constant { HAS_GCC => $Config{ccname} =~ /gcc/ ? 1 : 0, };

# can_xs, can_cc, can_run copied from the Moose distribution, copyright
# Infinity Interactive, under the terms of Perl 5 itself.
sub can_xs {
    # Do we have the configure_requires checker?
    unless ( eval 'require ExtUtils::CBuilder; ExtUtils::CBuilder->VERSION(0.27); 1' ) {
        # They don't obey configure_requires, so it is
        # someone old and delicate. Try to avoid hurting
        # them by falling back to an older simpler test.
        return can_cc();
    }

    return ExtUtils::CBuilder->new( quiet => 1 )->have_compiler;
}

# can we locate a (the) C compiler
sub can_cc {
    my @chunks = split( / /, $Config::Config{cc} ) or return;

    # $Config{cc} may contain args; try to find out the program part
    while (@chunks) {
        return can_run("@chunks") || ( pop(@chunks), next );
    }

    return;
}

# check if we can run some command
sub can_run {
    my ($cmd) = @_;

    return $cmd if -x $cmd;
    if ( my $found_cmd = MM->maybe_command($cmd) ) {
        return $found_cmd;
    }

    for my $dir ( ( split /$Config::Config{path_sep}/, $ENV{PATH} ), '.' ) {
        next if $dir eq '';
        my $abs = File::Spec->catfile( $dir, $cmd );
        return $abs if ( -x $abs or $abs = MM->maybe_command($abs) );
    }

    return;
}

sub check_for_compiler {
    die 'This distribution requires a working compiler'
      unless can_xs();

    check_for_outdated_win_gcc()
      if $^O eq 'MSWin32';
}

sub check_for_outdated_win_gcc {
    return if $ENV{MONGODB_NO_WIN32_GCC_CHECK};
    return if !HAS_GCC;

    local $@;
    my $gcc_ver = eval {
        my ($v) = split / /, $Config{gccversion};
        "$v";
    };
    die "Could not identify gcc version in '$Config{gccversion}' due to:\n$@"
      if !$gcc_ver or $@;
    my $gcc_vstring = eval "v$gcc_ver";
    die "Could not parse gcc version '$gcc_ver':\n$@" if !$gcc_vstring or $@;
    my $min_work_ver     = "4.6.3";
    my $min_work_vstring = eval "v$min_work_ver";
    return if $gcc_vstring ge $min_work_vstring;

    die <<"END";
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

Your gcc is version '$gcc_ver'.
The highest known incompatible version of gcc is '4.4.7'.
The lowest  known   compatible version of gcc is '$min_work_ver'.

Your gcc version is highly unlikely to be able to compile BSON, since the
libraries/headers that come with it is incompatible with our version of libbson.

We're aborting here forcibly so you will see this message. You have the
following options at this point:

1. set MONGODB_NO_WIN32_GCC_CHECK to any value to ignore this message and retry

2. if you know C, try and help us by upgrading our libbson, patches welcome!

3. install a newer gcc, '$min_work_ver' or higher

4. install Strawberry 5.16.3 or higher, their gcc versions are compatible

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
END
}

# Quick and dirty autoconf substitute
sub configure_bson {
    my $conf = probe_bson_config();

    my $config_guts = path("bson/bson-config.h.in")->slurp;
    for my $key (%$conf) {
        $config_guts =~ s/\@$key\@/$conf->{$key}/;
    }
    path("bson/bson-config.h")->spew($config_guts);

    return $conf;
}

sub probe_bson_config {
    my $ca = Config::AutoConf->new;
    $ca->push_lang("C");
    my %conf;

    ##/*
    ## * Define to 1234 for Little Endian, 4321 for Big Endian.
    ## */
    $conf{BSON_BYTE_ORDER} = $Config{byteorder} =~ /^1234/ ? '1234' : '4321';

    ##/*
    ## * Define to 1 if you have stdbool.h
    ## */
    $conf{BSON_HAVE_STDBOOL_H} = $Config{i_stdbool} ? 1 : 0;

    ##/*
    ## * Define to 1 for POSIX-like systems, 2 for Windows.
    ## */
    $conf{BSON_OS} = $^O eq 'MSWin32' ? 2 : 1;

    ##/*
    ## * Define to 1 if you have clock_gettime() available.
    ## */
    ## XXX also needs to link -lrt for this to work
    {
        my $ca = Config::AutoConf->new;
        $ca->push_libraries('rt');
        $conf{BSON_HAVE_CLOCK_GETTIME} =
          $ca->link_if_else( $ca->lang_call( "", "clock_gettime" ) ) ? 1 : 0;
    }

    ##/*
    ## * Define to 1 if you have strnlen available on your platform.
    ## */
    $conf{BSON_HAVE_STRNLEN} =
      $ca->link_if_else( $ca->lang_call( "", "strnlen" ) ) ? 1 : 0;

    ##/*
    ## * Define to 1 if you have snprintf available on your platform.
    ## */
    $conf{BSON_HAVE_SNPRINTF} = $Config{d_snprintf} ? 1 : 0;

    ##/*
    ## * Define to 1 if your system requires {} around PTHREAD_ONCE_INIT.
    ## * This is typically just Solaris 8-10.
    ## */

    ## pthread-related configuration
    if ( $^O eq 'MSWin32' ) {
        $conf{BSON_PTHREAD_ONCE_INIT_NEEDS_BRACES} = 0;
    }
    else {

        $conf{BSON_PTHREAD_ONCE_INIT_NEEDS_BRACES} = $ca->link_if_else(<<'HERE') ? 0 : 1;
#include <pthread.h>
pthread_once_t foo = PTHREAD_ONCE_INIT;
int
main ()
{
;
return 0;
}
HERE

    }

    ##/*
    ## * Define to 1 if we have access to GCC 32-bit atomic builtins.
    ## * While this requires GCC 4.1+ in most cases, it is also architecture
    ## * dependent. For example, some PPC or ARM systems may not have it even
    ## * if it is a recent GCC version.
    ## */
    $conf{BSON_HAVE_ATOMIC_32_ADD_AND_FETCH} = $ca->link_if_else(<<'HERE') ? 1 : 0;
#include <stdint.h>
int
main ()
{
    int32_t seq = 0;
    __sync_fetch_and_add_4(&seq, (int32_t)1);
    return seq;
}
HERE

    ##/*
    ## * Similarly, define to 1 if we have access to GCC 64-bit atomic builtins.
    ## */
    $conf{BSON_HAVE_ATOMIC_64_ADD_AND_FETCH} = $ca->link_if_else(<<'HERE') ? 1 : 0;
#include <stdint.h>
int
main ()
{
    int64_t seq = 0;
    __sync_fetch_and_add_8(&seq, (int64_t)1);
    return seq;
}
HERE

    ##/*
    ## * Define to 1 if you have _set_output_format (VS2013 and older).
    ## */
    $conf{BSON_NEEDS_SET_OUTPUT_FORMAT} = 0;

    ##/*
    ## * Define to 1 if you have struct timespec available on your platform.
    ## */
    $conf{BSON_HAVE_TIMESPEC} = $ca->check_type('timespec');

    ##/*
    ## * Define to 1 if you want extra aligned types in libbson
    ## */
    $conf{BSON_EXTRA_ALIGN} = 0;

    return \%conf;
}

sub configure {
    my $mm_conf = shift;

    my $ccflags = $mm_conf->{CCFLAGS} || $Config{ccflags};
    $ccflags = "" unless defined $ccflags;

    my $libs = $mm_conf->{LIBS};
    $libs = "" unless defined $libs;

    my $ldflags = $mm_conf->{LDFLAGS};
    $ldflags = "" unless defined $ldflags;

    $ccflags .= " -Wall -Wextra -Wuninitialized -Wdeclaration-after-statement"
      if HAS_GCC() && ( $ENV{AUTHOR_TESTING} || $ENV{AUTOMATED_TESTING} );

    # Perl on older Centos doesn't come with this by default
    $ccflags .= " -D_GNU_SOURCE"
      if HAS_GCC() && $ccflags !~ /-D_GNU_SOURCE/;

    # openbsd needs threaded perl *or* single-threaded but with libpthread, so
    # we check specifically for that
    if ( $^O eq 'openbsd' ) {
        my $has_libpthread = qx{/usr/bin/ldd $Config{perlpath}} =~ /libpthread/;
        die "OS unsupported: OpenBSD support requires a perl linked with libpthread"
          unless $has_libpthread;
    }

    # check for 64-bit
    if ( $Config{use64bitint} ) {
        $ccflags .= " -DMONGO_USE_64_BIT_INT";
    }

    # check for big-endian
    my $endianess = $Config{byteorder};
    if ( $endianess == 4321 || $endianess == 87654321 ) {
        $ccflags .= " -DMONGO_BIG_ENDIAN=1 ";
        if ( $] lt '5.010' ) {
            die "OS unsupported: Perl 5.10 or greater is required for big-endian platforms";
        }
    }

    # needed to compile bson library
    $ccflags .= " -DBSON_COMPILATION ";

    my $conf = configure_bson();

    if ( $conf->{BSON_WITH_OID32_PT} || $conf->{BSON_WITH_OID64_PT} ) {
        my $pthread = $^O eq 'solaris' ? " -pthreads " : " -pthread ";
        $ccflags .= $pthread;
        $ldflags .= $pthread;
    }

    if ( $conf->{BSON_HAVE_CLOCK_GETTIME} ) {
        $libs .= " -lrt";
    }

    $mm_conf->{INC}     = "-I. -Ibson";
    $mm_conf->{CCFLAGS} = $ccflags;
    $mm_conf->{LIBS}    = $libs;
    $mm_conf->{LDFLAGS} = $ldflags;

    return;
}

1;
