use 5.016003;
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;

my ($inc, $libs) = detect_liboqs();

unless (-f 'ppport.h') {
    require Devel::PPPort;
    Devel::PPPort::WriteFile();
}

WriteMakefile(
    NAME          => 'Crypt::Liboqs::Sign',
    VERSION_FROM  => 'lib/Crypt/Liboqs/Sign.pm',
    ABSTRACT_FROM => 'lib/Crypt/Liboqs/Sign.pm',
    AUTHOR        => 'Pavel Gulchuk <gul@gul.kiev.ua>',
    LICENSE       => 'perl_5',
    MIN_PERL_VERSION => '5.016003',
    INC           => $inc,
    LIBS          => [$libs],
    PREREQ_PM     => {},
    TEST_REQUIRES => {
        'Test::More' => 0,
    },
    META_MERGE    => {
        'meta-spec' => { version => 2 },
        resources   => {
            repository => {
                type => 'git',
                url  => 'https://github.com/pgul/Crypt-Liboqs-Sign.git',
                web  => 'https://github.com/pgul/Crypt-Liboqs-Sign',
            },
            bugtracker => {
                web => 'https://github.com/pgul/Crypt-Liboqs-Sign/issues',
            },
        },
    },
    clean => { FILES => 'Crypt-Liboqs-Sign-*' },
);

sub detect_liboqs {
    my $inc  = '';
    my $libs = '-loqs';

    # Try pkg-config first
    my $pc_cflags = `pkg-config --cflags liboqs 2>/dev/null`;
    my $pc_libs   = `pkg-config --libs liboqs 2>/dev/null`;
    if ($? == 0 && $pc_libs) {
        chomp $pc_cflags;
        chomp $pc_libs;
        print "Found liboqs via pkg-config\n";
        print "  CFLAGS: $pc_cflags\n";
        print "  LIBS:   $pc_libs\n";
        return ($pc_cflags, $pc_libs);
    }

    # Try common installation paths
    my @search_paths = (
        '/usr/local',
        '/usr',
        '/opt/local',
        '/opt/homebrew',
        '/usr/local/opt/liboqs',
    );

    for my $prefix (@search_paths) {
        if (-f "$prefix/include/oqs/oqs.h" &&
            (-f "$prefix/lib/liboqs.so" || -f "$prefix/lib/liboqs.dylib" || -f "$prefix/lib/liboqs.a"))
        {
            print "Found liboqs in $prefix\n";
            $inc  = "-I$prefix/include";
            $libs = "-L$prefix/lib -loqs";
            return ($inc, $libs);
        }
    }

    die <<'ERROR';

*************************************************************
liboqs not found!

Please install liboqs before building this module:

  # Debian/Ubuntu:
  apt install liboqs-dev

  # macOS with Homebrew:
  brew install liboqs

  # macOS with MacPorts:
  port install liboqs

  # From source:
  git clone https://github.com/open-quantum-safe/liboqs.git
  cd liboqs && mkdir build && cd build
  cmake -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr/local ..
  make -j$(nproc) && sudo make install
*************************************************************

ERROR
}
