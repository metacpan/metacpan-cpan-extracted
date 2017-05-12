package My::Judy::Builder;

use strict;

use Module::Build;
use vars qw( @ISA $Orig_CWD );
@ISA = 'Module::Build';

use Config     ();
use File::Spec ();
use File::Path ();
use File::Copy ();
use Cwd        ();

$Orig_CWD = Cwd::cwd();

sub _chdir_to_judy {
    chdir 'src/judy-1.0.5'
        or die "Can't chdir to src/judy-1.0.5: $!";
    return;
}

sub _chdir_back {
    chdir $Orig_CWD
        or die "Can't chdir to $Orig_CWD: $!";
    return;
}

use constant MAKE => [];

sub _run {
    my($self, $prog, @args) = @_;
    
    $prog = $self->notes('your_make') if $prog eq MAKE();
    
    return system( "$prog @args" ) == 0 ? 1 : 0;
}


sub _run_judy_configure {
    my ($self) = @_;
    
    if ( $self->notes('build_judy') =~ /^y/i ) {
        _chdir_to_judy();
        
        $self->_run( './configure', $self->notes('configure_args') )
            or do {
                warn "configuring Judy failed";
                return 0;
            };
        
        _chdir_back();
	
	return 1;
    }
    else {
	return 1;
    }
}

