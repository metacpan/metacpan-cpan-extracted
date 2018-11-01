package Build::PPK::Dist;

# Copyright (c) 2018, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use POSIX ();

use Cwd        ();
use File::Temp ();
use File::Find ();

use Build::PPK::Exec ();

use Carp ('confess');

sub new {
    my ( $class, $path ) = @_;

    return bless {
        'unpacked' => 0,
        'prepared' => 0,
        'path'     => Cwd::realpath($path),
        'dirs'     => []
    }, $class;
}

sub DESTROY {
    shift->cleanup;
}

sub pushd {
    my ( $self, $dir ) = @_;
    my $cwd = Cwd::getcwd() or confess("Unable to get current working directory: $!");

    push @{ $self->{'dirs'} }, $cwd;

    chdir($dir) or confess("Unable to change current working directory to $dir: $!");

    return $dir;
}

sub popd {
    my ($self) = @_;
    return unless @{ $self->{'dirs'} };

    my $dir = pop @{ $self->{'dirs'} };
    chdir($dir) or confess("Unable to change current working directory to $dir: $!");
    return $dir;
}

sub _find_dist_base {
    my ( $self, $distdir ) = @_;
    my @dirs;

    confess("$distdir is not a directory") unless -d $distdir;

    push @dirs, $distdir;

    while ( defined( my $dir = pop @dirs ) ) {
        opendir( my $dh, $dir ) or confess("Unable to opendir() on $dir: $!");

        while ( defined( my $item = readdir($dh) ) ) {
            next if $item eq '.' || $item eq '..';

            my $path = "$dir/$item";
            stat $path;

            if ( ( -d _ && $item eq 'lib' ) || ( -f _ && $item =~ /^(?:Makefile\.PL|MANIFEST)$/ ) ) {
                closedir $dh;
                return $dir;
            }
            elsif ( -d _ ) {
                push @dirs, $path;
            }
        }

        closedir $dh;
    }

    confess("Could not find lib/, Makefile.PL or MANIFEST anywhere within $self->{'path'}");
}

sub unpack {
    my ($self) = @_;

    return $self if $self->{'unpacked'};

    if ( -d $self->{'path'} ) {
        $self->{'basedir'} = $self->_find_dist_base( $self->{'path'} );

        return $self;
    }

    $self->{'tmpdir'} = File::Temp::mkdtemp('/tmp/.ppk-XXXXXX') or confess("Failed mkdtemp(): $!");

    pipe my ( $error_out, $error_in ) or confess("Unable to pipe(): $!");
    my $pid = fork();

    if ( $pid == 0 ) {
        close STDIN;
        close STDOUT;

        POSIX::dup2( fileno($error_in), fileno(STDERR) ) or confess("Unable to dup2(): $!");

        chdir $self->{'tmpdir'} or confess("Unable to chdir() to $self->{'tmpdir'}: $!");
        exec qw(tar pzxf), $self->{'path'};
    }
    elsif ( !defined($pid) ) {
        confess("Unable to fork(): $!");
    }

    waitpid( $pid, 0 );

    $self->{'basedir'}  = $self->_find_dist_base( $self->{'tmpdir'} );
    $self->{'unpacked'} = 1;

    return $self;
}

sub build {
    my ($self) = @_;

    $self->pushd( $self->{'basedir'} );

    Build::PPK::Exec->silent( $^X, 'Makefile.PL' ) == 0 or confess("Unable to run Makefile.PL: $@");
    Build::PPK::Exec->silent('make') == 0 or confess("Unable to build distribution with GNU make: $@");

    $self->popd;

    return $self;
}

sub prepare {
    my ($self) = @_;

    return $self if $self->{'prepared'};

    $self->unpack;

    unless ( -d "$self->{'basedir'}/lib" ) {
        $self->build;
        $self->{'basedir'} .= '/blib';
    }

    $self->{'libdir'}   = "$self->{'basedir'}/lib";
    $self->{'prepared'} = 1;

    return $self;
}

sub prepared {
    return shift->{'prepared'};
}

sub libdir {
    return shift->{'libdir'};
}

sub modules {
    my ($self) = @_;
    my @modules;

    $self->pushd( $self->{'basedir'} );

    File::Find::find(
        {
            'no_chdir' => 1,
            'wanted'   => sub {
                return unless -f $File::Find::name;
                return unless $File::Find::name =~ /\.pm$/;

                push @modules, $File::Find::name;
              }
        },
        'lib'
    );

    $self->popd;

    return \@modules;
}

sub cleanup {
    my ($self) = @_;

    return unless $self->{'tmpdir'};
    return unless -d $self->{'tmpdir'};

    File::Find::finddepth(
        {
            'no_chdir' => 1,
            'wanted'   => sub {
                if ( -d $File::Find::name ) {
                    rmdir $File::Find::name;
                }
                else {
                    unlink $File::Find::name;
                }
              }
        },
        $self->{'tmpdir'}
    );

    delete $self->{'tmpdir'};
}

1;
