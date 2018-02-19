# make;perl -Iblib/lib t/39_sim.t
use lib '.'; BEGIN{require 't/common.pl'}
use Test::More tests    => 10;
eval 'require String::Similarity';
if($@){ ok(1) for 1..10; exit }

for(["Humphrey DeForest Bogart",  "Bogart Humphrey DeForest" ],
    ["Humphrey Bogart",           "Humphrey Gump Bogart"],
    ["Humphrey deforest Bogart",  "Bogart DeForest"],
    ["Humfrey DeForest Boghart",  "BOGART HUMPHREY"],
#   ["Humfrey Deforest Boghart",  "BOGART D. HUMFREY"], #todo
    ["Humphrey",                  "Bogart Humphrey"],
){
  my($s,$sp)=(sim(@$_),sim_perm(@$_));
  deb sprintf("%-34s %-34s %7.2f vs %7.2f\n",@$_,$s,$sp);
  ok( $s < $sp );
  ok( $sp >= 0.85 );
}

#my($n1,$n2)=( "Humphrey DeForest Bogart", "Bogart Humphrey DeForest"  );
#my $start=time_fp();
#sim_perm($n1,$n2)."\n" for 1..100;
#deb sprintf("%.5fs\n",time_fp()-$start);
