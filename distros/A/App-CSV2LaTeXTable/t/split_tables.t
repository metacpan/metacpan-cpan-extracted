#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::LongString;
use File::Basename;

my $dir = dirname __FILE__;

use_ok 'App::CSV2LaTeXTable';

my $latex = $dir . "/data/test$$.tex";
my $csv   = $dir . '/data/test.csv';

{
    for ( 1 .. 2 ) {
        my $local = $dir . sprintf '/data/test%s-%s.tex', $$, $_;
        unlink $local;
        ok !-f $local;
    }

    my $obj = App::CSV2LaTeXTable->new(
        csv   => $csv,
        latex => $latex,
        split => 2,
    );

    $obj->run;

    for ( 1 .. 2 ) {
        my $local = $dir . sprintf '/data/test%s-%s.tex', $$, $_;
        my $content = do { local (@ARGV, $/) = $local; <> };
        like_string $content, qr/begin\{table\}/;
        like_string $content, qr/Name & Age & City \\\\/;
        unlink $local;
        ok !-f $local;
    }
}

done_testing();
