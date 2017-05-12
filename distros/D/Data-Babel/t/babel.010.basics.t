########################################
# 010.basics -- start fresh. create components & Babel. test.
# don't worry about persistence. tested separately
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
use List::MoreUtils qw(natatime);
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Config;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test

my $name='test';
# expect 'old' to return undef, because database is empty
my $babel=old Data::Babel(name=>$name,autodb=>$autodb);
ok(!$babel,'old on empty database returned undef');

# create Babel directly from config files. this is is the usual case
$babel=new Data::Babel
  (name=>$name,
   idtypes=>File::Spec->catfile(scriptpath,'handcrafted.idtype.ini'),
   masters=>File::Spec->catfile(scriptpath,'handcrafted.master.ini'),
   maptables=>File::Spec->catfile(scriptpath,'handcrafted.maptable.ini'));
isa_ok($babel,'Data::Babel','Babel created from config files');

# test simple attributes
is($babel->name,$name,'Babel attribute: name');
is($babel->id,"babel:$name",'Babel attribute: id');
is($babel->autodb,$autodb,'Babel attribute: autodb');
#is($babel->log,$log,'Babel attribute: log');
# test component-object attributes
check_handcrafted_idtypes($babel->idtypes,'mature','Babel attribute: idtypes');
check_handcrafted_masters($babel->masters,'mature','Babel attribute: masters');
check_handcrafted_maptables($babel->maptables,'mature','Babel attribute: maptables');

# test internal IdType (external tested by check_handcrafted_idtypes)
my $idtype=new Data::Babel::IdType(name=>'test',display_name=>'display name',internal=>1);
{
  my $ok=1; my $label='internal IdType';
  $ok&&=report_fail($idtype->display_name eq 'display name: FOR INTERNAL USE ONLY',
		    "$label: display_name");
  $ok&&=report_fail(as_bool($idtype->external)==0,"$label: external method");
  $ok&&=report_fail(as_bool($idtype->internal)==1,"$label: internal method");
  report_pass($ok,$label);
}

# next create Babel from component objects. 
# first, extract components from existing Babel. 
#   do it this way, rather than re-reading config files, to preserve MapTable names
my($idtypes,$masters,$maptables)=$babel->get(qw(idtypes masters maptables));
@$masters=grep {$_->explicit} @$masters; # remove implicit Masters, since Babel makes them

# check component objects
check_handcrafted_idtypes($idtypes);
check_handcrafted_masters($masters);
check_handcrafted_maptables($maptables);

# create Babel using existing component objects
$babel=new Data::Babel
  (name=>$name,idtypes=>$idtypes,masters=>$masters,maptables=>$maptables);
isa_ok($babel,'Data::Babel','Babel created from component objects');

# test simple attributes
is($babel->name,$name,'Babel attribute: name');
is($babel->id,"babel:$name",'Babel attribute: id');
is($babel->autodb,$autodb,'Babel attribute: autodb');
#is($babel->log,$log,'Babel attribute: log');
# test component-object attributes
check_handcrafted_idtypes($babel->idtypes,'mature','Babel attribute: idtypes');
check_handcrafted_masters($babel->masters,'mature','Babel attribute: masters');
check_handcrafted_maptables($babel->maptables,'mature','Babel attribute: maptables');

# show: just make sure it prints something..
# redirect STDOUT to a string. adapted from perlfunc
my $showout;
open my $oldout,">&STDOUT" or fail("show: can't dup STDOUT: $!");
close STDOUT;
open STDOUT, '>',\$showout or fail("show: can't redirect STDOUT to string: $!");
$babel->show;
close STDOUT;
open STDOUT,">&",$oldout or fail("show: can't restore STDOUT: $!");
ok(length($showout)>500,'show');

# show_schema_graph: just make sure it prints right number of lines.
my $correct=6;
my $showout;
open my $oldout,">&STDOUT" or fail("show: can't dup STDOUT: $!");
close STDOUT;
open STDOUT, '>',\$showout or fail("show: can't redirect STDOUT to string: $!");
$babel->show_schema_graph;
close STDOUT;
open STDOUT,">&",$oldout or fail("show: can't restore STDOUT: $!");
is(scalar(split("\n",$showout)),$correct,'show_schema_graph sif (implicit)');

