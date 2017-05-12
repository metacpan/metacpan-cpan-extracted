use t::lib;
use t::utilBabel;
use Carp;
use Test::More;
use Test::Deep;

# create database to start fresh
my $autodb=new Class::AutoDB(database=>'test',create=>1);
isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');

################################################################################
# SYNOPSIS
################################################################################
use Data::Babel;
use Data::Babel::Config;
use Class::AutoDB;
use DBI;

# open database containing Babel metadata
my $autodb=new Class::AutoDB(database=>'test');
cleanup_db($autodb);		# cleanup database from previous test

# try to get existing Babel from database
my $babel=old Data::Babel(name=>'test',autodb=>$autodb);
unless ($babel) {              
  # Babel does not yet exist, so we'll create it
  # idtypes, masters, maptables are names of configuration files that define 
  #   the Babel's component objects
  $babel=new Data::Babel
    (name=>'test',idtypes=>'examples/idtype.ini',masters=>'examples/master.ini',
     maptables=>'examples/maptable.ini');
  isa_ok($babel,'Data::Babel','sanity test - $babel');
}
# open database containing real data
my $dbh=DBI->connect("dbi:mysql:database=test",undef,undef);

goto SKIP1;
  # CAUTION: rest of SYNOPSIS assumes you've loaded the real database somehow
  # translate several Entrez Gene ids to other types
my $table=$babel->translate
  (input_idtype=>'gene_entrez',
   input_ids=>[1,2,3],
   output_idtypes=>[qw(gene_symbol gene_ensembl chip_affy probe_affy)]);
# print a few columns from each row of result
for my $row (@$table) {
  print "Entrez gene=$row->[0]\tsymbol=$row->[1]\tEnsembl gene=$row->[2]\n";
}
# same translation but limit results to Affy hgu133a
my $table=$babel->translate
  (input_idtype=>'gene_entrez',
   input_ids=>[1,2,3],
   filters=>{chip_affy=>'hgu133a'},
   output_idtypes=>[qw(gene_symbol gene_ensembl chip_affy probe_affy)]);
# generate a table mapping all Entrez Gene ids to UniProt ids
my $table=$babel->translate
  (input_idtype=>'gene_entrez',
   output_idtypes=>[qw(protein_uniprot)]);
# convert to HASH for easy programmatic lookups
my %gene2uniprot=map {$_[0]=>$_[1]} @$table;
# count number of Entrez Gene ids represented on Affy hgu133a
my $count=$babel->count
  (input_idtype=>'gene_entrez',filters=>{chip_affy=>'hgu133a'});
# tell which input ids are valid
my $table=$babel->validate
  (input_idtype=>'gene_entrez',
   input_ids=>[1,2,3]);
# print validity status of each
for my $row (@$table) {
  my($input_id,$valid,$current_id)=@$row;
  print "Entrez gene $input_id is ",
    ($valid? "valid with current value $current_id": 'invalid'),"\n";
}
SKIP1:
my $name='test';
my $idtypes=File::Spec->catfile(qw(examples idtype.ini));
my $masters=File::Spec->catfile(qw(examples master.ini));
my $maptables=File::Spec->catfile(qw(examples maptable.ini));
$Template::Context::maptable_counter=0; # real crock to reset maptable counter

####################
# METHODS AND FUNCTIONS
$babel=new Data::Babel
                      name=>$name,
                      idtypes=>$idtypes,masters=>$masters,maptables=>$maptables;
ok(UNIVERSAL::isa($babel,'Data::Babel'),'new');

$babel=old Data::Babel($name);
ok(UNIVERSAL::isa($babel,'Data::Babel'),'old: positional form');
$babel=old Data::Babel(name=>$name);
ok(UNIVERSAL::isa($babel,'Data::Babel'),'old: keyword form');

my $ok=cmp_attrs($babel,
		 {name=>'test',id=>'babel:test',autodb=>$autodb},
		 'simple and class attributes');
report($ok,'Data::Babel simple and class attributes in METHODS AND FUNCTIONS',__FILE__,__LINE__);

my $ok=1;
$ok&&=report_fail(ref $babel->idtypes eq 'ARRAY',
		  'Data::Babel idtypes attribute in METHODS AND FUNCTIONS',__FILE__,__LINE__);
$ok&&=report_fail(ref $babel->masters eq 'ARRAY',
		  'Data::Babel masters attribute in METHODS AND FUNCTIONS',__FILE__,__LINE__);
$ok&&=report_fail(ref $babel->maptables eq 'ARRAY',
		  'Data::Babel maptables attribute in METHODS AND FUNCTIONS',__FILE__,__LINE__);
