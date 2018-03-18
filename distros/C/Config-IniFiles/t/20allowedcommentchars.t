#!/usr/bin/perl

# This script attempts to reproduce:
# https://rt.cpan.org/Ticket/Display.html?id=36309

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use Config::IniFiles;

my $filename = File::Spec->catfile( File::Spec->curdir(), "t",
    "allowed-comment-chars.ini", );

{
    my $cfg = Config::IniFiles->new(
        -file                => $filename,
        -allowedcommentchars => '};',
    );

    # TEST
    is( $cfg->val( "cat1", "mykey" ), "500", "Proper comments are ignored.", );
}

