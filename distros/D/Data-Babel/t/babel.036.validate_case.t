########################################
# case insensitve validate test
######################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use List::MoreUtils qw(uniq);
use List::Util qw(min);
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Config;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test
Data::Babel->autodb($autodb);
my $dbh=$autodb->dbh;

# make component objects and Babel.  type_0 has history. type_1 is explicit, type_2 implicit
my @idtypes=map {new Data::Babel::IdType(name=>"type_$_",sql_type=>'VARCHAR(255)')} (0,1,2);
my @masters=map {new Data::Babel::Master(name=>$_->name.'_master',idtype=>$_)} @idtypes[0,1];
$masters[0]->history(1);
my $maptable=new Data::Babel::MapTable(name=>"maptable",idtypes=>"type_0 type_1 type_2");
my $babel=
  new Data::Babel(name=>'test',idtypes=>\@idtypes,masters=>\@masters,maptables=>[$maptable]);
isa_ok($babel,'Data::Babel','sanity test - $babel');

# create data & load database
# master 0
my @master_data=map {["retired_$_",undef]} (1..3);
for my $m (1..3) {
  my @x_ids=map {"x$_"} (1..$m);
  for my $n (1..3) {
    for my $x_id (@x_ids) {
      push(@master_data,map {["$m-$n $x_id","a$m-$n.$_"]} (1..$n));
    }}}
load_master($babel,'type_0_master',@master_data);
my @x_type_0_ids=uniq grep {defined $_} map {$_->[0]} @master_data;
my @type_0_ids=uniq grep {defined $_} map {$_->[1]} @master_data;
# master 1
my @master_data=((map {"none_$_"} 1..3),'b');
my @type_1_ids=@master_data;
load_master($babel,'type_1_master',@master_data);
# maptable
my @maptable_data=map {[$_,'b','c1'],[$_,'b','c2']} @type_0_ids;
load_maptable($babel,'maptable',@maptable_data);
my @type_2_ids=qw(c1 c2);
$babel->load_implicit_masters;
load_ur($babel,'ur');

# sanity tests
my $ok=1;
my $correct=scalar(@maptable_data)*2+6; # semi-empirically determined
my $actual=
  select_ur_sanity(babel=>$babel,urname=>'ur',
		   output_idtypes=>[qw(_X_type_0 type_0 type_1 type_2)]);
$ok&&=is_quietly(scalar @$actual,$correct,'sanity test - ur construction');
my $correct=scalar(@maptable_data)+6; # semi-empirically determined
my $correct=scalar @x_type_0_ids;
my $actual=
  select_ur_sanity(babel=>$babel,urname=>'ur',output_idtypes=>[qw(_X_type_0)]);
$ok&&=is_quietly(scalar @$actual,$correct,'sanity test - ur selection _X_type_0');
my $correct=scalar @type_0_ids;
my $actual=
  select_ur_sanity(babel=>$babel,urname=>'ur',output_idtypes=>[qw(type_0)]);
$ok&&=is_quietly(scalar @$actual,$correct,'sanity test - ur selection type_0');
my $correct=scalar @type_1_ids;
my $actual=
  select_ur_sanity(babel=>$babel,urname=>'ur',output_idtypes=>[qw(type_1)]);
$ok&&=is_quietly(scalar @$actual,$correct,'sanity test - ur selection type_1');
report_pass($ok,'sanity test - ur construction and selection');

# real tests
my $num_retired=3; my $num_none=3; my $num_invalid=3; 
my @retired_ids=map {"retired_$_"} (1..$num_retired);
my @none_ids=map {"none_$_"} (1..$num_none);
my @invalid_ids=map {"invalid_$_"} (1..$num_invalid);
doit('type_0',[@retired_ids],0,$num_retired,0,__FILE__,__LINE__);
doit('type_0',[@retired_ids,@invalid_ids],0,$num_retired,$num_invalid,__FILE__,__LINE__);

for my $m (1..3) {
  my @x_ids=map {"x$_"} (1..$m);
  for my $n (1..3) {
    for my $x_id (@x_ids) {
      my @ids=map {"$m-$n $x_id"} (1..$n);
      doit('type_0',\@ids,$n,0,0,__FILE__,__LINE__);
      doit('type_0',[@ids,@retired_ids],$n,$num_retired,0,__FILE__,__LINE__);
      doit('type_0',[@ids,@retired_ids,@invalid_ids],$n,$num_retired,$num_invalid,
	   __FILE__,__LINE__);
    }}}

doit('type_1',[@none_ids],0,$num_none,0,__FILE__,__LINE__);
doit('type_1',[@none_ids,@invalid_ids],0,$num_none,$num_invalid,__FILE__,__LINE__);
doit('type_1',['b'],1,0,0,__FILE__,__LINE__);
doit('type_1',['b',@none_ids],1,$num_none,0,__FILE__,__LINE__);
doit('type_1',['b',@none_ids,@invalid_ids],1,$num_none,$num_invalid,__FILE__,__LINE__);

doit('type_2',[@invalid_ids],0,0,$num_invalid,__FILE__,__LINE__);
for my $id (@type_2_ids) {
  doit('type_2',[$id],1,0,0,__FILE__,__LINE__);
  doit('type_2',[$id,@invalid_ids],1,0,$num_invalid,__FILE__,__LINE__);
}
doit('type_2',[@type_2_ids],scalar(@type_2_ids),0,0,__FILE__,__LINE__);
doit('type_2',[@type_2_ids,@invalid_ids],scalar(@type_2_ids),0,$num_invalid,__FILE__,__LINE__);

done_testing();

sub doit {
  my($idtype,$ids,$count_main,$count_retired,$count_invalid,$file,$line)=@_;
  # NG 13-06-15: added vary_case to test case insensitve comparisons
  $ids=vary_case($ids);
  my $label="idtype=$idtype ids=".join(', ',@$ids);
  my $ok=1;
  # use ids for input
  my $correct=
    select_ur(babel=>$babel,validate=>1,
  	      input_idtype=>$idtype,input_ids=>$ids,output_idtypes=>[$idtype]);
  is_quietly(scalar(@$correct),$count_main+$count_retired+$count_invalid,
  	     "BAD NEWS: select_ur got wrong number of rows!! input $label",
  	     $file,$line) or return 0;
  is_quietly(scalar(grep {$_->[1]==0} @$correct),$count_invalid,
	     "BAD NEWS: select_ur got wrong number of invalid rows!! input $label",
  	     $file,$line) or return 0;

  my $actual=$babel->validate(input_idtype=>$idtype,input_ids=>$ids);
  $ok&&=cmp_table_quietly($actual,$correct,"$label",$file,$line) or return 0;
  my $actual=$babel->validate(input_idtype=>$idtype,input_ids=>$ids,count=>1);
  $ok&&=is_quietly($actual,scalar @$correct,"$label count",$file,$line) or return 0;

  # repeat with limits
  for my $limit (0,1,2) {
    my $actual=$babel->validate(input_idtype=>$idtype,input_ids=>$ids,limit=>$limit);  
    $ok&&=cmp_table_quietly($actual,$correct,"$label limit=$limit",$file,$line,$limit)
      or return 0;
    my $actual=$babel->validate(input_idtype=>$idtype,input_ids=>$ids,limit=>$limit,count=>1);
    $ok&&=is_quietly($actual,min($limit,scalar(@$correct)),"$label count limit=$limit",
		     $file,$line)
      or return 0;
  }
  report_pass($ok,$label);
}
