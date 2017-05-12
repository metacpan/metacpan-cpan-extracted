########################################
# regression test for validate not doing case insensitive comparisons, eg,
#   searching for 'htt' as gene_symbol
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
# uses in-memory conf files. might make sense to use these for other tests, but this
#   is the first time I've tried 'em
my $idtypes=<<IDTYPES
[GLOBAL]
sql_type=VARCHAR(255)
[abc]
[xyz]
IDTYPES
;
my $masters=<<MASTERS
[abc_master]
MASTERS
;
my $maptables=<<MAPTABLES
[abc_xyz]
idtypes=abc xyz
MAPTABLES
;
my $abc=<<DATA
abc
DATA
;
my $abc_xyz=<<DATA
ABC XYZ
Abc Xyz
aBc xYz
DATA
;
$idtypes=new Data::Babel::Config (file=>\$idtypes)->objects('IdType');
$masters=new Data::Babel::Config (file=>\$masters)->objects('Master');
$maptables=new Data::Babel::Config (file=>\$maptables)->objects('MapTable');
my $babel=new Data::Babel
  (name=>'test',idtypes=>$idtypes,masters=>$masters,maptables=>$maptables);
isa_ok($babel,'Data::Babel','sanity test - $babel');
# setup the database
load_master($babel,'abc_master',$abc);    # explicit master
load_maptable($babel,'abc_xyz',$abc_xyz); # maptable
$babel->load_implicit_masters;	          # implicit master
load_ur($babel,'ur');

# translate matching input id: select_ur & real
my $correct=prep_tabledata('abc xyz');
my $actual=select_ur(babel=>$babel,
		     input_idtype=>'abc',input_ids=>[qw(abc)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'translate - select_ur');
my $actual=$babel->translate(input_idtype=>'abc',input_ids=>[qw(abc)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'translate');
# + non-matching input id
my $correct=prep_tabledata('abc xyz');
my $actual=select_ur(babel=>$babel,
		     input_idtype=>'abc',input_ids=>[qw(abc INVALID)],
		     output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'translate + INVALID - select_ur');
my $actual=$babel->translate(input_idtype=>'abc',input_ids=>[qw(abc INVALID)],
			     output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'translate + INVALID');

# validate matching input id, matching case: select_ur & real
my $correct=prep_tabledata('abc 1 xyz');
my $actual=select_ur(babel=>$babel,validate=>1,
		     input_idtype=>'abc',input_ids=>[qw(abc)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate id & case match - select_ur');
my $actual=$babel->validate(input_idtype=>'abc',input_ids=>[qw(abc)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate id & case match');
# + non-matching input id
my $correct=prep_tabledata('abc 1 xyz','INVALID 0 NULL');
my $actual=
  select_ur(babel=>$babel,validate=>1,input_idtype=>'abc',input_ids=>[qw(abc INVALID)],
	    output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate id & case match + INVALID - select_ur');
my $actual=
  $babel->validate(input_idtype=>'abc',input_ids=>[qw(abc INVALID)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate id & case match + INVALID');

# validate matching input id, non-matching case: select_ur & real
my $correct=prep_tabledata('abc 1 xyz');
my $actual=
  select_ur(babel=>$babel,validate=>1,
	    input_idtype=>'abc',input_ids=>[qw(abC)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate id match but case different - select_ur');
my $actual=$babel->validate(input_idtype=>'abc',input_ids=>[qw(abC)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate id match but case different');
# + non-matching input id
my $correct=prep_tabledata('abc 1 xyz','INVALID 0 NULL');
my $actual=
  select_ur(babel=>$babel,validate=>1,
	    input_idtype=>'abc',input_ids=>[qw(abC INVALID)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase
  ($actual,$correct,'validate id match but case different + INVALID- select_ur');
my $actual=
  $babel->validate(input_idtype=>'abc',input_ids=>[qw(abC INVALID)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate id match but case different + INVALID');

# translate two matching input ids, different cases: select_ur & real
my $correct=prep_tabledata('abc xyz');
my $actual=
  select_ur(babel=>$babel,input_idtype=>'abc',input_ids=>[qw(abc abC)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,
	  'translate two matching input ids, different cases - select_ur');
my $actual=
  $babel->translate(input_idtype=>'abc',input_ids=>[qw(abc abC)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'translate two matching input ids, different cases');
# + non-matching input id
my $actual=
  select_ur(babel=>$babel,input_idtype=>'abc',input_ids=>[qw(abc abC INVALID)],
	    output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,
	  'translate two matching input ids, different cases + INVALID - select_ur');
my $actual=
  $babel->translate(input_idtype=>'abc',input_ids=>[qw(abc abC INVALID)],
		    output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,
		 'translate two matching input ids, different cases + INVALID');

# validate two matching input ids, different cases: select_ur & real
my $correct=prep_tabledata('abc 1 xyz');
my $actual=select_ur(babel=>$babel,validate=>1,
		     input_idtype=>'abc',input_ids=>[qw(abc abC)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate two matching input ids, different cases - select_ur');
my $actual=
  $babel->validate(input_idtype=>'abc',input_ids=>[qw(abc abC)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate two matching input ids, different cases');
# + non-matching input id
my $correct=prep_tabledata('abc 1 xyz','INVALID 0 NULL');
my $actual=
  select_ur(babel=>$babel,validate=>1,
	    input_idtype=>'abc',input_ids=>[qw(abc abC INVALID)],output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,
		 'validate two matching input ids, different cases + INVALID - select_ur');
my $actual=
  $babel->validate(input_idtype=>'abc',input_ids=>[qw(abc abC INVALID)],
		   output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate two matching input ids, different cases + INVALID');

# validate two matching input ids, different cases w/ filter: select_ur & real
my $correct=prep_tabledata('abc 1 xyz');
my $actual=select_ur(babel=>$babel,validate=>1,
		     input_idtype=>'abc',input_ids=>[qw(abc abC)],filters=>{xyz=>'xyz'},
		     output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,
		 'validate two matching input ids, different cases w/ filter - select_ur');
my $actual=
  $babel->validate(input_idtype=>'abc',input_ids=>[qw(abc abC)],filters=>{xyz=>'xyz'},
		   output_idtypes=>[qw(xyz)]);
cmp_table_nocase($actual,$correct,'validate two matching input ids, different cases w/ filter');
# + non-matching input id
my $correct=prep_tabledata('abc 1 xyz','INVALID 0 NULL');
my $actual=select_ur(babel=>$babel,validate=>1,
		     input_idtype=>'abc',input_ids=>[qw(abc abC INVALID)],filters=>{xyz=>'xyz'},
		     output_idtypes=>[qw(xyz)]);
cmp_table_nocase
  ($actual,$correct,
   'validate two matching input ids, different cases w/ filter + INVALID - select_ur');
my $actual=
  $babel->validate(input_idtype=>'abc',input_ids=>[qw(abc abC INVALID)],filters=>{xyz=>'xyz'},
		   output_idtypes=>[qw(xyz)]);
cmp_table_nocase
  ($actual,$correct,'validate two matching input ids, different cases w/ filter + INVALID');

done_testing();
