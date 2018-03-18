#!/usr/bin/perl

# This script attempts to reproduce:
# https://sourceforge.net/tracker/index.php?func=detail&aid=1565180&group_id=6926&atid=106926

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use Config::IniFiles;

my $filename = File::Spec->catfile( File::Spec->curdir(), "t",
    "case-sensitive-default.ini", );

{
    my $cfg = Config::IniFiles->new(
        -file    => $filename,
        -default => "Common",
        -nocase  => 1,
    );

    # TEST
    is(
        $cfg->val( "MyScript", "stopfile", "not defined" ),
        "myscript-stop", "Default section handled in nocase => 1",
    );
}

