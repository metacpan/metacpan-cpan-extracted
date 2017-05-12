#!/usr/bin/perl
# This script is a regression test for:
#
# https://rt.cpan.org/Ticket/Display.html?id=45997
#
# Failure to read the ini file contents from a filehandle made out of a scalar

use Test::More tests => 2;

use strict;
use warnings;

use Config::IniFiles;
use File::Spec;

my $empty_fn = File::Spec->catfile(File::Spec->curdir(), "t", "for-27-empty.ini");

{
    my $cfg = Config::IniFiles->new( -file => $empty_fn, -allowempty => 1);

    # TEST
    ok ($cfg, "object was initialized.");

    my @Groups = $cfg->GroupMembers("test");

    # TEST
    is_deeply (
        \@Groups,
        [],
        "Groups is empty."
    );
}
