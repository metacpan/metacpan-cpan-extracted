########################################
# regression test for duplicate input ids - only relevant when validate option set
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use List::MoreUtils qw(uniq);
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

# make component objects and Babel. 
my @idtypes=map {new Data::Babel::IdType(name=>"type_$_",sql_type=>'VARCHAR(255)')}
  qw(history explicit implicit);
my @masters=map {new Data::Babel::Master(name=>$_->name.'_master',idtype=>$_)} @idtypes[0,1];
$masters[0]->history(1);
my $maptable=
  new Data::Babel::MapTable(name=>"maptable",idtypes=>"type_history type_explicit type_implicit");
my $babel=
  new Data::Babel(name=>'test',idtypes=>\@idtypes,masters=>\@masters,maptables=>[$maptable]);
isa_ok($babel,'Data::Babel','sanity test - $babel');

# create data & load database. 1 id per type. 1 row in maptable
# master 0
my @master_data=(["type_history/retired_1",undef],['type_history/x_1','type_history/a_1']);
load_master($babel,'type_history_master',@master_data);
# master 1
my @master_data=(['type_explicit/b_1']);
load_master($babel,'type_explicit_master',@master_data);
# maptable
my @maptable_data=[[qw(type_history/a_1 type_explicit/b_1 type_implicit/c_1)]];
load_maptable($babel,'maptable',@maptable_data);
$babel->load_implicit_masters;
load_ur($babel,'ur');
my $output_idtypes=[qw(type_history type_explicit type_implicit)]; # all idtypes

# sanity tests
my $ok=1;
my $correct=2;
my $actual=
  select_ur_sanity(babel=>$babel,urname=>'ur',
		   output_idtypes=>[qw(_X_type_history type_history type_explicit type_implicit)]);
$ok&&=is_loudly(scalar @$actual,$correct,'sanity test - ur construction');

# real tests
doit_all('type_history',["type_history/retired_1"],0,1,'retired id',__FILE__,__LINE__);
doit_all('type_history',["type_history/invalid_1"],0,1,'invalid id',__FILE__,__LINE__);
doit_all('type_history',["type_history/x_1"],1,1,'active id',__FILE__,__LINE__);
doit_all('type_history',[qw(type_history/retired_1 type_history/invalid_1)],0,2,
	 'retired+invalid id',__FILE__,__LINE__);
doit_all('type_history',[qw(type_history/retired_1 type_history/invalid_1 type_history/x_1)],1,3,
	 'retired+invalid+active id',__FILE__,__LINE__);

doit_all('type_explicit',["type_explicit/invalid_1"],0,1,'invalid id',__FILE__,__LINE__);
doit_all('type_explicit',["type_explicit/b_1"],1,1,'active id',__FILE__,__LINE__);
doit_all('type_explicit',[qw(type_explicit/invalid_1 type_explicit/b_1)],1,2,
	 'invalid+active id',__FILE__,__LINE__);

doit_all('type_implicit',["type_implicit/invalid_1"],0,1,'invalid id',__FILE__,__LINE__);
doit_all('type_implicit',["type_implicit/c_1"],1,1,'active id',__FILE__,__LINE__);
doit_all('type_implicit',[qw(type_implicit/invalid_1 type_implicit/c_1)],1,2,
	 'invalid+active id',__FILE__,__LINE__);

done_testing();

# $count0 is count w/o validate
# $count1 is count w/ validate
sub doit_all {
  my($idtype,$ids1,$count0,$count1,$label,$file,$line)=@_;
  my $count2=$count1;		# expect same count no matter how many copies
  my $ids2=[(@$ids1)x2];
  my $label01="$idtype no validate 1 $label";
  my $label02="$idtype no validate 2 $label(s)";
  my $label1="$idtype validate 1 $label";
  my $label2="$idtype validate 2 ${label}s";
  my $ok=1;
  $ok&&=doit($idtype,$ids1,$count0,$label01,undef,$file,$line);
  $ok&&=doit($idtype,$ids2,$count0,$label02,undef,$file,$line);
  $ok&&=doit($idtype,$ids1,$count1,$label1,'validate',$file,$line);
  $ok&&=doit($idtype,$ids2,$count2,$label2,'validate',$file,$line);
  $ok;
}
sub doit {
  my($idtype,$ids,$count,$label,$validate,$file,$line)=@_;
  my $correct=
    select_ur(babel=>$babel,validate=>$validate,
  	      input_idtype=>$idtype,input_ids=>$ids,output_idtypes=>$output_idtypes);
  is_quietly(scalar @$correct,$count,
	     "BAD NEWS: select_ur got wrong number of rows!! $label",$file,$line);
    # or return 0;
  my $actual=$babel->translate
    (input_idtype=>$idtype,input_ids=>$ids,output_idtypes=>$output_idtypes,validate=>$validate);
  cmp_table_quietly($actual,$correct,"$label translate",$file,$line) or return 0;
  my $actual=$babel->count
    (input_idtype=>$idtype,input_ids=>$ids,output_idtypes=>$output_idtypes,validate=>$validate);
  is_quietly($actual,scalar @$correct,"$label count",$file,$line) or return 0;
  pass($label);
  1;
}
