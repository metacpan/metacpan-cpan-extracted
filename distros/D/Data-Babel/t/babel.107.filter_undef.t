########################################
# regression test for filter=>undef and related
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

# test ur selection with filter=>undef
my $correct=prep_tabledata($data->filter_undef->data);
my $actual=select_ur
  (babel=>$babel,urname=>'ur',input_idtype=>'type_001',filters=>{type_003=>undef},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'sanity test - ur selection with filter=>undef');

# test ur selection with filter=>[undef]
my $correct=prep_tabledata($data->filter_arrayundef->data);
my $actual=select_ur
  (babel=>$babel,urname=>'ur',input_idtype=>'type_001',filters=>{type_003=>[undef]},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'sanity test - ur selection with filter=>[undef]');

# test ur selection with filter=>[undef,111]
my $correct=prep_tabledata($data->filter_arrayundef_111->data);
my $actual=select_ur
  (babel=>$babel,urname=>'ur',input_idtype=>'type_001',
   filters=>{type_003=>[undef,'type_003/a_111']},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'sanity test - ur selection with filter=>[undef,111]');

########################################
# repeat above with ARRAY of filters
# test ur selection with filter=>undef
my $correct=prep_tabledata($data->filter_undef->data);
my $actual=select_ur
  (babel=>$babel,urname=>'ur',input_idtype=>'type_001',filters=>[type_003=>undef],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'sanity test - ur selection with ARRAY of filter=>undef');

# test ur selection with filter=>[undef]
my $correct=prep_tabledata($data->filter_arrayundef->data);
my $actual=select_ur
  (babel=>$babel,urname=>'ur',input_idtype=>'type_001',filters=>[type_003=>[undef]],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'sanity test - ur selection with ARRAY of filter=>[undef]');

# test ur selection with filter=>[undef,111]
my $correct=prep_tabledata($data->filter_arrayundef_111->data);
my $actual=select_ur
  (babel=>$babel,urname=>'ur',input_idtype=>'type_001',
   filters=>[type_003=>undef,type_003=>'type_003/a_111'],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'sanity test - ur selection with ARRAY of filter=>[undef,111]');

################################################################################
# now do translate tests
# test translate with filter=>undef
my $correct=prep_tabledata($data->filter_undef->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',filters=>{type_003=>undef},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with filter=>undef');

# test translate with filter=>[undef]
my $correct=prep_tabledata($data->filter_arrayundef->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',filters=>{type_003=>[undef]},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with filter=>[undef]');

# test translate with filter=>[undef,111]
my $correct=prep_tabledata($data->filter_arrayundef_111->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',filters=>{type_003=>[undef,'type_003/a_111']},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with filter=>[undef,111]');

########################################
# repeat above with ARRAY of filters
# test translate with filter=>undef
my $correct=prep_tabledata($data->filter_undef->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',filters=>[type_003=>undef],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with ARRAY of filter=>undef');

# test translate with filter=>[undef]
my $correct=prep_tabledata($data->filter_arrayundef->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',filters=>[type_003=>[undef]],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with ARRAY of filter=>[undef]');

# test translate with filter=>[undef,111]
my $correct=prep_tabledata($data->filter_arrayundef_111->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',
   filters=>[type_003=>undef,type_003=>'type_003/a_111'],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with ARRAY of filter=>[undef,111]');

done_testing();
