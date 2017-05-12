our (@tests,$x,$obj,@list,$string);
BEGIN {
    @tests=(
       'Dump($x);',
        '$obj=Dump(); ref $obj eq "Data::Dump::Streamer"',
        '$obj=Dump($x); ref $obj eq "Data::Dump::Streamer"',
        '$obj=Dump($x)->Purity(0); ref $obj eq "Data::Dump::Streamer"',
        '@list=$obj->Dump; @list>0',
        '$obj->Purity()==0',
        '$string=$obj->Dump($x)->Out(); $string =~/1,/',
        '$string=$obj->Names("foo")->Data($x)->Dump(); $string =~/1,/ && $string=~/foo/',
    );
}
use Test::More tests => 1+@tests;
BEGIN { use_ok( 'Data::Dump::Streamer', qw(:undump Dump) ); }
use strict;
use warnings;
$obj="";
$x=[1..10];
for my $snippet (@tests){
    my ($title)=split /;/,$snippet;
    @list=();
    $string="";
    ok(eval($snippet)&&!$@,$title)
        or diag @list ? "[@list]" : $string;
}

#$Id: usage.t 26 2006-04-16 15:18:52Z demerphq $#