sub _default_config_args {
    my ($self) = @_;

=pod
$ src/Judy-1.0.5/configure -h
`configure' configures Judy 1.0.5 to adapt to many kinds of systems.

Usage: ./configure [OPTION]... [VAR=VALUE]...

To assign environment variables (e.g., CC, CFLAGS...), specify them as
VAR=VALUE.  See below for descriptions of some of the useful variables.

Defaults for the options are specified in brackets.

Configuration:
  -h, --help              display this help and exit
      --help=short        display options specific to this package
      --help=recursive    display the short help of all the included packages
  -V, --version           display version information and exit
  -q, --quiet, --silent   do not print `checking...' messages
      --cache-file=FILE   cache test results in FILE [disabled]
  -C, --config-cache      alias for `--cache-file=config.cache'
  -n, --no-create         do not create output files
      --srcdir=DIR        find the sources in DIR [configure dir or `..']

Installation directories:
  --prefix=PREFIX         install architecture-independent files in PREFIX
    [/usr/local]
  --exec-prefix=EPREFIX   install architecture-dependent files in EPREFIX
    [PREFIX]

By default, `make install' will install all the files in
`/usr/local/bin', `/usr/local/lib' etc.  You can specify
an installation prefix other than `/usr/local' using `--prefix',
for instance `--prefix=$HOME'.

For better control, use the options below.

Fine tuning of the installation directories:
  --bindir=DIR           user executables [EPREFIX/bin]
  --sbindir=DIR          system admin executables [EPREFIX/sbin]
  --libexecdir=DIR       program executables [EPREFIX/libexec]
  --sysconfdir=DIR       read-only single-machine data [PREFIX/etc]
  --sharedstatedir=DIR   modifiable architecture-independent data [PREFIX/com]
  --localstatedir=DIR    modifiable single-machine data [PREFIX/var]
  --libdir=DIR           object code libraries [EPREFIX/lib]
  --includedir=DIR       C header files [PREFIX/include]
  --oldincludedir=DIR    C header files for non-gcc [/usr/include]
  --datarootdir=DIR      read-only arch.-independent data root [PREFIX/share]
  --datadir=DIR          read-only architecture-independent data [DATAROOTDIR]
  --infodir=DIR          info documentation [DATAROOTDIR/info]
  --localedir=DIR        locale-dependent data [DATAROOTDIR/locale]
  --mandir=DIR           man documentation [DATAROOTDIR/man]
  --docdir=DIR           documentation root [DATAROOTDIR/doc/judy]
  --htmldir=DIR          html documentation [DOCDIR]
  --dvidir=DIR           dvi documentation [DOCDIR]
  --pdfdir=DIR           pdf documentation [DOCDIR]
  --psdir=DIR            ps documentation [DOCDIR]

Program names:
  --program-prefix=PREFIX            prepend PREFIX to installed program names
  --program-suffix=SUFFIX            append SUFFIX to installed program names
  --program-transform-name=PROGRAM   run sed PROGRAM on installed program names

System types:
  --build=BUILD     configure for building on BUILD [guessed]
  --host=HOST       cross-compile to build programs to run on HOST [BUILD]

Optional Features:
  --disable-FEATURE       do not include FEATURE (same as --enable-FEATURE=no)
  --enable-FEATURE[=ARG]  include FEATURE [ARG=yes]
  --enable-maintainer-mode  enable make rules and dependencies not useful
    (and sometimes confusing) to the casual installer
  --enable-debug          enable debugging features
  --enable-ccover         enable use of ccover code coverage tools
  --disable-dependency-tracking  speeds up one-time build
  --enable-dependency-tracking   do not reject slow dependency extractors
  --enable-32-bit          Generate code for a 32-bit environment
  --enable-64-bit          Generate code for a 64-bit environment
  --enable-shared[=PKGS]  build shared libraries [default=yes]
  --enable-static[=PKGS]  build static libraries [default=yes]
  --enable-fast-install[=PKGS]
                          optimize for fast installation [default=yes]
  --disable-libtool-lock  avoid locking (might break parallel builds)
  --enable-build-warnings    Enable build-time compiler warnings for gcc

Optional Packages:
  --with-PACKAGE[=ARG]    use PACKAGE [ARG=yes]
  --without-PACKAGE       do not use PACKAGE (same as --with-PACKAGE=no)
  --with-gnu-ld           assume the C compiler uses GNU ld [default=no]
  --with-pic              try to use only PIC/non-PIC objects [default=use
                          both]
  --with-tags[=TAGS]      include additional configurations [automatic]

Some influential environment variables:
  CC          C compiler command
  CFLAGS      C compiler flags
  LDFLAGS     linker flags, e.g. -L<lib dir> if you have libraries in a
              nonstandard directory <lib dir>
  LIBS        libraries to pass to the linker, e.g. -l<library>
  CPPFLAGS    C/C++/Objective C preprocessor flags, e.g. -I<include dir> if
              you have headers in a nonstandard directory <include dir>
  CPP         C preprocessor
  CXX         C++ compiler command
  CXXFLAGS    C++ compiler flags
  CXXCPP      C++ preprocessor
  F77         Fortran 77 compiler command
  FFLAGS      Fortran 77 compiler flags

Use these variables to override the choices made by `configure' or to help
it to find libraries and programs with nonstandard names/locations.

Report bugs to <dougbaskins@yahoo.com>.
=cut

    my $bin  = $self->install_destination('bin');

    my $archbase = $self->install_destination('arch')
        or confess("Can't get install_destination(arch)");
    my $arch =
        File::Spec->catdir(
            $archbase,
            'Alien',
            'Judy'
        );

    my $man3 = $self->install_destination('libdoc');
    my $man;
    if ( $man3 ) {
        $man =
            Cwd::abs_path(
                File::Spec->catdir(
                    $man3,
                    '..'
                )
            );
    }

    my $html3 = $self->install_destination('libhtml');
    my $html;
    if ( $html3 ) {
        $html =
            Cwd::abs_path(
                File::Spec->catdir(
                    $html3,
                    '..'
                )
            );
    }

    my %args = (
        sysconfdir     => $arch,
        sharedstatedir => $arch,
        localstatedir  => $arch,
        libdir         => $arch,
        includedir     => $arch,
        oldincludedir  => $arch,
        datarootdir    => $arch,
        datadir        => $arch,

        $bin ? ( bindir     => $bin,
                 sbindir    => $bin,
                 libexecdir => $bin )
             : (),
        $man ? ( mandir => $man )
             : (),
        $html ? ( htmldir => $html )
              : (),
    );
    
    return
        join ' ',
        map { "--$_=$args{$_}" }
        sort
        keys %args;
}

