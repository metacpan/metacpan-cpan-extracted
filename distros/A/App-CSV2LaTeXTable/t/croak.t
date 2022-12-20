#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Basename;

my $dir = dirname __FILE__;

use_ok 'App::CSV2LaTeXTable';

my $latex = '/likely/does/not/exist';
my $csv   = $dir . '/data/test.csv';

{
    unlink $latex;
    ok !-f $latex;

    my $obj = App::CSV2LaTeXTable->new(
        csv   => $csv,
        latex => $latex,
    );

    dies_ok {
        $obj->run;
    };
}

done_testing();