my $showout;
open my $oldout,">&STDOUT" or fail("show: can't dup STDOUT: $!");
close STDOUT;
open STDOUT, '>',\$showout or fail("show: can't redirect STDOUT to string: $!");
$babel->show_schema_graph(undef,'sif');
close STDOUT;
open STDOUT,">&",$oldout or fail("show: can't restore STDOUT: $!");
is(scalar(split("\n",$showout)),$correct,'show_schema_graph sif (explicit)');

my $showout;
open my $oldout,">&STDOUT" or fail("show: can't dup STDOUT: $!");
close STDOUT;
open STDOUT, '>',\$showout or fail("show: can't redirect STDOUT to string: $!");
$babel->show_schema_graph(undef,'txt');
close STDOUT;
open STDOUT,">&",$oldout or fail("show: can't restore STDOUT: $!");
is(scalar(split("\n",$showout)),$correct,'show_schema_graph txt (explicit)');

# check_schema: should be true.
my @errstrs=$babel->check_schema;
ok(!@errstrs,'check_schema array context');
ok(scalar($babel->check_schema),'check_schema boolean context');

# test name2xxx & related methods
check_handcrafted_name2idtype($babel);
check_handcrafted_name2master($babel);
check_handcrafted_name2maptable($babel);
check_handcrafted_id2object($babel);
check_handcrafted_id2name($babel);

# basic translate test. much more in later tests
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile(scriptpath,'handcrafted.data.ini'))->autohash;
load_handcrafted_maptables($babel,$data);
# NG 12-09-27: added load_implicit_masters
$babel->load_implicit_masters;
check_implicit_masters($babel,$data,'load_implicit_masters',__FILE__,__LINE__);
load_handcrafted_masters($babel,$data);
# load_ur($babel,'ur');
# NG 13-09-02: added check_contents: should be true.
my @errstrs=$babel->check_contents;
ok(!@errstrs,'check_contents array context');
ok(scalar($babel->check_contents),'check_contents boolean context');

my $correct=prep_tabledata($data->basics->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate');
# NG 12-08-24: added test for empty input_ids
my $correct=[];
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[],output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate empty input_ids');
# NG 11-10-21: added translate all
# NG 12-08-22: added other ways of saying 'translate all'
my $correct=prep_tabledata($data->basics_all->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate all: input_ids absent');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>undef,
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate all: input_ids=>undef');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids_all=>1,
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate all: input_ids_all=>1');
# NG 13-07-19: keep_pdups. minimal test since there are not pdups in this data...
my $actual=$babel->translate
  (input_idtype=>'type_001',keep_pdups=>1,
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate all: keep partial duplicates');

# NG 10-11-08: test limit
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   output_idtypes=>[qw(type_002 type_003 type_004)],
   limit=>1);
cmp_table($actual,$correct,'translate with limit',undef,undef,1);
# NG 12-09-22: added inputs_ids=>scalar
my $correct=prep_tabledata($data->input_scalar->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>'type_001/a_001',
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with input_ids=>scalar');
# NG 13-07-16: test big IN
my $big=10000;
my $correct=prep_tabledata($data->basics->data);
my @input_ids=qw(type_001/a_000 type_001/a_001 type_001/a_111);
push(@input_ids,map {"extra_$_"} (1..$big));
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>\@input_ids,
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate big IN');

########################################
# NG 12-09-23: added count
my $correct=prep_tabledata($data->basics->data);
$correct=scalar @$correct;
my $actual=$babel->count
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
is($actual,$correct,'count: method');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   output_idtypes=>[qw(type_002 type_003 type_004)],count=>1);
is($actual,$correct,'count: option');
# empty input_ids
my $correct=0;
my $actual=$babel->count
  (input_idtype=>'type_001',input_ids=>[],output_idtypes=>[qw(type_002 type_003 type_004)]);
is($actual,$correct,'count empty input_ids: method');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[],output_idtypes=>[qw(type_002 type_003 type_004)],
  count=>1);
is($actual,$correct,'count empty input_ids: option');
# translate all
my $correct=prep_tabledata($data->basics_all->data);
$correct=scalar @$correct;
my $actual=$babel->count
  (input_idtype=>'type_001',
   output_idtypes=>[qw(type_002 type_003 type_004)]);
is($actual,$correct,'count all: method');
my $actual=$babel->translate
  (input_idtype=>'type_001',
   output_idtypes=>[qw(type_002 type_003 type_004)],count=>1);
is($actual,$correct,'count all: option');

# NG 13-07-19: keep_pdups. minimal test since there are not pdups in this data...
my $actual=$babel->count
  (input_idtype=>'type_001',keep_pdups=>1,
   output_idtypes=>[qw(type_002 type_003 type_004)]);
is($actual,$correct,'count all: method: keep partial duplicates');
my $actual=$babel->translate
  (input_idtype=>'type_001',keep_pdups=>1,
   output_idtypes=>[qw(type_002 type_003 type_004)],count=>1);
is($actual,$correct,'count all: option: keep partial duplicates');

# inputs_ids=>scalar
my $correct=prep_tabledata($data->input_scalar->data);
$correct=scalar @$correct;
my $actual=$babel->count
  (input_idtype=>'type_001',input_ids=>'type_001/a_001',
   output_idtypes=>[qw(type_002 type_003 type_004)]);
is($actual,$correct,'count input_ids=>scalar: method');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>'type_001/a_001',
   output_idtypes=>[qw(type_002 type_003 type_004)],count=>1);
