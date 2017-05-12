########################################
# 'apostrophe' bug: ID containing apostrophe can trigger bug in partial duplicate removal
# problem is in PrefixMatcher::Exact - uses Hash::AutoHash::MultiValued w/ method notation
#   and turns out that method names containing apostrophe don't work...
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
my $confpath=File::Spec->catfile(scriptpath,scriptbasename);

# do it first with data extracted from running Babel database
# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.idtype.ini'))->objects('IdType');
my $masters=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.master.ini'))->objects('Master');
my $maptables=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.maptable.ini'),tt=>1)->objects('MapTable');
my $babel=new Data::Babel
  (name=>'test',idtypes=>$idtypes,masters=>$masters,maptables=>$maptables,
   pdups_group_cutoff=>0,pdups_prefixmatcher_cutoff=>0);

# setup the database
my $data=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.data.ini'))->autohash;
# do gene_info specially since description contains whitespace
my $name='gene_info';
my $gene_info=$data->$name->data;
my @gene_info=split(/\n/,$gene_info);
load_maptable($babel,$name,map {[split(' ',$_,4)]} @gene_info);
for my $name(qw(gene_transcript gene_entrez probe_transcript)) {
  load_maptable($babel,$name,$data->$name->data);
}
# explicit master: probe_id
load_master($babel,'probe_id_master',$data->probe_id_master->data);
$babel->load_implicit_masters;

# real tests start here
load_ur($babel,'ur');
my $output_idtypes=[qw(gene_entrez gene_description)];

# do translate specially since description contains whitespace
my $name='translate';
my $translate=$data->$name->data;
my @translate=split(/\n/,$translate);
my $correct=prep_tabledata(map {[split(' ',$_,3)]} @translate);
my $actual=select_ur
  (babel=>$babel,input_idtype=>'probe_id',input_ids=>'A_51_P153683',
   output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate - select_ur');

eval {
  my $actual=$babel->translate
    (input_idtype=>'probe_id',input_ids=>'A_51_P153683',output_idtypes=>$output_idtypes);
  cmp_table($actual,$correct,'translate');
};
fail($@) if $@;

########################################
# do it again with synthetic data
cleanup_db($autodb);		# cleanup database from previous test
# make component objects and Babel. note that $masters is for EXPLICIT masters only
my $idtypes=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.idtype_syn.ini'))->objects('IdType');
my $maptables=new Data::Babel::Config
  (file=>File::Spec->catfile($confpath,scriptcode.'.maptable_syn.ini'),tt=>1)->objects('MapTable');
my $babel=new Data::Babel
  (name=>'test',idtypes=>$idtypes,maptables=>$maptables,
   pdups_group_cutoff=>0,pdups_prefixmatcher_cutoff=>0);

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

eval {
  my $actual=$babel->translate
    (input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
  cmp_table($actual,$correct,'translate syn');
};
fail($@) if $@;

########################################
# do it again with synthetic data containing all possible control characters
my @xc=map {['x1','c'.chr($_).'c']} 0..255;
load_maptable($babel,'XC',@xc);
$babel->load_implicit_masters;
load_ur($babel,'ur',@tables);
# MySQL treats some control characters as equivalent, so have to get distinct ones from db
my $xc=$dbh->selectcol_arrayref(qq(SELECT DISTINCT C from XC));
report_fail(scalar(@$xc)>100,'sanity test - enough distinct C values in database');
my $correct=[map {['a','b',$_]} @$xc];
my $actual=select_ur
  (babel=>$babel,input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
cmp_table($actual,$correct,'translate syn all characters - select_ur');

eval {
  my $actual=$babel->translate
    (input_idtype=>'A',input_ids=>'a',output_idtypes=>$output_idtypes);
  cmp_table($actual,$correct,'translate syn all characters');
};
fail($@) if $@;

done_testing();

