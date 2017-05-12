#!/usr/bin/perl

# Fixes:
# https://sourceforge.net/tracker/index.php?func=detail&aid=767913&group_id=6926&atid=106926

use Test::More tests => 1;

use strict;
use warnings;

use File::Spec;

use Config::IniFiles;

{
    my $ini = Config::IniFiles->new(
        -file => File::Spec->catfile('t', 'array.ini')
    );


    my $verdict;
    if (my @v = $ini->val("Sect", "NotExist"))
    {
        $verdict = 1;
    }
    else
    {
        $verdict = 0;
    }

    # TEST
    ok(!$verdict, "False should be returned in list context.");
}

