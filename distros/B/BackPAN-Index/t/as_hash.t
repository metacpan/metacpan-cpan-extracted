#!/usr/bin/perl -w

use strict;
use warnings;
use lib 't/lib';

use TestUtils;

use Test::More;

my $b = new_backpan();

{
    my $dist = $b->dists->search(undef, { order_by => "random()", rows => 1 })->first;
    note("Dist is @{[$dist->name]}");

    my $first_release  = $dist->releases->search( undef,
                                                  { order_by => {-asc  => ['date']} })->first;
    my $latest_release = $dist->releases->search( undef,
                                                  { order_by => {-desc => ['date']} })->first;

    is_deeply $dist->as_hash, {
	name            => $dist->name,
	first_release   => $first_release,
	first_date      => $first_release->date,
	first_author    => $first_release->cpanid,
	latest_release  => $latest_release,
	latest_date     => $latest_release->date,
	latest_author   => $latest_release->cpanid,
	num_releases    => $dist->releases->count,
    } or diag explain $dist->as_hash;

    my $release = $dist->releases->search(undef, { order_by => "random()" })->first;
    note("Release is @{[$release->distvname]}");

    is_deeply $release->as_hash, {
        dist            => $release->dist,
        version         => $release->version,
        cpanid          => $release->cpanid,
        date            => $release->date,
        path            => $release->path,
        maturity        => $release->maturity
    };

    is "$release", $release->distvname,  "Release stringifies to distvname";

    my $file = $release->path;
    note("File is $file");

    is_deeply $file->as_hash, {
        path            => $file->path,
        size            => $file->size,
        date            => $file->date
    };
}


done_testing();
