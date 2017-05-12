########################################
# regression test for bug found by DM: translate sometimes returns row with NULLs
# in all output columns, along with rows containing real values. want the NULL 
# "for example, if you supply Uniprot 'P09467' and ask for the 'transcript_ncbi'
#  you'll get a bunch of results, but also a NULL response".
# also tests related bug of NULL rows in implicit Masters
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
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
# NG 13-07-20: now works to have subdir with same name as test
# my $confpath=File::Spec->catfile(scriptpath,scriptbasename.'.dir');
my $confpath=File::Spec->catfile(scriptpath,scriptbasename);

# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.idtype.ini'))->objects('IdType');
my $masters=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.master.ini'))->objects('Master');
my $maptables=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.maptable.ini'),tt=>1)->objects('MapTable');
my $babel=new Data::Babel
  (name=>'test',idtypes=>$idtypes,masters=>$masters,maptables=>$maptables);
isa_ok($babel,'Data::Babel','sanity test - $babel');

# my @idtypes=map {new Data::Babel::IdType(name=>"type_$_",sql_type=>'VARCHAR(255)')} (1,2,3);
# my @masters=map {new Data::Babel::Master(name=>"type_${_}_master",babel=>'test')} (1);
# my @maptables=
#   (new Data::Babel::MapTable(name=>'maptable_12',idtypes=>'type_1 type_2',babel=>'test'),
#    new Data::Babel::MapTable(name=>'maptable_23',idtypes=>'type_2 type_3',babel=>'test'));
# my $babel=new Data::Babel
#   (name=>'test',idtypes=>\@idtypes,masters=>\@masters,maptables=>\@maptables);
# isa_ok($babel,'Data::Babel','class is Data::Babel - sanity check');

# setup the database
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.data.ini'))->autohash;
for my $name(qw(maptable_12 maptable_23)) {
  load_maptable($babel,$name,$data->$name->data);
}
# explicit master: type_1
load_master($babel,'type_1_master',$data->type_1_master->data);
# NG 12-09-30: use load_implicit_masters
$babel->load_implicit_masters;
# # implicit masters (no data): type_2, type3
# for my $name(qw(type_2 type_3)) {
#   load_master($babel,$name.'_master');
# }

# for sanity, check normal translate
my $correct=[[qw(type_1/1223 type_2/1223 type_3/1223)]];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/1223)],
   output_idtypes=>[qw(type_2 type_3)]);
cmp_table($actual,$correct,'sanity test - normal translate');

# real tests start here
# this block of tests checks for NULLs in implicit Masters
ok($babel->name2master('type_2_master')->implicit,'sanity test - type_2 Master is implicit');
my $correct=prep_tabledata($data->type_2_master->data);
my $actual=$dbh->selectall_arrayref(qq(SELECT type_2 FROM type_2_master));
cmp_table($actual,$correct,'type_2 Master');

ok($babel->name2master('type_3_master')->implicit,'sanity test - type_3 Master is implicit');
my $correct=prep_tabledata($data->type_3_master->data);
my $actual=$dbh->selectall_arrayref(qq(SELECT type_3 FROM type_3_master));
cmp_table($actual,$correct,'type_3 Master');

# finally on to the 'translate' tests
my $correct=[];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/does_not_exist)],
   output_idtypes=>[qw(type_2 type_3)]);
cmp_table($actual,$correct,'translate non-existent id (id not in Master)');

my $correct=[];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/0)],
   output_idtypes=>[qw(type_2 type_3)]);
cmp_table($actual,$correct,'translate id in Master but not MapTable');

my $correct=[];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/1)],
   output_idtypes=>[qw(type_2 type_3)]);
cmp_table($actual,$correct,'translate id in MapTable with NULL partner');

# this one should produce non-empty result, since type_2 has real value
my $correct=[[qw(type_1/12 type_2/12),undef]];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/12)],
   output_idtypes=>[qw(type_2 type_3)]);
cmp_table($actual,$correct,
	  'translate id in 1st MapTable with real partner but not 2nd. outputs=2,3');

# this one should produce empty result, since only output is type_3
my $correct=[];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/12)],
   output_idtypes=>[qw(type_3)]);
cmp_table($actual,$correct,
	  'translate id in 1st MapTable with real partner but not 2nd. outputs=3');

# this one should produce non-empty result, since type_2 has real value
my $correct=[[qw(type_1/122 type_2/122),undef]];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/122)],
   output_idtypes=>[qw(type_2 type_3)]);
cmp_table($actual,$correct,
	  'translate id in 2nd MapTable with NULL partner. outputs=2,3');

# this one should produce empty result, since only output is type_3
my $correct=[];
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>[qw(type_1/122)],
   output_idtypes=>[qw(type_3)]);
cmp_table($actual,$correct,
	  'translate id in 2nd MapTable with NULL partner. outputs=3');

my $correct=[[qw(type_1/12 type_2/12),undef],
	     [qw(type_1/122 type_2/122),undef],
	     [qw(type_1/1223 type_2/1223 type_3/1223)]];
my $actual=$babel->translate
  (input_idtype=>'type_1',
   input_ids=>[qw(type_1/does_not_exist type_1/0 type_1/1 type_1/12 type_1/122 type_1/1223)],
   output_idtypes=>[qw(type_2 type_3)]);
cmp_table($actual,$correct,
	  'translate all ids (explicit values). outputs=2,3');

my $correct=[[qw(type_1/1223 type_3/1223)]];
my $actual=$babel->translate
  (input_idtype=>'type_1',
   input_ids=>[qw(type_1/does_not_exist type_1/0 type_1/1 type_1/12 type_1/122 type_1/1223)],
   output_idtypes=>[qw(type_3)]);
cmp_table($actual,$correct,
	  'translate all ids (explicit values). outputs=3');

# NG 11-10-21: test translate all
# NG 12-08-22: test other ways of saying input_ids_all=>1
# only a few cases worth testing.
load_ur($babel,'ur');

my $output_idtypes=[qw(type_2)];
my $correct=select_ur
  (babel=>$babel,input_idtype=>'type_1',input_ids_all=>1,output_idtypes=>$output_idtypes);
my $actual=$babel->translate
  (input_idtype=>'type_1',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids absent). outputs=2');
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>undef,output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids=>undef). outputs=2');
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids_all=>1,output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids_all=>1). outputs=2');

my $output_idtypes=[qw(type_3)];
my $correct=select_ur
  (babel=>$babel,input_idtype=>'type_1',input_ids_all=>1,output_idtypes=>$output_idtypes);
my $actual=$babel->translate
  (input_idtype=>'type_1',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids absent). outputs=3');
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>undef,output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids=>undef). outputs=3');
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids_all=>1,output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids_all=>1). outputs=3');

my $output_idtypes=[qw(type_2 type_3)];
my $correct=select_ur
  (babel=>$babel,input_idtype=>'type_1',input_ids_all=>1,output_idtypes=>$output_idtypes);
my $actual=$babel->translate
  (input_idtype=>'type_1',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids absent). outputs=2,3');
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids=>undef,output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids=>undef). outputs=2,3');
my $actual=$babel->translate
  (input_idtype=>'type_1',input_ids_all=>1,output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate all (input_ids_all=>1). outputs=2,3');

done_testing();
