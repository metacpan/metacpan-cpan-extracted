package App::PPK;

# Copyright (c) 2012, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Getopt::Long qw(:config no_ignore_case no_auto_abbrev);
use Build::PPK ();

use Carp ('confess');

sub usage {
    my ($message) = @_;

    print STDERR "$message\n" if $message;
    print STDERR "usage: $0 main.pl [options] [-o output]\n";
    print STDERR "       $0 main.pl [options] -c\n";

    exit 1;
}

sub read_depfile {
    my ( $class, $file ) = @_;
    my %modules;
    my @dists;

    my $fh;

    if ( $file eq '-' ) {
        $fh = \*STDIN;
    }
    else {
        open( $fh, '<', $file ) or confess("Unable to open dependency file $file for reading: $!");
    }

    while ( my $line = readline($fh) ) {
        chomp $line;

        next if $line =~ /^\s*(#|$)/;

        my ( $command, $args ) = split /\s+/, $line, 2;

        if ( $command eq 'module' ) {
            my ( $module, $file ) = split /\s+/, $args, 2;
            $modules{$module} = $file;
        }
        elsif ( $command eq 'dist' ) {
            push @dists, $args;
        }
        else {
            confess("Syntax error: Unknown specifier '$command'");
        }
    }

    close $fh unless $file eq '-';

    return {
        'modules' => \%modules,
        'dists'   => \@dists
    };
}

sub parse_opts {
    my ($class) = @_;
    my @modules;

    my $opts = {
        'output'  => 'ppk.out',
        'modules' => {},
        'dists'   => []
    };

    GetOptions(
        'check|c'         => \$opts->{'check'},
        'output|o=s'      => \$opts->{'output'},
        'dists|d=s@{,}'   => \$opts->{'dists'},
        'deps-from=s'     => \$opts->{'depfile'},
        'header|H=s'      => \$opts->{'header'},
        'desc|D=s'        => \$opts->{'desc'},
        'modules|m=s@{,}' => \@modules
    ) or usage();

    usage('No main entry point script specified') unless $opts->{'main'} = $ARGV[0];
    usage('Cannot check a script while compiling')             if $opts->{'check'} && $opts->{'output'};
    usage('Desc can only be passed when a header is provided') if $opts->{'desc'}  && !$opts->{'header'};

    #
    # If --deps-from is specified, then open the file passed and parse each line
    # in a special format described in the POD for ppk(1).
    #
    if ( $opts->{'depfile'} ) {
        my $deps    = $class->read_depfile( $opts->{'depfile'} );
        my $modules = $deps->{'modules'};
        my $dists   = $deps->{'dists'};

        push @{ $opts->{'dists'} }, @{$dists};
        %{ $opts->{'modules'} } = %{$modules};
    }

    #
    # Any module dependencies specified from a --deps-from file can of course
    # be overridden here.
    #
    foreach my $dependency (@modules) {
        my ( $file, $module ) = split /=/, $dependency, 2;

        usage("No module name was specified for module file $file") unless $module;

        $opts->{'modules'}->{$module} = $file;
    }

    return $opts;
}

sub run {
    my ($class) = @_;
    my $opts = $class->parse_opts;

    Build::PPK->build( $opts->{'main'}, $opts );

    return 0;
}

1;
