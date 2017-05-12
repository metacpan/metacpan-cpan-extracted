########################################
# 013.filter_basics -- some parts adapted from 010.basics
########################################
use t::lib;
use t::utilBabel;
use Test::More;
use Test::Deep;
use File::Spec;
use Class::AutoDB;
use Data::Babel;
use Data::Babel::Filter;
use strict;

# create AutoDB database
my $autodb=new Class::AutoDB(database=>'test',create=>1); 
isa_ok_quietly($autodb,'Class::AutoDB','sanity test - $autodb');
cleanup_db($autodb);		# cleanup database from previous test

# create Babel directly from config files. this is is the usual case
my $babel=new Data::Babel
  (name=>'test',autodb=>$autodb,
   idtypes=>File::Spec->catfile(scriptpath,'handcrafted.idtype.ini'),
   masters=>File::Spec->catfile(scriptpath,'handcrafted.master.ini'),
   maptables=>File::Spec->catfile(scriptpath,'handcrafted.maptable.ini'));
isa_ok_quietly($babel,'Data::Babel','Babel created from config files');

my $data=new Data::Babel::Config
  (file=>File::Spec->catfile(scriptpath,'handcrafted.data.ini'))->autohash;
load_handcrafted_maptables($babel,$data);
$babel->load_implicit_masters;
load_handcrafted_masters($babel,$data);

########################################
# NG 12-08-22: added filter
my $correct=prep_tabledata($data->basics_filter->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>{type_004=>'type_004/a_111'},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate filter (scalar)');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>{type_004=>['type_004/a_111']},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate filter (ARRAY)');

# NG 12-08-22: added ways of saying 'ignore this filter'
my $correct=prep_tabledata($data->basics->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>undef,output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with undef filters arg');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>'',output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with empty filters arg (string)');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>\ '',output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with empty filters arg (string ref)');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>{},output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with empty filters arg (HASH)');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>[],output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with empty filters arg (ARRAY)');


# NG 12-09-22: added ARRAY of filters
my $correct=prep_tabledata($data->basics_filter->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>[type_004=>'type_004/a_111'],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with ARRAY of filters (1 filter)');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>[type_001=>'type_001/a_111',type_002=>'type_002/a_111',type_003=>'type_003/a_111',
	     type_004=>'type_004/a_111',type_004=>'type_004/a_111'],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with ARRAY of filters (multiple filters)');

# NG 13-07-16: filter=>'invalid',filter=>[] - match nothing
my $correct=[];
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>[type_004=>'invalid'],
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with filter matching nothing (scalar)');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>{type_004=>['invalid']},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with filter matching nothing (ARRAY)');
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>{type_004=>[]},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate with filter matching nothing (empty ARRAY)');

########################################
# NG 12-09-22: added/fixed filter=>undef and related
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

# NG 13-07-16: test big IN
my $big=10000;
my $correct=prep_tabledata($data->basics_filter->data);
my @filter_ids=('type_004/a_111');
push(@filter_ids,map {"extra_$_"} (1..$big));
my $actual=$babel->translate
  (input_idtype=>'type_001',input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>{type_004=>\@filter_ids},
   output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate filter big IN');

########################################
# NG 12-08-25: added using objects as idtypes
my $correct=prep_tabledata($data->basics_filter->data);
my $actual=$babel->translate
  (input_idtype=>$babel->name2idtype('type_001'),
   input_ids=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
   filters=>{$babel->name2idtype('type_004')=>'type_004/a_111'},
   output_idtypes=>[map {$babel->name2idtype($_)} qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,'translate using objects as idtypes');

########################################
# NG 13-10-14: added 'validate' + 'filter'
my $label='basics_validate_filter';
my $correct=prep_tabledata($data->$label->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',
  input_ids=>[qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_111)],
  filters=>{type_004=>'type_004/a_111'},
  validate=>1,output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,"translate $label");

my $label='validate_filter_undef';
my $correct=prep_tabledata($data->$label->data);
my $actual=$babel->translate
   (input_idtype=>'type_001',filters=>{type_003=>undef},
   validate=>1,output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,"translate $label");

my $label='validate_filter_arrayundef';
my $correct=prep_tabledata($data->$label->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',filters=>{type_003=>[undef]},
   validate=>1,output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,"translate $label");

my $label='validate_filter_arrayundef_111';
my $correct=prep_tabledata($data->$label->data);
my $actual=$babel->translate
  (input_idtype=>'type_001',filters=>[type_003=>[undef,'type_003/a_111']],
   validate=>1,output_idtypes=>[qw(type_002 type_003 type_004)]);
cmp_table($actual,$correct,"translate $label");

########################################
# NG 13-10-14: added SQL filters

test_query('basics',undef,undef,type_001=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)]);
test_query('basics_all',undef,undef,
	   type_001=>[qw(type_001/a_000 type_001/a_001 type_001/a_010 type_001/a_011 
			 type_001/a_100 type_001/a_101 type_001/a_110 type_001/a_111)]);