is($actual,$correct,'count input_ids=>scalar: option');
# NG 13-07-16: test big IN
my $big=10000;
my $correct=prep_tabledata($data->basics->data);
$correct=scalar @$correct;
my @input_ids=qw(type_001/a_000 type_001/a_001 type_001/a_111);
push(@input_ids,map {"extra_$_"} (1..$big));
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>\@input_ids,
   output_idtypes=>[qw(type_002 type_003 type_004)],count=>1);
is($actual,$correct,'count big IN');

########################################
# NG 12-11-23: added validate option
my $correct=prep_tabledata($data->basics_validate_option->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',
   input_ids=>[qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_011 
		  type_001/a_110 type_001/a_111)],
   validate=>1,output_idtypes=>['type_003']);
cmp_table($actual,$correct,'translate with validate');
# NG 13-07-19: keep_pdups. minimal test since there are not pdups in this data...
my $actual=$babel->translate
  (input_idtype=>'type_001',
   input_ids=>[qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_011 
		  type_001/a_110 type_001/a_111)],
   validate=>1,keep_pdups=>1,output_idtypes=>['type_003']);
cmp_table($actual,$correct,'translate with validate: keep partial duplicates');

########################################
# NG 12-11-25: added validate method
my $correct=prep_tabledata($data->basics_validate_method->data);
my $actual=$babel->validate
  (input_idtype=>'type_001',
   input_ids=>[qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_011 
		  type_001/a_110 type_001/a_111)]);
cmp_table($actual,$correct,'validate');
# NG 13-07-19: keep_pdups. minimal test since there are not pdups in this data...
my $actual=$babel->validate
  (input_idtype=>'type_001',
   input_ids=>[qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_011 
		  type_001/a_110 type_001/a_111)],
   keep_pdups=>1);
cmp_table($actual,$correct,'validate: keep partial duplicates');
# NG 12-11-26: allowed output_idtypes in validate method
my $correct=prep_tabledata($data->basics_validate_option->data);
my $actual=$babel->validate
  (input_idtype=>'type_001',
   input_ids=>[qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_011 
		  type_001/a_110 type_001/a_111)],validate=>1,
   output_idtypes=>['type_003']);
cmp_table($actual,$correct,'validate with output idtypes');
# NG 13-07-16: test big IN
my $big=1000;			# smaller than usual $big, else test too slow
my $correct=prep_tabledata($data->basics_validate_method->data);
my @extra_ids=map {"extra_$_"} (1..$big);
push(@$correct,map {[$_,0,undef]} @extra_ids);
my @input_ids=
  qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_011 type_001/a_110 type_001/a_111);
push(@input_ids,@extra_ids);
my $actual=$babel->validate(input_idtype=>'type_001',input_ids=>\@input_ids);
cmp_table($actual,$correct,'validate big IN');

