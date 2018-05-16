#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Catmandu;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Fix::html_filter_tag';
    use_ok $pkg;
}

my $record = Catmandu->importer('HTML',file => 't/muse.html')->first;

{
    my $result = $pkg->new('meta')->fix($record);

    ok $result;

    for (@{$result->{token}}) {
        is $_->[1] , 'meta';
    }
}

{
    my $result = $pkg->new('meta',{group_by=>'name'})->fix($record);

    is $result->{html}->{citation_publisher}->{content} , 'Advertising Educational Foundation';
}

done_testing;
