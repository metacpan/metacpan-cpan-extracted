#!/usr/bin/perl

# This script attempts to reproduce:
# https://rt.cpan.org/Ticket/Display.html?id=46721
#
# #46721: $config->exists() does not pay attention to -nocase => 1

use Test::More tests => 2;

use strict;
use warnings;

use File::Spec;

use Config::IniFiles;

{
    my $conf = Config::IniFiles->new(
        -file => File::Spec->catfile(
            File::Spec->curdir(), 't', 'case-sensitive.ini'
        ),
        -nocase => 1
    );

    # TEST
    ok(
        scalar( $conf->exists( 'FOO', 'BAR' ) ),
        "->exists() Handles case well"
    );

    # TEST
    is( scalar( $conf->val( 'FOO', 'BAR' ) ),
        "goodness", "->val() Handles case well" );
}