########################################
# NG 13-10-15: moved filter tests to separate script
########################################
# make schema bad in all possible ways: cyclic, disconnected, isolated IdType, unknown IdType
use Data::Babel::MapTable;
my $cyclic_maptable=new Data::Babel::MapTable(name=>'cyclic',idtypes=>'type_004 type_001');
my @disconnected_idtypes=
  (new Data::Babel::IdType(name=>'disconnected_1'),
   new Data::Babel::IdType(name=>'disconnected_2'));
my $disconnected_maptable=new Data::Babel::MapTable
  (name=>'disconnected',idtypes=>'disconnected_1 disconnected_2');
my $isolated_idtype=new Data::Babel::IdType(name=>'isolated');
my $unknown_maptable=new Data::Babel::MapTable(name=>'unknown',idtypes=>'unknown type_001');

# NG 13-06-11: Babel constructor tests for isolated and unknown IdTypes, so don't
#              include in first test
my $bad=new Data::Babel
  (name=>'bad',
   idtypes=>[@$idtypes,@disconnected_idtypes],masters=>$masters,
   maptables=>[@$maptables,$cyclic_maptable,$disconnected_maptable]);

my @errstrs=$bad->check_schema;
ok((@errstrs==2 && 
   grep(/not connected/,@errstrs) && 
   grep(/cyclic/,@errstrs)),
   'check_schema array context: bad schema - disconnected, cyclic');
ok(!$bad->check_schema,'check_schema boolean context: bad schema - disconnected, cyclic');

# NG 13-06-11: Babel constructor tests for isolated and unknown IdTypes
eval {
  my $bad=new Data::Babel
    (name=>'bad',
     idtypes=>[@$idtypes,$isolated_idtype],masters=>$masters,
     maptables=>$maptables);
};
my $err=$@;
my $err_head='Some IdType\(s\) are \'isolated\', ie, not in any MapTable:';
like($err,qr/^$err_head/,'bad schema - isolated IdType');

eval {
  my $bad=new Data::Babel
    (name=>'bad',
     idtypes=>$idtypes,masters=>$masters,maptables=>[@$maptables,$unknown_maptable]);
};
my $err=$@;
my $err_head='Unknown IdType\(s\) appear in MapTables:';
like($err,qr/^$err_head/,'bad schema - unknown IdType');

########################################
# make contents bad by inserting some new values into maptable_001, maptable_002
# remake babel and reload the database
my $babel=new Data::Babel
  (name=>$name,
   idtypes=>File::Spec->catfile(scriptpath,'handcrafted.idtype.ini'),
   masters=>File::Spec->catfile(scriptpath,'handcrafted.master.ini'),
   maptables=>File::Spec->catfile(scriptpath,'handcrafted.maptable.ini'));
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile(scriptpath,'handcrafted.data.ini'))->autohash;
load_handcrafted_maptables($babel,$data);
# NG 12-09-27: added load_implicit_masters
$babel->load_implicit_masters;
load_handcrafted_masters($babel,$data);
# add the extra rows
my $dbh=$babel->dbh;
my $sql=qq(INSERT INTO maptable_001 (type_001,type_002)
           VALUES ('type_001/extra_001','type_002/extra_001'));
$dbh->do($sql);
report_fail(!$dbh->errstr,'database insert failed: '.$dbh->errstr);
my $sql=qq(INSERT INTO maptable_002 (type_002,type_003)
           VALUES ('type_002/extra_001','type_003/extra_001'),
                  ('type_002/extra_002','type_003/extra_002'),
                  ('type_002/extra_003','type_003/extra_003'),
                  ('type_002/extra_004','type_003/extra_004'),
                  ('type_002/extra_005','type_003/extra_005'),
                  ('type_002/extra_006','type_003/extra_006'));
$dbh->do($sql);
report_fail(!$dbh->errstr,'database insert failed: '.$dbh->errstr);
my @errstrs=$babel->check_contents;
is(scalar @errstrs,3,'bad contents - number of errors');
my @err_infos=map {/^(\w+): missing (\d+) ids from (\w+)/} @errstrs;
my $it=natatime 3,@err_infos;
my $actual=[];
while (my @err_info=$it->()) {
  push(@$actual,join(' ',@err_info));
}
my $correct=['type_001 1 maptable_001','type_002 1 maptable_001','type_002 6 maptable_002'];
cmp_deeply($actual,$correct,'bad contents - error information');

done_testing();

