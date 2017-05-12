# perl Makefile.PL;make;perl -Iblib/lib t/3_bloomfilter.t
# perl Makefile.PL;make;ATDEBUG=1 perl -Iblib/lib t/3_bloomfilter.t
# time ( perl Makefile.PL;make;ATDEBUG=1 perl -Iblib/lib t/03_bloomfilter.t )
# perl Makefile.PL;make;perl -Iblib/lib t/03_bloomfilter.t

BEGIN{require 't/common.pl'}
use Test::More tests => 28;

my $error_rate=0.02;
my $capacity=10000;
my $bf=bfinit($error_rate, $capacity);
my $t=time_fp();
bfadd($bf, map $_*2,0..$capacity-1);
#deb "Adds pr sec: ".int($capacity/(time_fp()-$t))."\n";
#bfadd($bf, $_) for map $_*2,0..$capacity-1;

deb serialize({%$bf,filter=>''},'bf','',1);
deb "Filter has capacity $$bf{capacity}\n";
deb "Filter has $$bf{key_count} keys\n";
deb "Filter has ".length($$bf{filter})." bytes\n";
deb "Filter has $$bf{filterlength} bits of which ".bfsum($bf)." (".int(100*bfsum($bf)/$$bf{filterlength})."%) are on\n";
deb "Filter has $$bf{hashfuncs} hash functions\n";
my @c=bfcheck($bf,0..$capacity*2); #test next ok: $c[2000]=0;
#deb "$_->".bfcheck($bf,$_)."\n" for 0..200;

my $sum; $sum+=$c[ $_*2+1 ],  for 0..$capacity-1;
deb "Filter has $sum false positives\n";
ok(!(grep $c[$_]!=1, map $_*2, 0..$capacity-1), 'no false negatives');
ok(
     $sum >= $capacity*$error_rate*80/100
  && $sum <= $capacity*$error_rate*120/100
  , sprintf "real error rate (%.6f) vs wanted error_rate ($error_rate) within ok ratio 80-120%% (%d%%)",
            $sum/$capacity,
            100*$sum/($capacity*$error_rate)
);
eval{bfinit(a=>1,b=>2)};
#deb $@;
ok($@=~/Not ok param to bfinit: a, b\b/,'param check');

eval{bfinit(capacity=>10,keys=>[1..11])};
ok($@=~/Exceeded filter capacity 10/,'capacity check');

eval{bfinit(error_rate=>0.0,capacity=>1e3)};ok($@=~/\QError rate (0) should be larger than 0 and smaller than 1\E/,'error_rate check1');
eval{bfinit(error_rate=>1.0,capacity=>1e3)};ok($@=~/\QError rate (1) should be larger than 0 and smaller than 1\E/,'error_rate check2');
#deb "<<$@>>\n";

#---------- OO
my $bfoo=new Acme::Tools::BloomFilter(0.1,1000);
$bfoo->add(1..500);
$bfoo->add([501..1000]);
ok(0+grep($_,$bfoo->check(1..1000)) == 1000, 'oo ok1');
ok($bfoo->clone()->grep([1..1000]) == 1000, 'oo ok2');
ok(0+grep($_,$bfoo->check(1001..2000)) < 150, 'oo ok3');

#---------- counting bloom filter
my($er,$cap,$cb)=(0.1,1000,4);
my $cbf=bfinit(error_rate=>$er,capacity=>$cap,counting_bits=>$cb,keys=>[1..$cap]);
ok(0+grep($_,bfcheck($cbf,1..$cap)) == $cap, 'cbf no false negatives');
ok(bfgrepnot($cbf,[1..$cap]) == 0, 'cbf grepnot');
my $errs=grep($_,bfcheck($cbf,$cap+1..$cap*2));
deb "Errs $errs\n";
ok(between($errs/$cap/$er,0.7,1.3),'error rate rating '.($errs/$cap/$er).' within ok range 0.7-1.3');

#---------- see doc about this example:
#do{
# my $bf=bfinit( error_rate=>0.00001, capacity=>4e6, counting_bits=>4 );
# bfadd($bf,[1000*$_+1 .. 1000*($_+1)]),deb"." for 0..4000-1;  # adding 4 million keys one thousand at a time
# my %c; $c{vec($$bf{filter},$_,$$bf{counting_bits})}++ for 0..$$bf{filterlength}-1;
# deb sprintf("%8d counters is %2d\n",$c{$_},$_) for sort{$a<=>$b}keys%c;
#};

my %c; $c{vec($$cbf{filter},$_,$cb)}++ for 0..$$cbf{filterlength}-1;
ok(sum(map$c{$_}*$_,keys%c)/$$cbf{key_count} == $$cbf{hashfuncs}, 'counter check');
#deb sprintf("%8d counters is %2d\n",$c{$_},$_) for sort{$a<=>$b}keys%c;

#---------- counting bloom filter, test delete
do{
  my($er,$cap,$cb)=(0.1,500,4);
  my $bf=bfinit(error_rate=>$er,capacity=>$cap*2,counting_bits=>$cb,keys=>[1..$cap*2]);
  bfdelete($bf, $cap+1 .. $cap*1.5);
  bfdelete($bf,[$cap*1.5+1 .. $cap*2]);
  ok(bfgrep($bf,[1..$cap]) == $cap, 'cbf, delete test, no false negatives');
  my $err=bfgrep($bf,[$cap+1..$cap*2]);
  deb "Err $err\n";
  ok($err/$cap/$er<1.3,"cbf, delete test, after delete ($err)");
  my %c=(); $c{vec($$bf{filter},$_,$cb)}++ for 0..$$bf{filterlength}-1;
  ok(sum(map$c{$_}*$_,keys%c)/$$bf{key_count} == $$bf{hashfuncs}, 'cbf, delete test, counter check after delete');
  eval{ok(bfdelete($bf,'x'))};ok($@=~/Cannot delete a non-existing key x/,'delete non-existing key');
};

