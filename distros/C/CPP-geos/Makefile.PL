use strict;
use warnings;

use Alien::cmake3;
use Alien::patch;
use Archive::Tar;
use Digest::SHA1;
use Env qw/@PATH/;
use File::Fetch;
use File::Path qw/rmtree/;
use XS::Install;

my $version       = '3.7.2';
my $sha1_checksum = '1b6ec9c197fb4b0ddb96fb192e2f6924a1fbb269';

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

if (not -e "./${filename}") {
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
    my $patch_flags = $^O eq 'MSWin32' ? '--binary -p0' : '-p0';
    unshift @PATH, Alien::cmake3->bin_dir;
    unshift @PATH, Alien::patch->bin_dir;
    my $result = system("cd $src_dir && patch $patch_flags -i ../CMakeLists.txt.patch");
    die "FATAL: can't patch geos\n" if $result != 0;

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
    $result = system("cd $src_dir/build && cmake $cmake_flags ..");
    die "FATAL: can't configure geos cmake\n" if $result != 0;
}

my %params = (
    NAME   => 'CPP::geos',
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
        "ExtUtils::MakeMaker"   => '6.52',
        "Archive::Tar"          => 0,
        "Digest::SHA1"          => 0,
        "File::Fetch"           => 0,
        "File::Path"            => 0,
        "Alien::cmake3"         => '0.04',
        "Alien::patch"          => '0.14',
    },
    realclean => { FILES => [$src_dir, $filename] },
);

write_makefile(%params);
