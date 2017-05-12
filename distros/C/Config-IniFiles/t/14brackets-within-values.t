#!/usr/bin/perl

# This script attempts to reproduce:
# https://sourceforge.net/tracker/index.php?func=detail&aid=2030786&group_id=6926&atid=106926

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use Config::IniFiles;

my $filename = File::Spec->catfile(File::Spec->curdir(), "t", "brackets-in-values.ini");

{
    my $cfg=Config::IniFiles->new(-file => $filename, -allowempty => 1);

    # TEST
    is ($cfg->val('SiteName', 'file'),
        "http://www.example.com/files/file[1-22].gz",
        "Reading value containing brackets well"
    );
}
