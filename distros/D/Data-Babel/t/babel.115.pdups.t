########################################
# explore the problem of pseudo duplicate rows
# in this example, we have rows that are identical on all non-null columns
#      gene_symbol  organism_name  gene_entrez  probe_id
#      HTT          human          3064         A_23_P212749
#      HTT          human          3064
#      Htt          rat            29424
#      Htt          mouse          15194
#      Htt          mouse          15194        A_55_P2088530
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
# NG 13-06-15: dropped '.dir' on subdir. can't remember why I put it on in the first place...
# my $confpath=File::Spec->catfile(scriptpath,scriptbasename.'.dir');
my $confpath=File::Spec->catfile(scriptpath,scriptbasename);

# do it first with data extracted from running Babel database
# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.idtype_htt.ini'))->objects('IdType');
my $maptables=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.maptable_htt.ini'),tt=>1)->objects('MapTable');
my $babel=new Data::Babel(name=>'test',idtypes=>$idtypes,maptables=>$maptables);

# setup the database
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.data_htt.ini'))->autohash;
for my $name(qw(gene_transcript probe_transcript gene_entrez gene_info)) {
  load_maptable($babel,$name,$data->$name->data);
}
# no explicit masters
$babel->load_implicit_masters;

# real tests start here
load_ur($babel,'ur');
my $output_idtypes=[qw(organism_name probe_id)];

my $correct=prep_tabledata($data->translate->data);
my $actual=select_ur
  (babel=>$babel,input_idtype=>'gene_symbol',input_ids=>'htt',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate htt - select_ur');

my $actual=$babel->translate
  (input_idtype=>'gene_symbol',input_ids=>'htt',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate htt');

########################################
# do it again with synthetic data
cleanup_db($autodb);		# cleanup database from previous test
# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.idtype_syn.ini'))->objects('IdType');
my $maptables=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.maptable_syn.ini'),tt=>1)->objects('MapTable');
my $babel=new Data::Babel(name=>'test',idtypes=>$idtypes,maptables=>$maptables);

# setup the database
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.data_syn.ini'))->autohash;
my @tables=qw(AX AB XC);
for my $name (@tables) {
  load_maptable($babel,$name,$data->$name->data);
}
# no explicit masters
$babel->load_implicit_masters;

# real tests start here. pass explicit join order to load_ur
load_ur($babel,'ur',@tables);
my $output_idtypes=[qw(B C)];

my $correct=prep_tabledata($data->translate->data);
my $actual=select_ur
  (babel=>$babel,input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate syn - select_ur');

my $actual=$babel->translate
  (input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate syn');

########################################
# do it again with synthetic data containing NULLs
cleanup_db($autodb);		# cleanup database from previous test
# no need to reread component objects - same as above

my $babel=new Data::Babel(name=>'test',idtypes=>$idtypes,maptables=>$maptables);

# setup the database
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.data_syn_nulls.ini'))->autohash;
my @tables=qw(AX AB XC);
for my $name (@tables) {
  load_maptable($babel,$name,$data->$name->data);
}
# no explicit masters
$babel->load_implicit_masters;

# real tests start here. pass explicit join order to load_ur
load_ur($babel,'ur',@tables);
my $output_idtypes=[qw(B C)];

my $correct=prep_tabledata($data->translate->data);
my $actual=select_ur
  (babel=>$babel,input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate syn w/ NULLs - select_ur');

my $actual=$babel->translate
  (input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate syn w/ NULLs');

########################################
# do it again with synthetic data having wide tables
cleanup_db($autodb);		# cleanup database from previous test
# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.idtype_wide.ini'))->objects('IdType');
my $maptables=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.maptable_wide.ini'),tt=>1)->objects('MapTable');
my $babel=new Data::Babel(name=>'test',idtypes=>$idtypes,maptables=>$maptables);

# setup the database
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.data_wide.ini'))->autohash;
my @tables=qw(XYZ A_X B_Y C_Z);
for my $name (@tables) {
  load_maptable($babel,$name,$data->$name->data);
}
# no explicit masters
$babel->load_implicit_masters;

# real tests start here. pass explicit join order to load_ur
load_ur($babel,'ur',@tables);
my $output_idtypes=[qw(B C)];

my $correct=prep_tabledata($data->translate->data);
my $actual=select_ur
  (babel=>$babel,input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate wide - select_ur');

my $actual=$babel->translate
  (input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate wide');

done_testing();

