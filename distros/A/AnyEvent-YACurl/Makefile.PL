use 5.010000;
use ExtUtils::MakeMaker;
use Cwd;

# I realize that having this in Makefile.PL isn't nice... but it's just so much easier.
my $cwd= cwd;
if (! -f "libbrotli-lib/lib/libbrotlidec.a") {
    chdir("libbrotli-src");
    system("./configure",
        "--prefix=$cwd/libbrotli-lib",
        "--disable-shared",
        "--enable-static",
        "--with-pic",
        split(/\s/, $ENV{YACURL_BROTLI_OPTS}||'')
    ) and exit $?;
    system("make") and exit $?;
    system("make", "check") and exit $?;
    system("make", "install") and exit $?;
    chdir("..");
}

if (! -f "nghttp2-lib/lib/libnghttp2.a") {
    chdir("nghttp2-src");
    system("./configure",
        "--prefix=$cwd/nghttp2-lib",
        "--disable-shared",
        "--enable-static",
        "--with-pic",
        "--enable-lib-only",
        split(/\s/, $ENV{YACURL_NGHTTP2_OPTS}||'')
    ) and exit $?;
    system("make") and exit $?;
    system("make", "check") and exit $?;
    system("make", "install") and exit $?;
    chdir("..");
}

if (! -f "c-ares-lib/lib/libcares.a") {
    chdir("c-ares-src");
    system("./configure",
        "--prefix=$cwd/c-ares-lib",
        "--disable-shared",
        "--enable-static",
        "--with-pic",
        "--enable-nonblocking",
        split(/\s/, $ENV{YACURL_CARES_OPTS}||'')
    ) and exit $?;
    system("make") and exit $?;
    system("make", "check") and exit $?;
    system("make", "install") and exit $?;
    chdir("..");
}

if (! -f "curl-lib/lib/libcurl.a") {
    chdir("curl-src");
    system("./configure",
        "--with-zlib",
        "--with-nghttp2=$cwd/nghttp2-lib",
        "--with-brotli=$cwd/libbrotli-lib",
        "--enable-ares=$cwd/c-ares-lib",
        "--disable-shared",
        "--enable-static",
        "--prefix=$cwd/curl-lib",
        "--with-pic",
        "--disable-threaded-resolver",
        "--disable-pthreads",
        split(/\s/, $ENV{YACURL_CURL_OPTS}||'')
    ) and exit $?;
    system("make") and exit $?;
    #system("make", "test") and exit $?;
    system("make", "install") and exit $?;
    chdir("..");
}

my @curl_wantflags= split /\s+/, join " ", (
    `./curl-lib/bin/curl-config --cflags`,
    `./curl-lib/bin/curl-config --static-libs`,
);

my (@libs, @inc, @object, @define);
for my $flag (@curl_wantflags) {
    if (uc substr($flag, 0, 2) eq '-L') {
        push @libs, $flag;
    } elsif (substr($flag, 0, 2) eq '-I') {
        push @inc, $flag;
    } elsif (substr($flag, 0, 2) eq '-D') {
        push @define, $flag;
    } elsif (substr($flag, 0, 1) eq '/') {
        push @object, $flag;
    } else {
        die $flag;
    }
}

WriteMakefile(
    NAME              => 'AnyEvent::YACurl',
    VERSION_FROM      => 'lib/AnyEvent/YACurl.pm', # finds $VERSION
    PREREQ_PM         => {
        "AnyEvent" => "7.0",
    },
    ABSTRACT_FROM     => 'lib/AnyEvent/YACurl.pm', # retrieve abstract from module
    AUTHOR            => 'Tom van der Woerdt <tvdw@cpan.org>',
    LIBS              => ["@libs"], # e.g., '-lm'
    DEFINE            => "@define", # e.g., '-DHAVE_SOMETHING'
    INC               => "-I. @inc", # e.g., '-I. -I/usr/include/other'
    OBJECT            => "\$(O_FILES) @object",
    META_MERGE => {
        'meta-spec' => { version => 2 },
        resources => {
             repository => {
                 type => 'git',
                 url  => 'https://github.com/TvdW/perl-AnyEvent-YACurl.git',
                 web  => 'https://github.com/TvdW/perl-AnyEvent-YACurl',
             },
         },
    },
);
