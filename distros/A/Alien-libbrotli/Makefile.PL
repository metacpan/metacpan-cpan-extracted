use strict;
use warnings;
use Alien::cmake3;
use Env qw/@PATH/;
use XS::Install;

my $libdir = "brotli";

unless (-f "$libdir/Makefile") {
    unshift @PATH, Alien::cmake3->bin_dir;
    my $result = system(qq{cd $libdir && cmake CMakeLists.txt -G "Unix Makefiles" -DCMAKE_C_FLAGS="-O2 -fPIC" -DCMAKE_BUILD_TYPE=Release});
    die "can't configure cmake\n" if $result != 0;
}

my %params = (
    NAME   => 'Alien::libbrotli',
    LDFROM => '-Wl,--whole-archive $(OBJECT) -Wl,--no-whole-archive',
    CLIB   => {
        DIR    => $libdir,
        FILE   => 'libbrotli-static.a',
        TARGET => 'brotli-static',
    },
    BIN_SHARE => {
        INCLUDE  => {
            "$libdir/c/include/" => '/',
        },
    },
    CONFIGURE_REQUIRES => {"Alien::cmake3" => '0.04'},
    realclean => { FILES => ["$libdir/Makefile"] },
);

write_makefile(%params);