report_pass($ok,
	    'Data::Babel component-object attribute in METHODS AND FUNCTIONS',__FILE__,__LINE__);

# CAUTION: translate assumes you've loaded the real database somehow
goto SKIP_translate;
my $table;
$table=$babel->translate
  (input_idtype=>'gene_entrez',
   input_ids=>[1,2,3],
   filters=>{chip_affy=>'hgu133a'},
   output_idtypes=>[qw(transcript_refseq transcript_ensembl)],
   limit=>100);

  # If a filter value is undef, ...
$babel->translate(input_idtype=>'gene_entrez',
		  filters=>{pathway_kegg_id=>undef},
		  output_idtypes=>[qw(gene_symbol)]);
$babel->translate(input_idtype=>'gene_entrez',
		  filters=>{pathway_kegg_id=>[undef,4610]},
		  output_idtypes=>[qw(gene_symbol)]);
SKIP_translate:
my @filters=
  (filters=>{chip_affy=>'hgu133a'},
   filters=>{chip_affy=>['hgu133a','hgu133plus2']},
   filters=>{chip_affy=>['hgu133a','hgu133plus2'],pathway_kegg_id=>4610},
   filters=>[chip_affy=>'hgu133a',chip_affy=>'hgu133plus2'],
   filters=>{chip_affy=>['hgu133a','hgu133plus2']},
   filters=>{chip_affy=>['hgu133a','hgu133plus2'],pathway_kegg_id=>undef},
   filters=>{chip_affy=>'hgu133a',pathway_kegg_id=>[undef,4610]},
  );
pass('translate in METHODS AND FUNCTIONS');

# CAUTION: count assumes you've loaded the real database somehow
goto SKIP_count;
my $number;
$number=$babel->count
  (input_idtype=>'gene_entrez',
   input_ids=>[1,2,3],
   filters=>{chip_affy=>'hgu133a'},
   output_idtypes=>[qw(transcript_refseq transcript_ensembl)]);
SKIP_count:
pass('count in METHODS AND FUNCTIONS');

# CAUTION: validate assumes you've loaded the real database somehow
goto SKIP_validate;
my $table;
$table=$babel->validate
  (input_idtype=>'gene_entrez',
   input_ids=>[1,2,3]);
SKIP_validate:
pass('validate in METHODS AND FUNCTIONS');

# show: just make sure it prints something..
# redirect STDOUT to a string. adapted from perlfunc
my $showout;
open my $oldout,">&STDOUT" or fail("show: can't dup STDOUT: $!");
close STDOUT;
open STDOUT, '>',\$showout or fail("show: can't redirect STDOUT to string: $!");
$babel->show;
close STDOUT;
open STDOUT,">&",$oldout or fail("show: can't restore STDOUT: $!");
ok(length($showout)>500,'show in METHODS AND FUNCTIONS');

@errstrs=$babel->check_schema;
ok(!@errstrs,'check_schema array context in METHODS AND FUNCTIONS');
$ok=$babel->check_schema;
ok($ok,'check_schema scalar context in METHODS AND FUNCTIONS');
# CAUTION: check_contents assumes you've loaded the real database somehow
goto SKIP_check_contents;
@errstrs=$babel->check_contents;
$ok=$babel->check_contents;
SKIP_check_contents:
pass('check_contents in METHODS AND FUNCTIONS');

goto SKIP_load_implicit_masters;
$babel->load_implicit_masters;
SKIP_load_implicit_masters:
pass('load_implicit_masters in METHODS AND FUNCTIONS');

my($idtype,$master,$maptable,$object,$name);
$idtype=$babel->name2idtype('gene_entrez');
ok(UNIVERSAL::isa($idtype,'Data::Babel::IdType'),'name2idtype in METHODS AND FUNCTIONS');
$master=$babel->name2master('gene_entrez_master');
ok(UNIVERSAL::isa($master,'Data::Babel::Master'),'name2master in METHODS AND FUNCTIONS');
$maptable=$babel->name2maptable('maptable_012');
ok(UNIVERSAL::isa($maptable,'Data::Babel::MapTable'),'name2maptable in METHODS AND FUNCTIONS');
$object=$babel->id2object('idtype:gene_entrez');
ok(UNIVERSAL::isa($object,'Data::Babel::IdType'),'id2object in METHODS AND FUNCTIONS');

$name=$babel->id2name('idtype:gene_entrez');
is($name,'gene_entrez','id2name as object method in METHODS AND FUNCTIONS');
$name=Data::Babel->id2name('idtype:gene_entrez');
is($name,'gene_entrez','id2name as class method in METHODS AND FUNCTIONS');

done_testing();

