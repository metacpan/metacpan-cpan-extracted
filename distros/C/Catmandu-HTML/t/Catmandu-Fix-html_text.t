#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::html_text';
    use_ok $pkg;
}

{
    my $record = Catmandu->importer('HTML',file => 't/muse.html')->first;
    my $result = $pkg->new()->fix($record);

    ok $result;

    like $result->{html} , qr{<html><body><!DOCTYPE} ;
}

{
    my $record = Catmandu->importer('HTML',file => 't/muse.html')->first;
    my $result = $pkg->new(join => "-")->fix($record);

    ok $result;

    like $result->{html} , qr{<html>-<body>-<!DOCTYPE} ;
}

{
    my $record = Catmandu->importer('HTML',file => 't/muse.html')->first;
    my $result = $pkg->new(split => 1)->fix($record);

    ok $result;

    is ref($result->{html}) , 'ARRAY';
}


done_testing;
