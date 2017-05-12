package inc::MyBuilder;
use strict;
use warnings FATAL => 'all';
use base qw(Module::Build);

use Fatal qw(open);
use List::Util qw(first);
use Carp;
use Config;
use Cwd;
use File::Path;
use File::Find;

use File::chdir;
use File::Which;

my @pkg_config_path = qw(
    /usr/local/lib/pkgconfig
    /usr/lib64/pkgconfig
    /usr/lib/pkgconfig
    /opt/X11/lib/pkgconfig
);


sub xsystem {
    my(@args) = @_;
    print "->> ", join(' ', @args), "\n";
    system(@args) == 0 or croak "Failed to system(@args): $!";
}

sub ACTION_manpages {
    # doesn't create man pages
}

sub ACTION_code { # default action
    my($self, @args) = @_;

    my $prefix    = $CWD . '/' . $self->notes('installdir');
    mkpath($prefix);

    my $bindir = $self->install_destination('bin');
    {
        local $CWD = $self->notes('name');

        local $ENV{PERL} = $self->perl;
        local $ENV{CC}   = $ENV{CC} || $self->maybe_ccache();
        local $ENV{PKGCONFIG} = ($ENV{PKGCONFIG} || which('pkg-config')) or die "no pkg-config(1) found in path.\n";
        local $ENV{PKG_CONFIG_PATH} = join(':', (split /:/, $ENV{PKG_CONFIG_PATH} || ''), @pkg_config_path);
        xsystem(
            './configure',

            "--prefix=$prefix",
            "--bindir=$bindir",
            "--enable-perl-site-install",

            "--disable-tcl",
            "--disable-rrdcgi",
            "--disable-perl", # install by myself
            "--disable-lua",
            "--disable-python",
            "--disable-ruby",
            "--disable-shared",
        ) unless -f 'Makefile';

        xsystem($Config{make});
        xsystem($Config{make}, 'install');
    }

    my @libdirs = $self->find_libdirs();

    my $libs = do {
        open my $fh, '<', $self->notes('name') . '/Makefile';

        my $libs = '';
        while(<$fh>) {
            if(/ALL_LIBS \s+ = \s+ (.+) /xms) {
                chomp($libs = $1);
            }
        }
        join ' ', (map { "-L$_" } @libdirs),  $libs;
    };

    my $rpath = Cwd::abs_path($self->notes('name') . '/src/.libs') or die;

    $self->perl_bindings(sub {
        xsystem($self->perl,
            'Makefile.PL',
            "LIBS=$libs",
            "RPATH=$rpath");
        xsystem($Config{make});
    });

    $self->SUPER::ACTION_code(@args);
}

sub ACTION_test {
    my($self, @args) = @_;

    $self->ACTION_code();

    $self->perl_bindings(sub {
        xsystem($Config{make}, 'test');
    });

    $self->SUPER::ACTION_test(@args);
}


sub ACTION_install {
    my($self, @args) = @_;

    $self->perl_bindings(sub {
        xsystem($Config{make}, 'install');
    });

    $self->SUPER::ACTION_install(@args);
}

sub ACTION_clean {
    my($self, @args) = @_;

    # work around Module::Build's bug that removing symlinks might fail
    unlink('rrdtool');
    $self->SUPER::ACTION_clean(@args);
}

sub perl_bindings {
    my($self, $block) = @_;
    for my $path(
            $self->binding_dir('perl-shared'),
            $self->binding_dir('perl-piped')) {

        local $CWD = $path;
        print "In $path:\n";

        $block->();
    }
    return;
}


sub binding_dir {
    my($self, $name) = @_;

    return $self->notes('name') . '/bindings/' . $name;
}

sub maybe_ccache {
    my $cc = $Config{cc};

    return $cc if $cc =~ /ccache/;

    my $ccache = which('ccache');
    return $ccache ? "ccache $cc" : $cc;
}

sub find_libdirs {
    my @dirs = qw(/usr/local/lib /opt/X11/lib);
    return @dirs;
}

1;
