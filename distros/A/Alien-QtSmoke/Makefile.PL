#!/usr/bin/perl

use strict;
use warnings;

use lib 'lib';
use Alien::QtSmoke;
use Cwd;
use File::Fetch;
use File::Path;
use File::Spec;
use ExtUtils::MakeMaker;

my $CWD = Cwd::cwd(); 

sub fetch_kdebindings {
    my $version = Alien::QtSmoke->version();

    my $downloadDir = File::Spec->catdir( $CWD, 'src' );

    my @mirrors = (
        'http://chernabog.cc.vt.edu/pub/projects',
        'http://ftp.gtlib.cc.gatech.edu/pub',
        'ftp://carroll.aset.psu.edu/pub',
        'http://kde.mirrors.tds.net/pub',
        'http://ibiblio.org/pub/mirrors',
        'ftp://ftp.ussg.iu.edu/pub',
        'http://mirror.cc.columbia.edu/pub/software',
        'http://mirrors.isc.org/pub',
        'ftp://chernabog.cc.vt.edu/pub/projects',
        'ftp://ibiblio.org/pub/mirrors',
        'http://ftp.ussg.iu.edu',
        'ftp://kde.mirrors.tds.net/pub',
        'ftp://ftp.gtlib.cc.gatech.edu/pub',
    );

    foreach my $url ( @mirrors ) {
        $url .= "/kde/stable/$version/src/kdebindings-$version.tar.bz2";

        print "Attempting to download kdebindings source package\n";
        print "from $url\n";
        my $ff = File::Fetch->new( uri => $url ) or next;
        my $loc = $ff->fetch( to => $downloadDir ) or next;

        next if( !$loc || $ff->error() );

        print "Successfully downloaded kdebindings source.\n";
        return $loc;
    }

    die 'Unable to fetch kdebinding source.';
}

sub extract_kdebindings {
    my ( $src ) = @_;
    my $srcDir = File::Spec->catdir( $CWD, 'src' );
    chdir $srcDir;
    system "tar -xf $src";
    if ( ($? >> 8) > 0 ) {
        die "Unable to extract sources: $!\n";
    }
}

sub build_kdebindings {
    my $version = Alien::QtSmoke->version();
    my $prefix = Alien::QtSmoke->prefix();
    my $srcDir = File::Spec->catdir( $CWD, 'src', "kdebindings-$version" );
    my $buildDir = File::Spec->catdir( $srcDir, 'build' );
    my $qtSmokeBuildDir = File::Spec->catdir( $buildDir, 'smoke', 'qt' );

    File::Path::mkpath( $buildDir );
    chdir $buildDir;

    # Just build QtSmoke
    my $cmakeArgs = qq( -DCMAKE_INSTALL_PREFIX=$prefix \\
    -DENABLE_SMOKE=on                                  \\
    -DENABLE_QTRUBY=off                                \\
    -DENABLE_QTWEBKIT_SMOKE=off                        \\
    -DENABLE_QTSCRIPT_SMOKE=off                        \\
    -DENABLE_QTUITOOLS_SMOKE=off                       \\
    -DENABLE_QTTEST_SMOKE=off                          \\
    -DENABLE_PHONON_SMOKE=off                          \\
    -DENABLE_QSCI_SMOKE=off                            \\
    -DENABLE_QWT_SMOKE=off                             \\
    -DENABLE_KDE_SMOKE=off                             \\
    -DENABLE_KDEVPLATFORM_SMOKE=off                    \\
    -DENABLE_KHTML_SMOKE=off                           \\
    -DENABLE_KTEXTEDITOR_SMOKE=off                     \\
    -DENABLE_SOLID_SMOKE=off                           \\
    -DENABLE_PLASMA_SMOKE=off                          \\
    -DENABLE_QTWEBKIT_RUBY=off                         \\
    -DENABLE_QTUITOOLS_RUBY=off                        \\
    -DENABLE_QTSCRIPT=off                              \\
    -DENABLE_QTTEST=off                                \\
    -DENABLE_PHONON_RUBY=off                           \\
    -DENABLE_QSCINTILLA_RUBY=off                       \\
    -DENABLE_QWT_RUBY=off                              \\
    -DENABLE_SOPRANO_RUBY=off                          \\
    -DENABLE_KDEVPLATFORM_RUBY=off                     \\
    -DENABLE_KORUNDUM_RUBY=off                         \\
    -DENABLE_KHTML_RUBY=off                            \\
    -DENABLE_KTEXTEDITOR_RUBY=off                      \\
    -DENABLE_SOLID_RUBY=off                            \\
    -DENABLE_KROSSRUBY=off                             \\
    -DENABLE_PLASMA_RUBY=off                           \\
    -DENABLE_QIMAGEBLITZ_SMOKE=off );
    system "cmake .. $cmakeArgs -Wno-dev";
    if ( ($? >> 8) > 0 ) {
        die "Running cmake failed: $!\n";
    }

    chdir $qtSmokeBuildDir;

    system "make";
    if ( ($? >> 8) > 0 ) {
        die "Compiling QtSmoke failed while running make: $!\n";
    }
    system "make install";
    if ( ($? >> 8) > 0 ) {
        die "Installing QtSmoke failed while running make install: $!\n";
    }
}

sub main {
    my $src = fetch_kdebindings();
    extract_kdebindings( $src );
    chdir $CWD;
    build_kdebindings();

    chdir $CWD;
    WriteMakefile(
        NAME => 'Alien::QtSmoke',
        VERSION_FROM => 'lib/Alien/QtSmoke.pm',
        AUTHOR => 'Chris Burel <chrisburel[at]gmail[dot]com>',
        ABSTRACT => 'Builds the QtSmoke library'
    );
}

main();
