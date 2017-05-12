########################################
# main filter tests
########################################
use t::lib;
use t::utilBabel;
use translate;
use Test::More;
use List::Util qw(max);
use Data::Babel;
use strict;

init();

my($input_ids,$invalid_ids,$num_input_ids,$num_invalid_ids);
my $input_ids_all=$OPTIONS->input_ids_all;
for my $input (map {$_->name} @{$babel->idtypes}) {
  my($min_input_ids,$max_input_ids)=id_range('input',$input,2);
  my($min_invalid_ids,$max_invalid_ids)=id_range('invalid',$input,1);
  $num_input_ids=max($num_input_ids,$min_input_ids);
  $num_invalid_ids=max($num_invalid_ids,$min_invalid_ids);
  
  for my $outputs (@output_subsets) {
    # infeasible to iterate over all num_input_ids, so cycle through
    ($input_ids,$num_input_ids)=
      input_ids($input,$num_input_ids,$min_input_ids,$max_input_ids,$input_ids_all);
    if (defined $input_ids) {
      # add invalid ids unless we're doing input_ids=>undef
      ($invalid_ids,$num_invalid_ids)=
	invalid_ids($input,$num_invalid_ids,$min_invalid_ids,$max_invalid_ids);
      push(@$input_ids,@$invalid_ids);
    }
    my $ok=1;
    for my $filters (@filter_subsets) {
      for my $multi (0,1) {
	my $filter=make_filter($input,$input_ids,$filters,$outputs,$multi);
	$ok&&=doit($input,$input_ids,$filter,$outputs,__FILE__,__LINE__);
	if ($OPTIONS->filter_none && %$filter) {
	  # change one filter to match nothing
	  # do it via empty list, and via value that matches nothing
	  my $new_filter={}; %$new_filter=%$filter;
	  my $key=$filters->[0];
	  $new_filter->{$key}=[];
	  $ok&&=doit($input,$input_ids,$new_filter,$outputs,__FILE__,__LINE__);
	  $new_filter->{$key}=['none'];
	  $ok&&=doit($input,$input_ids,$new_filter,$outputs,__FILE__,__LINE__);
	}
	if ($OPTIONS->filter_all && %$filter) {
	  # change one filter to match everything
	  # do it via undef, and via all ids
	  my $new_filter={}; %$new_filter=%$filter;
	  my $key=$filters->[0];
	  $new_filter->{$key}=undef;
	  $ok&&=doit($input,$input_ids,$new_filter,$outputs,__FILE__,__LINE__);
	  my $ids=idtype2ids($key);
	  $new_filter->{$key}=$ids;
	  $ok&&=doit($input,$input_ids,$new_filter,$outputs,__FILE__,__LINE__);
	}
	if ($OPTIONS->filter_undef && %$filter) {
	  # add undef to every filter
	  my $new_filter={}; %$new_filter=%$filter;
	  map {push(@$_,undef)} (values %$new_filter);
	  $ok&&=doit($input,$input_ids,$new_filter,$outputs,__FILE__,__LINE__);
	}
      }
    }
    my $label=
      "input=$input num_ids=".(defined $input_ids? scalar @$input_ids: 'all').
	" outputs=@$outputs";
    report_pass($ok,$label);
  }
}
done_testing();

