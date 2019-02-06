use strict;
use warnings;

use Archive::Tar;
use Digest::SHA1;
use File::Fetch;
use File::Path qw/rmtree/;
use XS::Install;

my $version       = '3.7.0';
my $sha1_checksum = 'a42cfc1178784ebdf124c6537ee3158e5acac698';

my $filename = "geos-${version}.tar.bz2";
my $src_dir  = "geos-${version}";
my $url      = "http://download.osgeo.org/geos/${filename}";

sub check_digest {
    print "Cheking SHA1 digest for $filename\n";
    my $sha1 = Digest::SHA1->new;
    open(my $fh, "<", $filename) or die "Can't open < $filename: $!";
    binmode $fh if ($^O eq 'MSWin32');
    $sha1->addfile($fh);
    my $actual_digest = $sha1->hexdigest;
    die ("Digests mismatch. Got $actual_digest, expected: $sha1_checksum")
        if ($actual_digest ne $sha1_checksum);
    print "SHA1 digest is correct\n";
}

my $do_download =  !(-e $filename);

if ($do_download) {
    print "Downloading $url\n";
    my $ff = File::Fetch->new(uri => $url);
    my $path = $ff->fetch($url);
    if (!$path) {
        die $ff->error(1) // "There was a problem downloading $url";
    }
    rename $path, $filename;
}
check_digest();

print "Unpacking $filename\n";
my $tar = Archive::Tar->new;
$tar->read($filename);
$tar->extract;

if (! -f "$src_dir/build/include/geos/platform.h"){
    print "Going to apply patch\n";
    my $result = system("cd $src_dir && patch -p0 < ../CMakeLists.txt.patch");
    die "FATAL: can't patch geos\n" if $result != 0;

    print "Going to generate Makefile\n";
    my $CFLAGS = $ENV{CFLAGS} // '-g0 -O2 -fPIC';
    local $ENV{CFLAGS} = $ENV{CXXFLAGS} = $CFLAGS;

    my $cmake_flags = join(" ", '-G "Unix Makefiles"', "-DCMAKE_CXX_FLAGS=\"$CFLAGS\"", "-DCMAKE_C_FLAGS=\"$CFLAGS\"",
        qw/
        -DGEOS_ENABLE_TESTS=off
        -DGEOS_ENABLE_INLINE=on
        -DGEOS_BUILD_STATIC=on
        -DGEOS_BUILD_SHARED=off
        -DGEOS_BUILD_CAPI=off
        -DCMAKE_BUILD_TYPE=Release
        /
    );
    print "clags: ", $cmake_flags, "\n";
    rmtree "$src_dir/build" if -d "$src_dir/build";
    mkdir "$src_dir/build" or die("Can't mkdir : $!");
    $result = system("cd $src_dir/build && cmake $cmake_flags ..");
    die "FATAL: can't configure geos cmake\n" if $result != 0;
}

my %params = (
    NAME          => 'CPP::geos',
    VERSION_FROM  => 'lib/CPP/geos.pm',
    ABSTRACT_FROM => 'lib/CPP/geos.pod',
    CPLUS         => 11,
    CLIB          => {
        DIR    => "$src_dir/build",
        FILE   => 'lib/libgeos.a',
        TARGET => '',
    },
    LDFROM => '-Wl,--whole-archive $(OBJECT) -Wl,--no-whole-archive',
    BIN_SHARE     => {
        CPLUS    => 11,
        INCLUDE  => {
            "$src_dir/build/include" => '/',
            "$src_dir/include" => '/',
        },
    },
    realclean => { FILES => [$src_dir, $filename] },
);

write_makefile(%params);
