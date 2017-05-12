########################################
# translate_hand.010.main -- main tests 
########################################
use t::lib;
use t::utilBabel;
use translate_hand;
use List::Util qw(min);
use Test::More;
use Data::Babel;
use strict;

init();

# Also test with duplicate outputs
# Note that for some cases, outputs will contain input
# For each case, test range of input ids, input_ids=>undef
#                test w/o limit and with limits if set
#                test w/ count or validate 0r keep_pdups if options set
#                test w/ duplicate outputs
my($input_ids,$invalid_ids,$num_input_ids,$num_invalid_ids);
for my $input_idtype (@idtypes) {
  my $input=$input_idtype->name;
  my($min_input_ids,$max_input_ids)=num_range('input',$input,2);
  my($min_invalid_ids,$max_invalid_ids)=num_range('invalid',$input,1);  
  my($min_limit,$max_limit)=num_range('limit',$input,undef);  
  for my $outputs (@output_subsets) {
    my $ok=1;
    for my $num_input_ids ($min_input_ids..$max_input_ids) {
      my @input_ids=idtype2ids($input,$num_input_ids);
      for my $num_invalid_ids ($min_invalid_ids..$max_invalid_ids) {
	my @invalid_ids=make_invalid_ids($input,$num_invalid_ids);
	my $input_ids=[@input_ids,@invalid_ids];
	my $ok1=doit($input,$input_ids,$outputs); $ok&&=$ok1;
     }}
    # do it it with all input ids
    my $ok1=doit($input,undef,$outputs); $ok&&=$ok1;
    report_pass($ok,"input_idtype=$input, output_idtypes=@$outputs");
  }}
done_testing();

sub doit {
  my($input,$input_ids,$outputs)=@_;
  my $ok=1;
  my @args=(input_idtype=>$input,input_ids=>$input_ids,output_idtypes=>$outputs);
  push(@args,count=>1) if $OPTIONS->count;
  push(@args,validate=>1) if $OPTIONS->validate;
  push(@args,keep_pdups=>1) if $OPTIONS->keep_pdups;
  my $op=$OPTIONS->count? 'count': 'translate'; # for cmp_op
  my $limit=$OPTIONS->limit;
  my($min_limit,$max_limit)=@$limit if defined $limit;
  for my $dup (0,1) {
    $outputs=[@$outputs,@$outputs] if $dup;
    my $correct=select_ur(babel=>$babel,@args);
    my $actual=$babel->translate(@args);
    my $label="input_idtype=$input, input_ids=".(defined $input_ids? @$input_ids: 'undef').
      "output_idtypes=@$outputs";
    $ok&&=cmp_op_quietly($actual,$correct,$op,$label,__FILE__,__LINE__) or return 0;
    # test with limits if option set
    if (defined $limit) {
      for my $limit ($min_limit..$max_limit) {
	my $actual=$babel->translate(@args,limit=>$limit);  
	$ok&&=cmp_op_quietly($actual,$correct,$op,"$label, limit=$limit",__FILE__,__LINE__,$limit)
	  or return 0;
      }}}
  $ok;
}
