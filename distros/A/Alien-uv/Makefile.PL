use strict;
use XS::Install;
use Alien::cmake3;
use Env qw/@PATH/;

my $bdir = "libuv/build";

unshift @PATH, Alien::cmake3->bin_dir;
mkdir($bdir) unless -d $bdir;
my $result = system(qq{cd $bdir && cmake .. -G "Unix Makefiles" -DCMAKE_C_FLAGS="-fPIC -O2"});
die "could not make Makefile\n" if $result != 0;

my $libs = '-lpthread';
$libs .= ' -liphlpapi -lpsapi -luserenv' if $^O eq 'MSWin32'; 

my %params = (
    NAME      => 'Alien::uv',
    LIBS      => $libs,
    BIN_SHARE => {INCLUDE => {'libuv/include' => '/'}},
    CLIB      => {
        DIR       => $bdir,
        FILE      => 'libuv_a.a',
        BUILD_CMD => '$(MAKE) uv_a',
    },
    CONFIGURE_REQUIRES => {'Alien::cmake3' => 0},
    clean              => {FILES => $bdir},
);

write_makefile(%params);
