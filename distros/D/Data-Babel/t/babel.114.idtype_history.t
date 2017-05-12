########################################
# regression test for specifying history in IdTypes
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
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

# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=<<IDTYPES
[GLOBAL]
sql_type=VARCHAR(255)
[no_history]
[master_history]
[idtype_history]
history=1
[both_history]
history=1
IDTYPES
;
my $masters=<<MASTERS
[master_history_master]
history=1
[idtype_history_master]
[both_history_master]
history=1
MASTERS
;
my $maptables=<<MAPTABLES
[maptable]
idtypes=no_history master_history idtype_history both_history
MAPTABLES
;
my $master_history=<<DATA
old_master_history master_history
DATA
;
my $idtype_history=<<DATA
old_idtype_history idtype_history
DATA
;
my $both_history=<<DATA
old_both_history both_history
DATA
;
my $maptable=<<DATA
no_history master_history idtype_history both_history
DATA
;
$idtypes=new Data::Babel::Config (file=>\$idtypes)->objects('IdType');
$masters=new Data::Babel::Config (file=>\$masters)->objects('Master');
$maptables=new Data::Babel::Config (file=>\$maptables)->objects('MapTable');
# test histories before making Babel
my %actual=map {$_->name=>$_->history} @$idtypes;
my %correct=(no_history=>0,master_history=>0,idtype_history=>1,both_history=>1);
cmp_history_attrs(\%actual,\%correct,'IdType histories before making Babel',__FILE__,__LINE__);
my %actual=map {$_->name=>$_->history} @$masters;
my %correct=(master_history_master=>1,idtype_history_master=>0,both_history_master=>1);
cmp_history_attrs(\%actual,\%correct,'Master histories before making Babel',__FILE__,__LINE__);

my $babel=new Data::Babel
  (name=>'test',idtypes=>$idtypes,masters=>$masters,maptables=>$maptables);
isa_ok($babel,'Data::Babel','sanity test - $babel');
# test histories after making Babel
my %actual=map {$_->name=>$_->history} @$idtypes;
my %correct=(no_history=>0,master_history=>1,idtype_history=>1,both_history=>1);
cmp_history_attrs(\%actual,\%correct,'IdType histories after making Babel',__FILE__,__LINE__);
my %actual=map {$_->name=>$_->history} @$masters;
my %correct=(no_history_master=>0,master_history_master=>1,
	     idtype_history_master=>1,both_history_master=>1);
cmp_history_attrs(\%actual,\%correct,'Master histories after making Babel',__FILE__,__LINE__);

# setup the database
load_master($babel,'master_history_master',$master_history);
load_master($babel,'idtype_history_master',$idtype_history);
load_master($babel,'both_history_master',$both_history);
load_maptable($babel,'maptable',$maptable);
$babel->load_implicit_masters;
load_ur($babel,'ur');

# do translates to make sure histories worked
my $output_idtypes=[qw(no_history master_history idtype_history both_history)];
my $correct=[];
my $actual=$babel->translate(input_idtype=>'no_history',input_ids=>'old_no_history',
			     output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate no_history');

my $correct=[[qw(old_master_history no_history master_history idtype_history both_history)]];
my $actual=$babel->translate(input_idtype=>'master_history',input_ids=>'old_master_history',
			     output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate master_history');

my $correct=[[qw(old_idtype_history no_history master_history idtype_history both_history)]];
my $actual=$babel->translate(input_idtype=>'idtype_history',input_ids=>'old_idtype_history',
			     output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate idtype_history');

my $correct=[[qw(old_both_history no_history master_history idtype_history both_history)]];
my $actual=$babel->translate(input_idtype=>'both_history',input_ids=>'old_both_history',
			     output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate both_history');

done_testing();

sub cmp_history_attrs {
  my($actual,$correct,$label,$file,$line)=@_;
  my $ok=1;
  for my $key (sort keys %$actual) {
    my $a=$actual->{$key};
    my $c=$correct->{$key};
    $ok=report_fail($a==$c,"$label: $key got $a, expect $c",$file,$line) && $ok;
  }
  report_pass($ok,$label);
}


