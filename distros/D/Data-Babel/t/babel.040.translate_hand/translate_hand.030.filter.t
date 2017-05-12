########################################
# main filter tests 
########################################
use t::lib;
use t::utilBabel;
use translate_hand;
use Test::More;
use Data::Babel;
use strict;

init();

# For each case, test input_ids=>undef
#                test w/ count or validate or keep_pdups if options set
# note that for some cases, outputs will contain input
for my $input_idtype (@idtypes) {
  my $input=$input_idtype->name;
  my($min_limit,$max_limit)=num_range('limit',$input,undef);  
  for my $outputs (@output_subsets) {
    my $ok=1;
    for my $filters (@filter_subsets) {
      my $ok1=doit($input,$filters,$outputs); $ok&&=$ok1;
      report_pass($ok,"input_idtype=$input, filter_idtypes=@$filters, output_idtypes=@$outputs");
    }}}
done_testing();

sub doit {
  my($input,$filters,$outputs)=@_;
  my $ok=1;
  my @args_base=(input_idtype=>$input,output_idtypes=>$outputs);
  push(@args_base,count=>1) if $OPTIONS->count;
  push(@args_base,validate=>1) if $OPTIONS->validate;
  push(@args_base,keep_pdups=>1) if $OPTIONS->keep_pdups;
  my $op=$OPTIONS->count? 'count': 'translate'; # for cmp_op
  my $limit=$OPTIONS->limit;
  my($min_limit,$max_limit)=@$limit if defined $limit;
  my $label="input_idtype=$input, filter_idtypes=@$filters, output_idtypes=@$outputs";
  my @filters=make_filters($filters); # make series of filter hashes
  for my $filters (@filters) {
    my @args=(@args_base,filters=>$filters);
    my $correct=select_ur(babel=>$babel,@args);
    my $actual=$babel->translate(@args);
    $ok&&=cmp_op_quietly($actual,$correct,$op,$label,__FILE__,__LINE__) or return 0;
  }
  $ok;
}

# make series of filters hashes
sub make_filters {
  my($filters)=@_;
  my @filters;
  if (@$filters) {
    # all ids
    my %filters=map {$_=>[idtype2ids($_)]} @$filters;
    push(@filters,\%filters);
    # all ids w/ one filter=>undef
    my %filters=($filters->[0]=>undef,map {$_=>[idtype2ids($_)]} @$filters[1..$#$filters]);
    $filters{$filters->[0]}=undef;
    push(@filters,\%filters);
    # one id that should match cross the board
    my %filters=map {$_=>make_ids($_,'111')} @$filters;
    push(@filters,\%filters);
    # add undef to each filter
    my %filters=map {$_=>[undef,make_ids($_,'111')]} @$filters;
    push(@filters,\%filters);
  }
  @filters;
}

