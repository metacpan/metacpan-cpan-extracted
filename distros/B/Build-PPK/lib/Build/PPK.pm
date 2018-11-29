package Build::PPK;

# Copyright (c) 2018, cPanel, L.L.C.
# All rights reserved.
# http://cpanel.net/
#
# This is free software; you can redistribute it and/or modify it under the same
# terms as Perl itself.  See the LICENSE file for further details.

use strict;
use warnings;

use Fcntl ();

use MIME::Base64               ();
use File::ShareDir             ();
use Filesys::POSIX::IO::Handle ();

use Build::PPK::Bundle ();
use Build::PPK::Dist   ();

use Carp;

BEGIN {
    use Exporter ();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

    our $VERSION = '0.08';
    our @ISA     = qw(Exporter);

    our @EXPORT      = ();
    our @EXPORT_OK   = ();
    our %EXPORT_TAGS = ();
}

sub build {
    my ( $class, $main, $args ) = @_;
    my @dists;

    my $bundle = Build::PPK::Bundle->new( $main, $args );

    #
    # First, go through each of the distributions passed, crack them open,
    # and add them to the bundle.
    #
    foreach my $path ( @{ $args->{'dists'} } ) {
        my $dist = Build::PPK::Dist->new($path)->prepare;

        $bundle->add_dist($dist);

        #
        # Retain this distribution for later usage and cleanup.
        #
        push @dists, $dist;
    }

    #
    # Second, go through each of the explicit module dependencies passed,
    # and add them to the bundle as well.
    #
    foreach my $module ( keys %{ $args->{'modules'} } ) {
        my $file = $args->{'modules'}->{$module};

        $bundle->add_module( $file, $module );
    }

    #
    # Verify the bundle contents prior to preparing it.
    #
    $bundle->check;

    #
    # If the '-c' flag is passed, then skip the bundle preparation
    # phase and only perform a sanity check.
    #
    return if $args->{'check'};

    #
    # Prepare the bundle for assembly, and receive a filesystem object
    # that represents the prepared result.
    #
    my $fs = $bundle->prepare();

    #
    # Assemble the bundle!
    #
    $bundle->assemble($fs);

    #
    # Clean up any distributions previously opened.
    #
    foreach my $dist (@dists) {
        $dist->cleanup;
    }

    return;
}

1;
