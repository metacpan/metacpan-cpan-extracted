use strict;
use warnings;

use Alien::cmake3;
use Alien::patch;
use Archive::Tar;
use Digest::SHA1;
use Env qw/@PATH/;
use HTTP::Tiny;
use File::Path qw/rmtree/;
use XS::Install;

my $version       = '1.0.7';
my $sha1_checksum = 'ee64a380152aa20fbc1098fe3799104884c570c1';

my $filename = "libbrotli-${version}.tar.gz";
my $src_dir  = "brotli-${version}";
my $url      = "https://github.com/google/brotli/archive/v${version}.tar.gz";

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

if (not -e "${filename}") {
    print "Downloading $url\n";
    my $res = HTTP::Tiny->new->get($url);
    if (!$res->{success}) {
        die $res->{reason} // "There was a problem downloading $url";
    }
    my $file = IO::File->new($filename, "w");
    die("error saving file: $!") unless $file;
    $file->binmode;
    print $file $res->{content};
}
check_digest();

print "Unpacking $filename\n";
my $tar = Archive::Tar->new;
$tar->read($filename);
$tar->extract;

if (! -f "$src_dir/libbrotli-static.a"){
    print "Going to apply patch\n";
    my $patch_flags = $^O eq 'MSWin32' ? '--binary -p0' : '-p0';
    unshift @PATH, Alien::cmake3->bin_dir;
    unshift @PATH, Alien::patch->bin_dir;
    my $result = system("cd $src_dir && patch $patch_flags -i ../CMakeLists.txt.patch");
    die "FATAL: can't patch geos\n" if $result != 0;

    print "Going to generate Makefile\n";
    my $CFLAGS = $ENV{CFLAGS} // '-O2 -fPIC';
    local $ENV{CFLAGS} = $ENV{CXXFLAGS} = $CFLAGS;

    my $cmake_flags = join(" ", '-G "Unix Makefiles"', "-DCMAKE_C_FLAGS=\"$CFLAGS\"",
        qw/
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
    NAME   => 'Alien::libbrotli',
    LDFROM => '-Wl,--whole-archive $(OBJECT) -Wl,--no-whole-archive',
    CLIB   => {
        DIR    => "$src_dir/build",
        FILE   => 'libbrotli-static.a',
        TARGET => 'brotli-static',
    },
    BIN_SHARE => {
        INCLUDE  => {
            "$src_dir/c/include/" => '/',
        },
    },
    CONFIGURE_REQUIRES => {
        "XS::Install"           => '1.2.12',
        "ExtUtils::MakeMaker"   => '6.52',
        "Archive::Tar"          => 0,
        "Digest::SHA1"          => 0,
        "HTTP::Tiny"            => 0,
        "File::Path"            => 0,
        "Alien::cmake3"         => '0.04',
        "Alien::patch"          => '0.14',
    },
    realclean => { FILES => [$src_dir, $filename] },
);

write_makefile(%params);
