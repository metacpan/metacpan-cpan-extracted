#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::stat_stddev';
    use_ok $pkg;
}

require_ok $pkg;

lives_ok { $pkg->new('numbers')->fix({ numbers => [1,2,3,4] }) };

my $res = $pkg->new('numbers')->fix({ numbers => [1,2,3,4] });

ok $res->{numbers} , "Simple stddev ok";

done_testing 4;
