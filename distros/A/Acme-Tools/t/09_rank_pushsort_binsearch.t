#perl Makefile.PL;make;          perl -Iblib/lib t/09_rank_pushsort_binsearch.t
#perl Makefile.PL;make;ATDEBUG=1 perl -Iblib/lib t/09_rank_pushsort_binsearch.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests => 61;

my @a=(1,10,20,50,70,90,120,130);
testsearch(1,@a);

@a=(1..20);    testsearch(1,@a);
@a=(1..1000);  testsearch(0,@a);
@a=(1..2000);  testsearch(0,@a);
@a=(1..4000);  testsearch(0,@a);
#@a=(1..8000);  testsearch(0,@a);
#@a=(1..16000); testsearch(0,@a);

sub testsearch {
  my $deb=shift;
  my @a=@_;
  deb "----------\nArrsize: ".@a."\n";
  $deb and deb serialize(\@a,'a');

  my $time=time_fp;
  my @steps;
  my $ok=1;
  for(@a){
    my($res,$steps)=(binsearch($_,\@a),$Acme::Tools::Binsearch_steps);
    $ok=0 if $a[$res] !=$_;
    push @steps,$steps;
    #print "$_: ".binsearch($_,@a) ,"  steps=$steps\n";
  }
  ok($ok);
  $time=time_fp()-$time;
  print "Time: $time sek\n";
  print "Time pr search: ".($time/@a)." sek/search\n";
  print "Time pr step:   ".($time/sum(@steps))." sek/step\n";
  print "Steps:   sum = ".sum(@steps)."   avg = ".avg(@steps)."   min = ".min(@steps)."   max = ".max(@steps)."\n";
  if($deb){my %ant;$ant{$_}++ for @steps; print "Searches with $_ steps: $ant{$_}\n" for sort {$a<=>$b} keys %ant}
}

my $bs;
ok( binsearch(1,[1,2,5])==0 );
ok( binsearch(2,[1,2,5])==1 );
ok( binsearch(5,[1,2,5])==2 );
ok( ($bs=binsearch(6,[1,2,5],1))==2.5, "after $bs");
ok( ($bs=binsearch(3,[1,2,5],1))==1.5, $bs);
ok( ($bs=binsearch(1.4,[1,2,5],1))==0.5, $bs);
ok( ($bs=binsearch(0,[1,2,5],1))==-0.5,"before $bs");

my $cmpsub=sub{$_[0] <=> $_[1]};
ok( binsearch(1,[1,2,5],0,$cmpsub)==0 );
ok( binsearch(2,[1,2,5],0,$cmpsub)==1 );
ok( binsearch(5,[1,2,5],0,$cmpsub)==2 );
ok( ($bs=binsearch(6,[1,2,5],1,$cmpsub))==2.5, "after $bs");
ok( ($bs=binsearch(3,[1,2,5],1,$cmpsub))==1.5, $bs);
ok( ($bs=binsearch(1.4,[1,2,5],1,$cmpsub))==0.5, $bs);
ok( ($bs=binsearch(0,[1,2,5],1,$cmpsub))==-0.5,"before $bs");

ok( binsearch(10,[20,15,10,5],undef,sub{$_[1]<=>$_[0]}) == 2);       # 2 search arrays sorted numerically in opposite order
ok( binsearch("c",["a","b","c","d"],undef,sub{$_[0]cmp$_[1]}) == 2); # 2 search arrays sorted alphanumerically
ok( binsearchstr("b",["a","b","c","d"]) == 1);                       # 1 search arrays sorted alphanumerically

my @data=( map {  {num=>$_,sqrt=>sqrt($_), square=>$_**2}  } grep !($_%7), 1..10000  );
my($i1,$i2) = ( binsearch( {num=>8883}, \@data, undef, sub {$_[0]{num} <=> $_[1]{num}} ),
                binsearch( {num=>8883}, \@data, undef, 'num' )                             );
ok( $i1==1268, 'binsearch i1');
ok( $i2==1268, 'binsearch i2' );
#ok( $data[$i1]{square}==78907689 );
ok( $Acme::Tools::Binsearch_steps == 10, 'binsearch 10 steps' );
#print "i=$i   ".srlz(\$found,'f')."Binsearch_steps = $Acme::Tools::Binsearch_steps\n";

deb "--------------------------------------------------------------------------------eqarr\n";
ok( eqarr([1,2,3],[1,2,3],[1,2,3]) == 1 ,'eqarr 1');
ok( eqarr([1,2,3],[1,2,3],[1,2,4]) == 0 ,'eqarr 0');
ok( !defined(eqarr([1,2,3],[1,2,3,4]))  ,'eqarr undef' );
ok( do{eval{eqarr([1,2,3])};$@}            ,'eqarr croak 1');
ok( do{eval{eqarr([1,2,3],1,2,3)};$@}      ,'eqarr croak 2');

deb "--------------------------------------------------------------------------------rank\n";
ok( rank(1,[20,30,10,15,40])==10 ,'rank 1');
ok( rank(2,[20,30,10,15,40])==15 ,'rank 2');
ok( rank(3,[20,30,10,15,40])==20 ,'rank 3');
ok( rank(4,[20,30,10,15,40])==30 ,'rank 4.1');
ok( rank(4,[20,30,10,15,40,10])==20 ,'rank 4.2');

for my $big (0,2,20,200,2000){
  my $ant=min(20,$big);
  ok( eqarr([rank(20,[mix(1..$big)])],[1..$ant]), "rank wantarray $big");
  ok( eqarr([rankstr(20,[mix(1..$big)])],[(sort(1..$big))[0..$ant-1]]), "rankstr wantarray $big");

  ok( eqarr([rank(-20,[mix(1..$big)])],[reverse($big-$ant+1..$big)]), "rank wantarray neg $big");
  ok( eqarr([rankstr(-20,[mix(1..$big)])],[(reverse(sort(1..$big)))[0..$ant-1]]), "rankstr wantarray neg $big");

  #my @r20=rankstr(20,[mix(1..$big)]); deb join(",",@r20)."\n";
}


deb "--------------------------------------------------------------------------------pushsort\n";
my @p=(1..10);
pushsort @p,7;
ok( eqarr(  \@p,[1,2,3,4,5,6,7,7,8,9,10] ), 'pushsort '.join(",",@p) );

if($ENV{ATDEBUG}){
  my(@o,@n);my$i=0;
  require Benchmark; Benchmark::timethese(200,{
    'new' => sub{@n=();pushsort(@n,rand()) for 1..100},
    'old' => sub{@o=();pushsort(@o,rand()) for 1..100},
  });
  deb "len new=".@n." old=".@o."     sorted? new=".sorted(@n)." old=".sorted(@o)."\n";
}

@p=();
pushsort @p, rand for 1..1000;
ok( sorted(@p), 'pushsort' );
@p=();
pushsortstr @p, rand for 1..1000;
ok( sortedstr(@p), 'pushsortstr' );

deb "--------------------------------------------------------------------------------sorted\n";
my @num=sort {$a<=>$b} map rand()*100,1..100;
my @str=sort           map rand()*100,1..100;
ok( sorted(    @num ), 'sorted' );
ok( sortedstr( @str ), 'sortedstr' );
ok( !eqarr(\@num,\@str), 'sorted ne sortedstr' );
