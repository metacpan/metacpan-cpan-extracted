#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;

my $pkg;
BEGIN {
    $pkg = 'Catmandu::Fix::stat_mode';
    use_ok $pkg;
}

require_ok $pkg;

lives_ok { $pkg->new('numbers')->fix({ numbers => [1,2,3,3,3,4] }) };

is_deeply 
$pkg->new('numbers')->fix({ numbers => [1,2,3,3,3,4] }), 
{ numbers => 3 }, "Simple mode ok";


done_testing 4;