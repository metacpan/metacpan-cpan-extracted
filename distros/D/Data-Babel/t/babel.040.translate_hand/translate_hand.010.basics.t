########################################
# test everything by hand
########################################
use t::lib;
use t::utilBabel;
use translate_hand;
use Test::More;
use Data::Babel;
use strict;

init();
my $what=$OPTIONS->what;
my @idtypes=@{$OPTIONS->idtypes};

# test ur selection
my @output_idtypes=@idtypes[0,$#idtypes];
my $correct=prep_tabledata($data->ur_selection->data);
my $actual=select_ur_sanity(babel=>$babel,urname=>'ur',output_idtypes=>\@output_idtypes);
cmp_table($actual,$correct,'ur selection');

# for pdups_multi, outputs should not include 'type_multi'
@idtypes=grep !/multi/,@idtypes;

# basic translate
my $input_idtype='type_001';
my @input_ids=make_ids($input_idtype,qw(000 001 111));
my @output_idtypes=grep {$_ ne $input_idtype} @idtypes;
my @args=(input_idtype=>$input_idtype,input_ids=>\@input_ids, output_idtypes=>\@output_idtypes);
doit('basics',@args);

# validate
my $input_idtype='type_001';
my @input_ids=(make_invalid_ids($input_idtype),make_ids($input_idtype,qw(000 001 011 110 111)));
my @args=(input_idtype=>$input_idtype,input_ids=>\@input_ids,validate=>1,
	  output_idtypes=>['type_003']);
doit('basics_validate',@args);

# basic filter test
my $input_idtype='type_001';
my @input_ids=(make_invalid_ids($input_idtype),make_ids($input_idtype,qw(000 001 011 110 111)));
my @output_idtypes=grep {$_ ne $input_idtype} @idtypes;
my $filter_idtype=$idtypes[$#idtypes];
my($filter_id)=$filter_idtype=~/multi/? 'multi_002': make_ids($filter_idtype,qw(111));
my @args=(input_idtype=>$input_idtype,input_ids=>\@input_ids,
	  filters=>{$filter_idtype=>$filter_id},output_idtypes=>\@output_idtypes);
doit('basics_filter',@args);

# filter tests from filter_main.
my $input_idtype='type_001';
my @output_idtypes=grep {$_ ne $input_idtype} @idtypes;
my $filter_idtype=$idtypes[2];
# filter all ids
my @filter_ids=idtype2ids($filter_idtype);
my @args=(input_idtype=>$input_idtype,filters=>{$filter_idtype=>\@filter_ids},
	  output_idtypes=>\@output_idtypes);
doit('filter_all',@args);
# filter one id
my($filter_id)=make_ids($filter_idtype,'111');
my @args=(input_idtype=>$input_idtype,filters=>{$filter_idtype=>$filter_id},
	  output_idtypes=>\@output_idtypes);
doit('filter_one',@args);
# filter one id + undef
my @filter_ids=(undef,make_ids($filter_idtype,'111'));
my @args=(input_idtype=>$input_idtype,filters=>{$filter_idtype=>\@filter_ids},
	  output_idtypes=>\@output_idtypes);
doit('filter_one_undef',@args);

# translate all
my $input_idtype='type_001';
my @output_idtypes=grep {$_ ne $input_idtype} @idtypes;
my @args=(input_idtype=>$input_idtype,input_ids_all=>1,output_idtypes=>\@output_idtypes);
doit('basics_all',@args);

# select one id for each input idtype
for my $input_idtype (@idtypes) {
  my($input_id)=$input_idtype=~/multi/? 'multi_002': make_ids($input_idtype,qw(111));
  my @args=(input_idtype=>$input_idtype,input_ids=>$input_id,output_idtypes=>\@idtypes);
  doit_oneid($input_idtype,@args);
}

done_testing();

# test one case: select_ur & translate. case is section in data file
sub doit {
  my($case,@args)=@_;
  my $correct=prep_tabledata($data->$case->data);
  my $actual=select_ur(babel=>$babel,@args);
  cmp_table($actual,$correct,"select_ur $case");
  my $actual=$babel->translate(@args);
  cmp_table($actual,$correct,"translate $case");
}
# test one input id: select_ur & translate. input_idtype is section in data file
sub doit_oneid {
  my($input_idtype,@args)=@_;
  my $correct=prep_tabledata($data->$input_idtype->data);
  my $actual=select_ur(babel=>$babel,@args);
  cmp_table($actual,$correct,"select_ur $input_idtype one id");
  my $actual=$babel->translate(@args);
  cmp_table($actual,$correct,"translate $input_idtype one id");
}

