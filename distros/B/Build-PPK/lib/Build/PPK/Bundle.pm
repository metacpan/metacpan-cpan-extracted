package Build::PPK::Bundle;

# Copyright (c) 2018, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Fcntl        ();
use MIME::Base64 ();

use Filesys::POSIX                ();
use Filesys::POSIX::IO::Handle    ();
use Filesys::POSIX::Mem           ();
use Filesys::POSIX::Path          ();
use Filesys::POSIX::Extensions    ();
use Filesys::POSIX::Userland::Tar ();

use Build::PPK::Exec     ();
use Build::PPK::Pipeline ();

use Carp;

sub new {
    my ( $class, $main, $opts ) = @_;

    confess('No main entry point defined') unless $main;
    confess('No output file specified') unless $opts->{'output'};

    return bless {
        'main'    => $main,
        'output'  => $opts->{'output'},
        'header'  => $opts->{'header'},
        'desc'    => $opts->{'desc'},
        'modules' => {},
        'libdirs' => {}
    }, $class;
}

sub _module_path {
    my ($module) = @_;
    my $pat = qr/[a-z0-9_]*/i;

    confess('Invalid module name') unless $module =~ /^$pat(::$pat)*$/i;

    my @path_components = split /::/, $module;
    $path_components[-1] .= '.pm';

    return Filesys::POSIX::Path->full( join( '/', @path_components ) );
}

sub add_module {
    my ( $self, $file, $name ) = @_;
    my $short_module_path  = _module_path($name);
    my $bundle_module_path = "lib/$short_module_path";

    my $libdir = Filesys::POSIX::Path->full($file);
    $libdir =~ s/\/$short_module_path$//;

    $self->{'libdirs'}->{$libdir}             = 1;
    $self->{'modules'}->{$bundle_module_path} = $file;
}

sub add_dist {
    my ( $self, $dist ) = @_;

    confess("Cannot add unprepared dist $dist->{'path'} to bundle") unless $dist->prepared;

    foreach my $path ( @{ $dist->modules } ) {
        my $file = "$dist->{'basedir'}/$path";

        $self->{'modules'}->{$path} = $file;
    }

    $self->{'libdirs'}->{ $dist->libdir } = 1;
}

sub libdirs {
    my ($self) = @_;

    return sort keys %{ $self->{'libdirs'} };
}

sub check {
    my ($self) = @_;

    my @dirs = @INC;
    push @dirs, $self->libdirs;

    local $ENV{'PERL5LIB'} = join( ':', @dirs );

    confess("Main entry point $self->{'main'} not found") unless -f $self->{'main'};

    unless ( Build::PPK::Exec->silent( $^X, '-c', $self->{'main'} ) == 0 ) {
        confess("Errors while checking $self->{'main'}: $@");
    }
}

sub prepare {
    my ($self) = @_;

    my $fs = Filesys::POSIX->new(
        Filesys::POSIX::Mem->new,
        'noatime' => 1
    );

    foreach my $dir (qw(lib scripts)) {
        $fs->mkdir($dir);
    }

    #
    # Map the given main entry point script into scripts/main.pl.
    #
    $fs->map( $self->{'main'}, 'scripts/main.pl' );

    #
    # Map each module dependency into lib/ as appropriate.
    #
    foreach my $bundle_module_path ( keys %{ $self->{'modules'} } ) {
        my $file = $self->{'modules'}->{$bundle_module_path};
        my $path = Filesys::POSIX::Path->new($bundle_module_path);

        $fs->mkpath( $path->dirname );
        $fs->map( $file, $path->full );
    }

    return $fs;
}

sub assemble {
    my ( $self, $fs ) = @_;
    my $stub = File::ShareDir::dist_file( 'Build-PPK', 'stub.pl' );

    my $output_fh;

    unless ( sysopen( $output_fh, $self->{'output'}, &Fcntl::O_CREAT | &Fcntl::O_TRUNC | &Fcntl::O_WRONLY, 0755 ) ) {
        confess("Unable to open $self->{'output'} for writing: $!");
    }

    #
    # Print the Perl shebang.
    #
    print {$output_fh} "#! /usr/bin/perl\n";

    #
    # Check for a header file to include.
    #
    if ( $self->{'header'} ) {
        open( my $header_fh, '<', $self->{'header'} ) or confess("Unable to open $self->{'header'} for reading: $!");

        while ( my $line = readline($header_fh) ) {
            chomp $line;
            $line =~ s/\$Desc\$/\$Desc: $self->{'desc'}\$/g if $self->{'desc'};
            print {$output_fh} "$line\n";
        }

        close $header_fh;
    }

    #
    # Add a newline for style's sake.
    #
    print {$output_fh} "\n";

    #
    # Then, copy the self-executing stub into the output file.
    #
    open( my $stub_fh, '<', $stub ) or confess("Unable to open stub $stub for reading: $!");

    while ( my $len = read( $stub_fh, my $buf, 4096 ) ) {
        print {$output_fh} $buf;
    }

    close $stub_fh;

    #
    # Next, tar up the prepared filesystem, and pass it through gzip, then
    # base64 encoding, while appending the result to the end of the output
    # file.  There's no need to read the end of this pipe, as it is all
    # being dumped to the output file handle anyway.
    #
    my $pipeline = Build::PPK::Pipeline->open(
        sub {
            $fs->tar( Filesys::POSIX::IO::Handle->new( \*STDOUT ), '.' );
        },

        sub {
            exec 'gzip' or confess("Unable to exec() gzip: $!");
        },

        sub {
            while ( my $len = read( STDIN, my $buf, 4047 ) ) {
                print {$output_fh} MIME::Base64::encode_base64($buf);
            }
        }
    );

    $pipeline->close;

    close $output_fh;
}

1;
