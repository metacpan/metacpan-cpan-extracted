# make test
# perl Makefile.PL; make; perl -Iblib/lib t/17_roman.t

use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 31;
use Carp;
my %rom=(MCCXXXIV=>1234,MCMLXXI=>1971,IV=>4,VI=>6,I=>1,V=>5,X=>10,L=>50,C=>100,D=>500,M=>1000,CDXCVII=>497);
my$rom;ok( ($rom=int2roman($rom{$_})) eq $_, sprintf"int2roman %8d => %-10s   %-10s",$rom{$_},$_,"($rom)") for sort keys%rom;
my$int;ok( ($int=roman2int($_)) eq $rom{$_}, sprintf"roman2int %-8s => %10d   %10d",$_,$rom{$_},$int)      for sort keys%rom;
ok( do{eval{roman2int("a")};$@=~/invalid/i}, "croaks ok" );
ok( roman2int("-MCCXXXIV")==-1234, 'negative ok');
ok( int2roman(0) eq '', 'zero');
ok( !defined(int2roman(undef)), 'undef');
ok( defined(int2roman("")) && !length(int2roman("")), 'empty');
my @n=(-100..4999);
my @err=grep roman2int(int2roman($_))!=$_, grep $_>100?$_%7==0:1, @n;
ok( @err==0, "all, not ok: ".(join(", ",@err)||'none') );

my @t=([time_fp(),join(" ",map int2roman($_)    ,@n),time_fp()],
       [time_fp(),join(" ",map int2roman_old($_),@n),time_fp()]);
ok( $t[0][1] eq $t[1][1] );
if($ENV{ATDEBUG}){
  printf "Acme::Tools::int2roman   - %.6fs\n",$t[0][2]-$t[0][0];
  printf "17_roman.t/int2roman_old - %.6fs\n",$t[1][2]-$t[1][0];
}

sub int2roman_old {
  my($n,@p)=(shift,[],[1],[1,1],[1,1,1],[1,2],[2],[2,1],[2,1,1],[2,1,1,1],[1,3],[3]);
    !defined($n)? undef
  : !length($n) ? ""
  : int($n)!=$n ? croak"int2roman: $n is not an integer"
  : $n==0       ? ""
  : $n<0        ? "-".int2roman(-$n)
  : $n>3999     ? "M".int2roman($n-1000)
  : join'',@{[qw/I V X L C D M/]}[map{my$i=$_;map($_+5-$i*2,@{$p[$n/10**(3-$i)%10]})}(0..3)];
}

