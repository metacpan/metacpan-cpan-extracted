#!perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}


use strict;
use warnings;

# this test was generated with Dist::Zilla::Plugin::Test::Perl::Critic::Subset 3.001.006

use Test::Perl::Critic (-profile => "") x!! -e "";

my $filenames = ['lib/App/TextTableUtils.pm','script/csv2ansitable','script/csv2asciitable','script/csv2dd','script/csv2json','script/csv2mdtable','script/csv2orgtable','script/csv2texttable','script/dd2ansitable','script/dd2asciitable','script/dd2csv','script/dd2mdtable','script/dd2orgtable','script/dd2texttable','script/dd2tsv','script/ini2ansitable','script/ini2asciitable','script/ini2csv','script/ini2mdtable','script/ini2orgtable','script/ini2texttable','script/ini2tsv','script/iod2ansitable','script/iod2asciitable','script/iod2csv','script/iod2mdtable','script/iod2orgtable','script/iod2texttable','script/iod2tsv','script/json2ansitable','script/json2asciitable','script/json2csv','script/json2mdtable','script/json2orgtable','script/json2texttable','script/json2tsv','script/texttableutils-convert','script/tsv2ansitable','script/tsv2asciitable','script/tsv2dd','script/tsv2json','script/tsv2mdtable','script/tsv2orgtable','script/tsv2texttable'];
unless ($filenames && @$filenames) {
    $filenames = -d "blib" ? ["blib"] : ["lib"];
}

all_critic_ok(@$filenames);