sub ACTION_code {
    my ($self) = @_;

    if ( $self->notes('build_judy') =~ /^y/i ) {
        $self->SUPER::ACTION_code();

        _chdir_to_judy();
        
        $self->_run(MAKE())
            or do {
                warn "building Judy failed";
                _chdir_back();
                return 0;
            };

        # "Install" a minor copy of Judy.h and libJudy.so to my own
        # blib/arch/Alien/Judy because it looks like some CPAN smokers
        # don't install dependencies but just adjust @INC to point
        # into depended-on- blib/* directories.
        my $alien = File::Spec->catdir( $Orig_CWD, 'blib', 'arch', 'Alien', 'Judy' );
        File::Path::make_path( $alien );
        my @files = (
            'src/Judy.h',
            glob('src/obj/.libs/*'),
        );
        for my $file ( @files ) {
            File::Copy::copy( $file, $alien );
        }

        _chdir_back();

        return 1;
    }
    else {
	return $self->SUPER::ACTION_code();
    }
}


sub ACTION_test {
    my ($self) = @_;
    
    if ( $self->notes('build_judy') =~ /^y/i ) {
        $self->SUPER::ACTION_test();
    
        _chdir_to_judy();
        
        $self->_run( MAKE(), 'check' )
            or do {
                warn "checking Judy failed ";
                _chdir_back();
                return 0;
            };
        
        _chdir_back();

        return 1;
    }
    else {
        return $self->SUPER::ACTION_test();
    }
}

sub ACTION_install {
    my ($self) = @_;
    
    if ( $self->notes('build_judy') =~ /^y/i ) {
        $self->SUPER::ACTION_install();

        _chdir_to_judy();
        
        $self->_run( MAKE(), 'install' )
            or do {
                warn "installing Judy failed ";
                _chdir_back();
                return 0;
            };
        
        _chdir_back();

        return 1;
    }
    else {
        return $self->SUPER::ACTION_install();
    }
}

sub ACTION_clean {
    my ( $self ) = @_;

    $self->SUPER::ACTION_clean();

    print STDERR <<'ACTION_clean';
This may fail. Sorry. It's just the libJudy library. It can provide a Makefile
without being able to use it for `make clean'.
ACTION_clean

    my $ok = eval {
        _chdir_to_judy();
        $self->_run(  MAKE(), 'clean' );
        1;
    };
    my $failure_msg = $@;
    _chdir_back();

    if ( ! $ok ) {
        print STDERR $failure_msg;
    }

    return;
}

sub ACTION_realclean {
    my ( $self ) = @_;

    $self->SUPER::ACTION_clean();

    print STDERR <<'ACTION_realclean';
This may fail. Sorry. It's just the libJudy library. It can provide a Makefile
without being able to use it for `make clean'.
ACTION_realclean

    my $ok = eval {
        _chdir_to_judy();
        $self->_run(  MAKE(), 'distclean' );
        1;
    };
    my $failure_msg = $@;
    _chdir_back();

    if ( ! $ok ) {
        print STDERR $failure_msg;
    }

    return;
}

sub ACTION_distclean {
    my ( $self ) = @_;

    $self->SUPER::ACTION_clean();

    print STDERR <<'ACTION_distclean';
This may fail. Sorry. It's just the libJudy library. It can provide a Makefile
without being able to use it for `make clean'.
ACTION_distclean

    my $ok = eval {
        _chdir_to_judy();
        $self->_run(  MAKE(), 'distclean' );
        1;
    };
    my $failure_msg = $@;
    _chdir_back();

    if ( ! $ok ) {
        print STDERR $failure_msg;
    }

    return;
}

1;
