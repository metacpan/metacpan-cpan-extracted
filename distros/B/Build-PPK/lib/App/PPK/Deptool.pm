package App::PPK::Deptool;

# Copyright (c) 2018, cPanel, Inc.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Getopt::Long ('GetOptionsFromArray');
use Build::PPK::Deptool ();

my $DEFAULT_DIST_INDEX = 'DIST.INDEX';
my $DEFAULT_PROG_INDEX = 'PROG.INDEX';

my %ACTIONS = (
    'fetch-dist' => {
        'usage' => [
            '[--force] <dist ...>',
            '--deps-for <targets ...>'
        ],

        'handler' => \&fetch_dist
    },

    'list-targets' => {
        'usage'   => undef,
        'handler' => \&list_targets
    },

    'list-target-deps' => {
        'usage'   => '<target ...>',
        'handler' => \&list_target_deps
    }
);

sub usage {
    my ($action) = @_;
    my @actions = $action ? ($action) : sort keys %ACTIONS;

    my $first = 1;

    foreach my $action (@actions) {
        my $usage = $ACTIONS{$action}->{'usage'};
        my @synopses = ref($usage) eq 'ARRAY' ? @{$usage} : ($usage);

        if ($first) {
            print STDERR "usage: ";
        }

        foreach my $synopsis (@synopses) {
            unless ($first) {
                print STDERR "       ";
            }

            print STDERR "$0 $action";
            print STDERR " $synopsis" if $synopsis;
            print STDERR "\n";

            $first = 0;
        }
    }

    exit 1;
}

sub fetch_dist {
    my ( $deptool, @args ) = @_;
    my %opts;
    my @dists;

    GetOptionsFromArray(
        \@args,
        'force'          => \$opts{'force'},
        'deps-for=s@{,}' => \$opts{'targets'}
    );

    if ( $opts{'targets'} ) {
        push @dists, $deptool->target_deps( 'targets' => $opts{'targets'} );
    }
    else {
        push @dists, @args;
    }

    usage('fetch-dist') unless @dists;

    foreach my $dist (@dists) {
        if ( -e $dist ) {
            next unless $opts{'force'};
        }

        my $path = $ENV{'PPK_DISTDIR'} ? "$ENV{'PPK_DISTDIR'}/$dist" : $dist;

        $deptool->fetch_dist(
            'dist'     => $dist,
            'path'     => $path,
            'callback' => sub {
                my (%args) = @_;

                print "fetch $args{'url'} => $args{'path'}\n";
            }
        );
    }

    return 0;
}

sub list_targets {
    my ($deptool) = @_;

    foreach my $target ( $deptool->targets ) {
        print "$target\n";
    }

    return 0;
}

sub list_target_deps {
    my ( $deptool, @targets ) = @_;

    usage('list-target-deps') unless @targets;

    my @deps = $deptool->target_deps( 'targets' => \@targets );

    foreach my $dep (@deps) {
        my $path = $ENV{'PPK_DISTDIR'} ? "$ENV{'PPK_DISTDIR'}/$dep" : $dep;

        print "$path\n";
    }

    return 0;
}

sub run {
    my ( $class, @args ) = @_;
    my $action = shift @args;

    usage() unless $action && $ACTIONS{$action};

    my $deptool = Build::PPK::Deptool->new(
        'dist_index' => $DEFAULT_DIST_INDEX,
        'prog_index' => $DEFAULT_PROG_INDEX
    );

    return $ACTIONS{$action}->{'handler'}->( $deptool, @args );
}
