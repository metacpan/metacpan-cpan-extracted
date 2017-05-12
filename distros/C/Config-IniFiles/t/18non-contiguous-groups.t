#!/usr/bin/perl -T

# This script attempts to reproduce:
# https://sourceforge.net/tracker/index.php?func=detail&aid=1720915&group_id=6926&atid=106926

use strict;
use warnings;

use Test::More tests => 1;
use File::Spec;

use Config::IniFiles;

my $filename = File::Spec->catfile(
    File::Spec->curdir(), "t", "non-contiguous-groups.ini",
);

{
    my $cfg=Config::IniFiles->new(-file => $filename);

    my @members = $cfg->GroupMembers("A");

    # TEST
    is_deeply(
        \@members,
        ["A 1", "A 2", "A 3"],
    );
}

