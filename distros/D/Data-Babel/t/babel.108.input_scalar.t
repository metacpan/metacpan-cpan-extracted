########################################
# regression test for input_ids=>scalar
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

# make component objects and Babel
my $idtypes=new Data::Babel::Config
  (file=>File::Spec->catfile(scriptpath,'handcrafted.idtype.ini'))->objects('IdType');
my $masters=new Data::Babel::Config
  (file=>File::Spec->catfile(scriptpath,'handcrafted.master.ini'))->objects('Master');
my $maptables=new Data::Babel::Config
  (file=>File::Spec->catfile(scriptpath,'handcrafted.maptable.ini'),tt=>1)->objects('MapTable');
my $babel=new Data::Babel
  (name=>'test',idtypes=>$idtypes,masters=>$masters,maptables=>$maptables);
isa_ok($babel,'Data::Babel','sanity test - $babel');

# setup the database
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile(scriptpath,'handcrafted.data.ini'))->autohash;
load_handcrafted_maptables($babel,$data);
load_handcrafted_masters($babel,$data);
$babel->load_implicit_masters;
load_ur($babel,'ur');

# test ur selection with input_ids=>scalar
my $correct=prep_tabledata($data->input_scalar->data);
my $actual=select_ur
  (babel=>$babel,urname=>'ur',input_idtype=>'type_001',input_ids=>'type_001/a_001',
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'sanity test - ur selection with input_ids=>scalar');

# test translate with input_ids=>scalar
my $correct=prep_tabledata($data->input_scalar->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>'type_001/a_001',
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with input_ids=>scalar');

done_testing();
