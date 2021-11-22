#!perl
use strict;
use warnings;
use Test::More;
use Data::Dumper;

use DBIx::Spreadsheet;

my @testcases = (
    [[""],["col_1"]],
    [["",""],["col_1","col_2"]],
    [['column1',"",""],['column1',"col_2","col_3"]],
    [['col_2',"",""],['col_2',"col_2_1","col_3"]],
    [["col_2",'col_2',""],['col_2',"col_2_1","col_3"]],
    [["foo.bar",'foo\\bar','foo"bar'],['foo_bar','foo_bar_1','foobar'],"Names get sanitized"],
    [["foo+bar",'foo%'],['foo_plus_bar','foo_perc'],"Some chars get named"],
    [[',',';',"\t"," ",'_',"\r\n"],['col_1','col_2','col_3','col_4','col_5','col_6'],"Whitespace and delimiters"],
);

my $testcount = 0+2*@testcases;

plan tests => $testcount;

for my $case (@testcases) {
    my( $input, $expected, $name ) = @$case;
    $name ||= join ", ", map { qq("\Q$_\E") } @$input;

    my $res = [ DBIx::Spreadsheet->gen_colnames( @$input ) ];
    s!(^"|"$)!!g for @$res;
    is_deeply $res, $expected, $name
        or diag Dumper $res;
    my %seen;
    $seen{ $_ }++ for @$res;
    my @duplicates_generated = map {
          $seen{ $res->[ $_ ] } >  1
        ? [ $_, $input->[$_] => $res->[$_] ]
        : ()
    } 0..$#$expected;
    is_deeply( \@duplicates_generated, [], "No duplicate column names get generated")
        or diag Dumper \@duplicates_generated;
}
