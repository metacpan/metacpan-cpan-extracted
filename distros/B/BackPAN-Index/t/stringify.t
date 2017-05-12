#!perl

use strict;
use warnings;
use lib 't/lib';

use TestUtils;
use Test::More;

use BackPAN::Index;

my $b = new_backpan();

{
    my $dist = $b->dists->search(undef, { order_by => "random()", rows => 1 })->first;
    note("Dist is @{[$dist->name]}");

    is "$dist", $dist->name,    "Dist stringifies to name";

    my $release = $dist->releases->search(undef, { order_by => "random()" })->first;
    note("Release is @{[$release->distvname]}");

    is "$release", $release->distvname,  "Release stringifies to distvname";

    my $file = $release->path;
    note("File is $file");

    is "$file", $file->path,            "File stringifies to path";
}

done_testing();
