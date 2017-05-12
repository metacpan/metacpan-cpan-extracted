#
# $Id: Build.PL,v 1.3 2003/12/17 03:39:54 james Exp $
#

use strict;
use warnings;

use Module::Build;

use File::Spec;

my $inc_dir;
my $lib_dir;

# possible prefixes where we might find libwrap.a
# if you know of other common ones please let me know
my @prefixes = (
    File::Spec->catdir( File::Spec->rootdir, 'usr' ),
    File::Spec->catdir( File::Spec->rootdir, 'usr', 'local' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt', 'local' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt', 'libwrap' ),
    File::Spec->catdir( File::Spec->rootdir, 'opt', 'tcpwrappers' ),
);

# try to figure out where libwrap.a is
for my $prefix( @prefixes ) {
    for my $libname( qw|libwrap.so libwrap.a| ) {
        my $candidate = File::Spec->catfile( $prefix, 'lib', $libname );
        if( -e $candidate && -f _ && -r _ ) {
            my $y_n = Module::Build->y_n(
                "do you want to link against $candidate?", "y"
            );
            if( $y_n ) {
                $lib_dir = File::Spec->catdir( $prefix, 'lib' );
                last;
            }
        }
    }
}

# try to figure out where tcpd.h is
for my $prefix( @prefixes ) {
    my $candidate = File::Spec->catfile( $prefix, 'include', 'tcpd.h' );
    if( -e $candidate && -f _ && -r _ ) {
        my $y_n = Module::Build->y_n(
            "do you want to use $candidate as your header?", "y"
        );
        if( $y_n ) {
            $inc_dir = File::Spec->catdir( $prefix, 'include' );
            last;
        }
    }
}

# if we can't find it, prompt
unless( $inc_dir ) {
    $inc_dir = Module::Build->prompt(
        "enter include directory to use:",
        File::Spec->catdir($prefixes[0], 'include')
    );
}
unless( $lib_dir ) {
    $lib_dir = Module::Build->prompt(
        "enter library directory to use:",
        File::Spec->catdir($prefixes[0], 'lib')
    );
}

# create the Buildfile
Module::Build->new(

    module_name          => 'Authen::Libwrap',

    dist_version         => '0.23',

    license              => 'perl',
    
    requires             => {
        'Scalar::Util'    => 0,
    },
    
    build_requires       => {
        'Test::More'      => 0,
        'Test::Exception' => 0,
    },

    create_makefile_pl   => 'passthrough',

    extra_compiler_flags => "-I$inc_dir",

    extra_linker_flags   => [ "-L$lib_dir", "-lwrap" ]

)->create_build_script;

#
# EOF
