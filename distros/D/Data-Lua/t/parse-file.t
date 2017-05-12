#!/usr/bin/perl

use File::Spec::Functions qw(rel2abs splitpath catfile);
use Test::More;
use Test::NoWarnings;
use warnings;
use strict;


my $DIR         = rel2abs((splitpath __FILE__)[1]);
my $FILE_FORMAT = 'parse-file-%s.lua';

my @outs = (
    { s => "string"               },
    { a => [qw( one two three )]  },
    { h => { one => 1, two => 2 } }, 
    { ga => [(undef) x 9, "ten"]  },
    {},
);


plan tests => @outs + 3;


use_ok("Data::Lua");


foreach my $i (0 .. $#outs) {
    my $out  = $outs[$i];
    my $file = catfile($DIR, sprintf($FILE_FORMAT, $i + 1));
    my $vars = Data::Lua->parse_file($file);

    is_deeply($vars, $out, "parsing Lua file $file");
}



{
    my $all_file = catfile($DIR, sprintf($FILE_FORMAT, 'all'));
    my %all_out  = map { %$_ } @outs;

    my $vars = Data::Lua->parse_file($all_file);

    is_deeply($vars, \%all_out, "parsing all");
}
