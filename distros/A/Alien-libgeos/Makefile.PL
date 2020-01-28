use strict;
use warnings;

use Alien::cmake3;
use File::Path qw/rmtree/;
use Env qw/@PATH/;
use XS::Install;

my $version = '3.7.3';

my $src_dir  = "geos-${version}";

if (! -f "$src_dir/build/Makefile"){
    unshift @PATH, Alien::cmake3->bin_dir;

    print "Going to generate Makefile\n";
    my $CFLAGS = $ENV{CFLAGS} // '-O2 -fPIC';
    local $ENV{CFLAGS} = $ENV{CXXFLAGS} = $CFLAGS;

    my $cmake_flags = join(" ", '-G "Unix Makefiles"', "-DCMAKE_CXX_FLAGS=\"$CFLAGS\"", "-DCMAKE_C_FLAGS=\"$CFLAGS\"",
        qw/
        -DGEOS_ENABLE_TESTS=off
        -DGEOS_ENABLE_INLINE=off
        -DGEOS_BUILD_STATIC=on
        -DGEOS_BUILD_SHARED=off
        -DGEOS_BUILD_CAPI=off
        -DCMAKE_BUILD_TYPE=Release
        /
    );
    print "cflags: ", $cmake_flags, "\n";
    rmtree "$src_dir/build" if -d "$src_dir/build";
    mkdir "$src_dir/build" or die("Can't mkdir : $!");
    my $result = system("cd $src_dir/build && cmake $cmake_flags ..");
    die "FATAL: can't configure geos cmake\n" if $result != 0;
}

my %params = (
    NAME   => 'Alien::libgeos',
    LDFROM => '-Wl,--whole-archive $(OBJECT) -Wl,--no-whole-archive',
    CPLUS  => 11,
    CLIB   => {
        DIR    => "$src_dir/build",
        FILE   => 'lib/libgeos.a',
        TARGET => '',
    },
    BIN_SHARE => {
        INCLUDE  => {
            "$src_dir/build/include" => '/',
            "$src_dir/include"       => '/',
        },
    },
    CONFIGURE_REQUIRES => {
        "Alien::cmake3"         => '0.04',
        "ExtUtils::MakeMaker"   => '6.52',
        "File::Path"            => 0,
    },
);

write_makefile(%params);
