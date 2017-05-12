########################################
# regression test for internal idtypes
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use File::Spec;
use Class::AutoDB;
use Data::Babel;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test
Data::Babel->autodb($autodb);
my $dbh=$autodb->dbh;

# regular (external) idtype - usual case: new w/o internal or external set
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name');
check_idtype($idtype,'external',"external. new w/ defaults",__FILE__,__LINE__);
# external idtype - new w/ external=>1
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',external=>1);
check_idtype($idtype,'external',"external. new external=>1",__FILE__,__LINE__);
# external idtype - new w/ internal=>0
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',internal=>0);
check_idtype($idtype,'external',"external. new internal=>0",__FILE__,__LINE__);

# internal idtype - new w/ internal=>1
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',internal=>1);
check_idtype($idtype,'internal',"internal. new internal=>1",__FILE__,__LINE__);
# internal idtype - new w/ external=>0
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',external=>0);
check_idtype($idtype,'internal',"internal. new external=>0",__FILE__,__LINE__);

# test setting of external,internal
# external->external
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name');
$idtype->external(1);
check_idtype($idtype,'external',"external->external. set external(1)",__FILE__,__LINE__);
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name');
$idtype->internal(0);
check_idtype($idtype,'external',"external->external. set internal(0)",__FILE__,__LINE__);

# external->internal
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name');
$idtype->external(0);
check_idtype($idtype,'internal',"external->internal. set external(0)",__FILE__,__LINE__);
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name');
$idtype->internal(1);
check_idtype($idtype,'internal',"external->internal. set internal(1)",__FILE__,__LINE__);

# internal->external
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',internal=>1);
$idtype->external(1);
check_idtype($idtype,'external',"internal->external. set external(1)",__FILE__,__LINE__);
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',internal=>1);
$idtype->internal(0);
check_idtype($idtype,'external',"internal->external. set internal(0)",__FILE__,__LINE__);

# internal->internal
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',internal=>1);
$idtype->external(0);
check_idtype($idtype,'internal',"internal->internal. set external(0)",__FILE__,__LINE__);
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',internal=>1);
$idtype->internal(1);
check_idtype($idtype,'internal',"internal->internal. set internal(1)",__FILE__,__LINE__);

done_testing();

sub check_idtype {
  my($idtype,$what,$label,$file,$line)=@_;
  my $ok=1;
  my $display_name='display name';
  $display_name="$display_name: FOR INTERNAL USE ONLY" if $what eq 'internal';
  my $external=$what eq 'internal'? 0: 1;
  my $internal=$what eq 'internal'? 1: 0;
  $ok&&=report_fail($idtype->display_name eq $display_name,"$label: display_name",$file,$line);
  $ok&&=report_fail(as_bool($idtype->external)==$external,"$label: external",$file,$line);
  $ok&&=report_fail(as_bool($idtype->internal)==$internal,"$label: internal",$file,$line);
  report_pass($ok,$label);
}