test_query('basics_filter',undef,undef,
	   type_001=>[qw(type_001/a_000 type_001/a_001 type_001/a_111)],
	   type_004=>'type_004/a_111');
test_query('filter_undef',undef,undef,type_003=>\'IS NOT NULL');
test_query('filter_arrayundef',undef,undef,type_003=>\'IS NULL');
test_query('filter_arrayundef_111',undef,undef,type_003=>\'IS NULL OR type_003="type_003/a_111"');

test_query('basics_validate_filter',
	   [qw(type_001/invalid type_001/a_000 type_001/a_001 type_001/a_111)],'validate',
	   type_004=>'type_004/a_111');
test_query('validate_filter_undef',undef,'validate',type_003=>\'IS NOT NULL');
test_query('validate_filter_arrayundef',undef,'validate',type_003=>\'IS NULL');
test_query('validate_filter_arrayundef_111',undef,'validate',
	   type_003=>\'IS NULL OR type_003="type_003/a_111"');

done_testing();

sub test_query {
  my($label,$input_ids,$validate,%filters)=@_;
  my $correct=prep_tabledata($data->$label->data);
  # make various query forms
  my(@sql,%sql_notype,%sql_default,%sql_explicit);
  while (my($type,$values)=each %filters) {
    my $sql=('SCALAR' eq ref $values)? $$values: sql_in($values);
    push(@sql,"$type $sql");
    $sql_notype{$type}=\$sql;
    $sql_default{$type}=\": $sql";
    $sql_explicit{$type}=\":$type $sql";
  }
  my $sql=join(' AND ',@sql);
  # do the tests
  # filters=>sql
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>$sql);
  cmp_table_quietly($actual,$correct,"translate $label filters=>sql (string)") or return 0;
  # filters=>\sql
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>\$sql);
  cmp_table_quietly($actual,$correct,"translate $label filters=>sql (string ref)") or return 0;
  # filters=>object
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],
     filters=>new Data::Babel::Filter
     (babel=>$babel,prepend_idtype=>undef,conditions=>\$sql));
  cmp_table_quietly($actual,$correct,"translate $label filters=>sql (object)") or return 0;
  # HASH or ARRAY w/o embdedded idtype
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>\%sql_notype);
  cmp_table_quietly
    ($actual,$correct,
     "translate $label filters=>sql without embedded idtype (HASH)") or return 0;
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>[%sql_notype]);
  cmp_table_quietly
    ($actual,$correct,
     "translate $label filters=>sql without embedded idtype (ARRAY)") or return 0;
  # HASH or ARRAY w/ embdedded default idtype
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>\%sql_default);
  cmp_table_quietly
    ($actual,$correct,
     "translate $label filters=>sql with embedded default idtype (HASH)") or return 0;
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>[%sql_default]);
  cmp_table_quietly
    ($actual,$correct,
     "translate $label filters=>sql with embedded default idtype (ARRAY)") or return 0;
  # HASH or ARRAY w/ embdedded explicit idtype
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>\%sql_explicit);
  cmp_table_quietly
    ($actual,$correct,
     "translate $label filters=>sql with embedded explicit idtype (HASH)") or return 0;
  my $actual=$babel->translate
    (input_idtype=>'type_001',input_ids=>$input_ids,validate=>$validate,
     output_idtypes=>[qw(type_002 type_003 type_004)],filters=>[%sql_explicit]);
  cmp_table_quietly
    ($actual,$correct,
     "translate $label filters=>sql with embedded explicit idtype (ARRAY)") or return 0;

  pass("$label query");
}
