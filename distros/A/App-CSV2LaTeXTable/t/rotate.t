#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;

my $dir = dirname __FILE__;

use_ok 'App::CSV2LaTeXTable';

my $latex = $dir . '/data/rotate.latex';
my $csv   = $dir . '/data/test.csv';

{
    unlink $latex;
    ok !-f $latex;

    my $obj = App::CSV2LaTeXTable->new(
        csv    => $csv,
        latex  => $latex,
        rotate => 90,
    );

    $obj->run;

    ok -f $latex;

    my $content = do { local (@ARGV, $/) = $latex; <> };
    like_string $content, qr/rotatebox\{90\}/;
    like_string $content, qr/Name & Age & City \\\\/;
}

done_testing();
