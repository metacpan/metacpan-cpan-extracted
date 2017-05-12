use 5.10.0;
use ExtUtils::MakeMaker;
use Config;
use English;
use version 0.77;

sub bail($) {
    my $reason = shift;
    warn $reason;
    exit(0);
}

# Patch Festus Hagen rt.cpan.org #79942
# Patch Festus Hagen 1.62.fh1 - rt.cpan.org #82298

my $tl_static = 0;
foreach (@ARGV) {
    $tl_static++  if /^.?.?TAGLIB_STATIC$/i;
}

# Check TagLib (taglib.so) is installed.
# Note that this depends on the search path -- 
# If the one you want is down-path, then modify your
# PATH environment variable, or edit for a fixed path

my $perl_version = substr($PERL_VERSION, 3, 2) < 12 ? ' -DPERLV_LESS_12' : '';

# Patch Festus Hagen rt.cpan.org #79942
if ($Config{'osname'} eq 'MSWin32') {
    bail("\nPlease install the taglib C++ library.\n  taglib-config.cmd needs to be located via the PATH statement.\n")
        unless system('taglib-config --version > NUL') == 0;
} else {
    bail("Please install the taglib C++ library first. \nI need the package that has taglib-config")
        unless system('taglib-config --version > /dev/null') == 0;
}
  
# No guarantees what tatlib-config will say about the number
# version.pm is only in core beginning with 5.10.0
chomp(my $libver = qx{taglib-config --version});
if ( version->parse($libver)->normal < version->parse('v1.11') ) {
    die "Audio::TagLibb requires with taglib 1.11 or greater\nThis is version $libver\n"
}

# Configure compiler
my $CC = 'g++';

# Configure libraries
chomp(my $libs = qx{taglib-config --libs});

# These options eliminate uninteresting warnings
my $xs_options = " -Wno-unused-variable -Wno-unused-but-set-variable -Wformat=0 -Wno-sign-compare -Wno-maybe-uninitialized ";

# Configure compile flags
my $cflags = $Config{'ccflags'} . $perl_version . $xs_options;

# Configure includes
# ./include has a needed .h
chomp(my $inc = qx{taglib-config --cflags});
$inc  = $Config{'incpath'} . '  -I./include ' . $inc;

# Configure ld flags
my $ldd =  $Config{'lddlflags'} . ' ' .
           $Config{'ccdlflags'} . ' ' . $Config{'cccdlflags'};

# Configure various os-es
my $define;
if ( $Config{'osname'} eq 'darwin' ) {
    # _DARWIN added for issue #101294 
    $define = '-D_BSD_ICONV -DNO_DOXYGEN' -D_DARWIN; 
    $libs .= ' -L/System/Library/Perl/lib/'. $Config{version}. ' -lperl -liconv';
}
elsif ( $Config{'osname'} eq 'freebsd' ||  $Config{'osname'} eq 'solaris' ) {
    # 'solaris' added to get _BSD_ICONV defined
    $define = '-D_BSD_ICONV -DNO_DOXYGEN';
# Patch Festus Hagen rt.cpan.org #79942
#   $libs .= ' -liconv';
    if ($tl_static) {
        print "Statically linking with Taglib...\n";
        $define .= ' -DTAGLIB_STATIC';
        $libs .= ' -liconv -lz';
    } else {
        print "Dynamically linking with Taglib...\n";
        $libs .= ' -liconv';
    }
}
elsif ( $Config{'osname'} eq 'MSWin32' ) {
    $define = '-DNO_DOXYGEN';
    if ($tl_static) {
        # Taglib is built Static. (libtag.a)
        print "Statically linking with Taglib...\n";
        $define .= ' -DTAGLIB_STATIC';
        $libs .= ' -llibiconv -llibz';
    } else {
        # Taglib is built Shared. (libtag.dll.a)
        print "Dynamically linking with Taglib...\n";
        # '.dll' must remain as the first element, it gets appended to taglib
        $libs .= '.dll -llibiconv';
    }
}
else {
    # As of v5.22.2 (and perhaps earlier) in the Fedora v23 environ, 
    # the addition of zlib is necessary to remove a problem with the symbol
    # "inflate" being requied. It's not clear where the requirement comes from
    $libs .= ' -lz';
}

#$Verbose = 2;
WriteMakefile(
    NAME              => 'Audio::TagLib',
    MIN_PERL_VERSION  => '5.12.0',
    VERSION_FROM      => 'lib/Audio/TagLib.pm', 
    LICENSE           => 'perl',
    CC                => $CC,
    LD                => '$(CC)',
    XSOPT             => '-C++ -hiertype',
    CCFLAGS           => $cflags,
    LIBS              => $libs, 
    DEFINE            => $define,
    INC               => $inc,
    LDDLFLAGS         => $ldd,
    (
        $Config{'version'} >= 5.005        
        ?                                                     
          (
            ABSTRACT_FROM => 'lib/Audio/TagLib.pm',
            AUTHOR        => 'Geoffrey Leach <gleach@cpan.org>'
          )
        : ()
    ),
    PREREQ_PM => {
        "Encode"         => 0,
        "Test::Deep"     => 0,
        "Test::More"     => 0,
        "Test::Simple"   => 0.99,
    },
     "CONFIGURE_REQUIRES" => {
        "ExtUtils::MakeMaker" => 0,
        "Config"              => 0,
        "version"             => 0.77,
    },
    "META_MERGE" => {
        "no_index" => {
            "directory" => "lib/Audio/TagLib",
        }
    }
);

