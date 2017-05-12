#!/usr/bin/perl

use Test::More;
use Test::NoWarnings;
use warnings;
use strict;


my @inout = (
    [ 's = "string"'                    =>  { s => "string"               } ],
    [ 'a = { "one", "two", "three" }'   =>  { a => [qw( one two three )]  } ],
    [ 'h = { one = 1, two = 2 }'        =>  { h => { one => 1, two => 2 } } ], 
    [ 'ga = { [10] = "ten" }'           =>  { ga => [(undef) x 9, "ten"]  } ],
);


plan tests => @inout + 3;


use_ok("Data::Lua");


foreach my $pair (@inout) {
    my($in, $out) = @$pair;
    my $vars = Data::Lua->parse($in);
    
    is_deeply($vars, $out, "parsing Lua: $in");
}



{
    my $all_in  = join("", map {   "$_->[0]\n" } @inout);
    my %all_out =          map { %{ $_->[1] }  } @inout;

    my $vars = Data::Lua->parse($all_in);

    is_deeply($vars, \%all_out, "parsing all");
}
