#!/usr/bin/perl -T

# This script attempts to reproduce:
# https://sourceforge.net/tracker/index.php?func=detail&aid=1565180&group_id=6926&atid=106926

use strict;
use warnings;

use Test::More tests => 2;
use File::Spec;
use Scalar::Util qw(tainted);

use Config::IniFiles;

my $filename = File::Spec->catfile( File::Spec->curdir(), "t", "array.ini", );

{
    my $cfg = Config::IniFiles->new(
        -file    => $filename,
        -default => "Common",
        -nocase  => 1,
    );

    my @val = $cfg->val( "Sect", "Par" );

    # TEST
    ok( !tainted( $val[0] ), "val[0] is not tainted" );

    # TEST
    ok( !tainted( $val[1] ), "val[1] is not tainted" );
}

