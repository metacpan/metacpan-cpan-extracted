use strict;
use warnings;
use inc::Devel::CheckLib;
use Cwd ();
use ExtUtils::MakeMaker;
use File::Spec;

if ( -e 'MANIFEST.SKIP' ) {
    system('pod2text lib/Alien/Libevent.pm > README');
}

if ( $^O eq 'MSWin32' ) {
    print STDERR "Win32 is currently not supported";
    exit(0);
}

my $CWD  = Cwd::cwd();
my $DIST = File::Spec->catfile(qw(lib Alien Libevent.pm));
my $PKG  = File::Spec->catfile(qw(src libevent-1.4.13-stable.tar.gz));
my $SRC  = File::Spec->catfile(qw(src libevent-1.4.13-stable));

$_ = File::Spec->rel2abs($_) for $PKG, $SRC, $DIST;

my $VERSION = do {
    require ExtUtils::MM_Unix;
    ExtUtils::MM_Unix->parse_version($DIST);
};
my $LIBEVENT_VERSION = '1.4.13';

my $CCFLAGS = $ENV{CCFLAGS} || '-I/usr/local/include';
my $LDFLAGS = $ENV{LDFLAGS} || '-L/usr/local/lib';

eval { Devel::CheckLib::assert_lib( lib => "event", LIBS => $LDFLAGS ) };

my $install_libevent = 1;
if ( !$@ ) {
    print <<EOF;

*** We've detected an existing installation of libevent ***

That existing installation of libevent may have been installed before by:

  * your distributions packaging system
  * previous installation of Alien::Libevent
  * compiling/installing it manually from source

Because Alien::Libevent may have been called to be installed from a dependency
of another module, we want to make sure that you *really* want to install
this version of libevent.

If you answer "y", then we're going to install
    libevent:         $LIBEVENT_VERSION
    Alient::Libevent: $VERSION

If you answer "n", then we're going to install
    Alient::Libevent: $VERSION

This operation may OVERWRITE your previous installation, you've been warned!

EOF
    my $yn = prompt( "Really install?", "n" );
    if ( $yn !~ /^y(?:es)?$/ ) {
        $install_libevent = 0;
    }
}

if ($install_libevent) {
    extract( $PKG => $SRC );
    run_configure( libevent => $SRC );
}

WriteMakefile(
    ABSTRACT           => 'Wrapper for installing libevent v1.4.13',
    AUTHOR             => 'Johannes Plunien <plu@cpan.org>',
    CCFLAGS            => $CCFLAGS,
    LDFLAGS            => $LDFLAGS,
    NAME               => 'Alien-Libevent',
    CONFIGURE_REQUIRES => {
        'File::Spec'   => 0,
        'Archive::Tar' => 0,
        'IO::Zlib'     => 0,
    },
    VERSION => $VERSION,
);

print "Everything ready, now type 'make'\n";

sub extract {
    my ( $archive, $destination ) = @_;

    eval {
        require Archive::Tar;
        chdir File::Spec->catfile( $CWD, 'src' );
        print "Unpacking $archive\n";
        Archive::Tar->extract_archive( $archive, 1 );
    };

    chdir $CWD;

    if ($@) {
        print STDERR "Failed to extract file $archive\n";
        exit 0;
    }
}

sub run_configure {
    my ( $name, $destination ) = @_;

    my $prefix = prompt( "Where would you like to install ${name}?", "/usr/local" );
    my $configure_args = '';
    $configure_args .= "--prefix=$prefix " if $prefix;

    $configure_args .= prompt("Are there any other arguments you would like to pass to configure?");

    print "\n$name will be configured with the following arguments:\n", "  $configure_args\n";

    chdir $destination;

    local $ENV{CFLAGS}  = $CCFLAGS;
    local $ENV{LDFLAGS} = $LDFLAGS;
    my @cmd = ( File::Spec->catfile( $destination, "configure" ), split( /\s+/, $configure_args ) );
    if ( system(@cmd) != 0 ) {
        print <<EOF;
configure $configure_args failed: $!
    Something went wrong with the $name configuration.
    You should correct it and re-run Makefile.PL.
EOF
        chdir $CWD;
        exit 0;
    }
    chdir $CWD;
}

package MY;

sub top_targets {
    my $inherited = shift->SUPER::top_targets(@_);
    return $inherited unless $install_libevent;
    $inherited =~ s/^all :: /all :: libevent /;
    return $inherited;
}

sub constants {
    my $inherited = shift->SUPER::constants(@_);
    return $inherited unless $install_libevent;
    $inherited .= "LIBEVENT_SRC=$SRC\n";
    return $inherited;
}

sub postamble {
    my $make_str = '';

    return $make_str unless $install_libevent;

    $make_str = <<'MAKE_FRAG';

libevent:
	cd $(LIBEVENT_SRC) && $(MAKE) all

install::
	cd $(LIBEVENT_SRC) && $(MAKE) install

MAKE_FRAG

    return $make_str;
}
