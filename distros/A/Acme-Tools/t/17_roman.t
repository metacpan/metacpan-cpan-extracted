# make test
# perl Makefile.PL; make; perl -Iblib/lib t/17_roman.t

BEGIN{require 't/common.pl'}
use Test::More tests => 30;

my %rom=(MCCXXXIV=>1234,MCMLXXI=>1971,IV=>4,VI=>6,I=>1,V=>5,X=>10,L=>50,C=>100,D=>500,M=>1000,CDXCVII=>497);
my$rom;ok( ($rom=int2roman($rom{$_})) eq $_, sprintf"int2roman %8d => %-10s   %-10s",$rom{$_},$_,"($rom)") for sort keys%rom;
my$int;ok( ($int=roman2int($_)) eq $rom{$_}, sprintf"roman2int %-8s => %10d   %10d",$_,$rom{$_},$int)      for sort keys%rom;
ok( do{eval{roman2int("a")};$@=~/invalid/i}, "croaks ok" );
ok( roman2int("-MCCXXXIV")==-1234, 'negative ok');
ok( int2roman(0) eq '', 'zero');
ok( !defined(int2roman(undef)), 'undef');
ok( defined(int2roman("")) && !length(int2roman("")), 'empty');
my @err=grep roman2int(int2roman($_))!=$_, grep $_>100?$_%7==0:1, -100..4999;
ok( @err==0, "all, not ok: ".(join(", ",@err)||'none') );
