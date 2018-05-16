#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::html_filter_type';
    use_ok $pkg;
}

{
    my $record = Catmandu->importer('HTML',file => 't/muse.html')->first;
    my $result = $pkg->new('PI')->fix($record);

    ok $result;

    for (@{$result->{html}}) {
        is $_->[0] , 'PI';
    }
}


done_testing;