#---------- test filter lengths
my $r;
ok(between($r=
length(bfinit(counting_bits=>$_,error_rate=>0.01,capacity=>100)->{filter}) /
length(bfinit(counting_bits=>1, error_rate=>0.01,capacity=>100)->{filter}) / $_, 0.95, 1.05), "filter length ($r), cb $_") for qw/2 4 8 16/;

eval{bfinit(counting_bits=>2,error_rate=>0.1,capacity=>1000,keys=>[1..1000])};ok($@=~/Too many overflows/,'overflow check');

#----------storing and retrieving
my $tmp=tmp();
if(-w$tmp){
  my $file="$tmp/cbf.bf";
  bfstore($cbf,$file);
  deb "Stored size of $file: ".(-s$file)." bytes\n";
  my $cbfr=bfretrieve($file);
  ok(bfgrep($cbfr,[1..$cap]) == $cap, 'store+retrieve: cbf no false negatives');
  $errs=bfgrep($cbf,[$cap+1..$cap*2]);
  #deb "Errs $errs\n";
  ok(between($errs/$cap/$er,0.7,1.3),'store+retrieve: error rate rating '.($errs/$cap/$er).' within ok range 0.7-1.3');
  my $bf=Acme::Tools::BloomFilter->new($file);
  ok($$bf{key_count}==$cap,'store+retrieve, oo');
  unlink $file;
}
else{
  ok(1,'skipped, not linux') for 1..3;
}

#----------adaptive bloom filter, not implemented/tested, see http://intertrack.naist.jp/Matsumoto_IEICE-ED200805.pdf
# $cap=100;
# $bf=bfinit(adaptive=>0,error_rate=>0.001,capacity=>$cap,keys=>[1..$cap]);
# @c=bfcheck($bf,[1..$cap]);
# %c=(); $c{$_}++ for @c;
# deb "Filter has $$bf{filterlength} bits of which ".bfsum($bf)." (".int(100*bfsum($bf)/$$bf{filterlength})."%) are on\n";
# deb "Filter has ".int(1+$$bf{filterlength}/8)." bytes (".sprintf("%.1f",int(1+$$bf{filterlength}/8)/1024)." kb)\n";
# deb "Filter has $$bf{hashfuncs} hash functions\n";
# deb "Number of $_: $c{$_}\n" for sort{$a<=>$b}keys%c;
# deb "Sum bits ".sum(map $$bf{hashfuncs}+$_-1,bfcheck($bf,1..$cap))."\n";
# deb "False negatives: ".grep(!$_,@c)."\n";
# deb "Error rate: ".(($errs=grep($_,bfcheck($bf,$cap+1..$cap*2)))/$cap)."\n";
# deb "Errors: $errs\n";

#---------- bfaddbf, adding two bloom filters
do{
  my $cap=100;
  my $bf1=bfinit(error_rate=>0.01,capacity=>$cap,keys=>[1..$cap/2]);
  my $bf2=bfinit(error_rate=>0.01,capacity=>$cap,keys=>[$cap/2+1..$cap]);
  deb "bf1 key_count: $$bf1{key_count}, bf1 ones: ".bfsum($bf1)."\n";
  deb "bf2 key_count: $$bf2{key_count}, bf2 ones: ".bfsum($bf2)."\n";
  bfaddbf($bf1,$bf2);
  deb "bf1 key_count: $$bf1{key_count}, bf1 ones: ".bfsum($bf1)."\n";
  my @found=bfgrep($bf1,[1..$cap]);
  ok(@found==$cap,"bfaddbf(), found ".@found." of $cap");
};
do{
  my $cap=1000;
  my $er=0.1;
  my $bf1=bfinit(counting_bits=>4,error_rate=>$er,capacity=>$cap,keys=>[1..$cap/2]);
  my $bf2=bfinit(counting_bits=>4,error_rate=>$er,capacity=>$cap,keys=>[$cap/2+1..$cap]);
  deb "bf1 key_count: $$bf1{key_count}, bf1 sum: ".bfsum($bf1)."\n";
  deb "bf2 key_count: $$bf2{key_count}, bf2 sum: ".bfsum($bf2)."\n";
  deb serialize($$bf1{overflow},'bf1overflow');
  deb serialize($$bf2{overflow},'bf2overflow');
  bfaddbf($bf1,$bf2);
  deb "bf1 key_count: $$bf1{key_count}, bf1 sum: ".bfsum($bf1)."\n";
  deb serialize($$bf1{overflow},'bf1overflow');
  my @found=bfgrep($bf1,[1..$cap]);
  ok(@found==$cap,"bfaddbf(), found ".@found." of $cap");
  my $errs=bfgrep($bf1,[$cap+1..$cap*2]);
  deb "erate: ".($errs/$cap)."\n";
  my $p=100*$errs/$cap/$er;
  ok(between($p,70,130),"error rate ".($errs/$cap)." within 70%-130% of $er ($p%)");
#  deb "Error rate: ".(($errs=grep($_,bfcheck($bf1,$cap+1..$cap*2)))/$cap)."\n";
};
