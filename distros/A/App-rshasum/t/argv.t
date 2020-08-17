#!/usr/bin/env perl

use strict;
use warnings;
use Test::More tests => 1;

use Path::Tiny qw/ path tempdir tempfile cwd /;
use App::rshasum ();

{
    local @ARGV = ( "--digest=SHA-256", "/" );

    eval { App::rshasum->run(); };

    my $err = $@;

    my $needle =
qq#Leftover arguments "/" in the command line. (Did you intend to use --start-path ?)#;

    # TEST
    like( $err, qr#\A\Q$needle\E#, "right exception thrown" );
}
