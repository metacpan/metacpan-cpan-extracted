########################################
# 014.filter -- test all forms of translate filter arg
########################################
use t::lib;
use t::utilBabel;
use Carp;
use File::Spec;
use Getopt::Long;
use List::MoreUtils qw(all);
# use Test::Deep;
use Test::More;
use Text::Abbrev;
use Data::Babel;
use Data::Babel::Filter;
use strict;

our %OPTIONS;
GetOptions (\%OPTIONS,qw(bundle:s));
our %bundle=abbrev qw(install develop);
$OPTIONS{bundle}='install' unless defined $OPTIONS{bundle};
my $bundle=$bundle{$OPTIONS{bundle}} || confess "Invalid bundle option $OPTIONS{bundle}";
$OPTIONS{$OPTIONS{bundle}}=1;

our($babel,$history,@all_input_ids,@all_filter_ids,@all_other_ids,
    @std_filter_ids,@std_other_ids,
    @std_filter_likes,@std_other_likes,
    @like0_filter_ids,@like1_filter_ids,@like2_filter_ids,
    @likea_filter_ids,@likeb_filter_ids,@likec_filter_ids,@likex_filter_ids,@likey_filter_ids,
   );

# script assumes a very specific database design. although $num_idtypes and $num_ids
#   are variables, DO NOT change them without careful consideration!!
# chain schema with binary maptables
# database has 'a' values that are 1:1, 'b' values 1:1 and connected to NULLs
#   histories have 'x' values 1;1 with 'a' values, 'y' values that are retired
# idtypes are type_0,...,type_6
# type_0 always input_idtype, type_2 filter_idtype, type_4 output_idtype
#   also test other outut_idtypes in passing
#   some queries touch type_6 via embedded explicit idtype
# test histories on type_0, type_2, type_6
# test regular translate, validate, count
# standard tests retrieve 2 or 3 rows depending on history: 'a_0', 'b_1', 'a_2' (w/ history)

# CAUTION: do NOT change these parameters without careful consideration!
my $num_idtypes=7;		
my $num_maptables=$num_idtypes-1;
my $num_ids=3;
my $input_idtype='type_0';
my $filter_idtype='type_2';
my $output_idtype='type_4';
my $other_idtype='type_6';                # for testing embedded explicit idtypes
my($filter_idtype_obj,$other_idtype_obj); # for testing objects as filter keys 
my @even_idtypes=map {"type_$_"} grep {!($_%2)} 0..$num_idtypes-1;
my @odd_idtypes=map {"type_$_"} grep {$_%2} 0..$num_idtypes-1;
my @all_idtypes=map {"type_$_"} 0..$num_idtypes-1;

my @histories=$OPTIONS{install}? ([],[0,2,6]):  ([],[0],[2],[6],[0,2],[0,2,6]);

for $history (@histories) {
  init() or next;
  doit();
}
done_testing();

sub doit {
  # various ways of saying 'no filters'
  my $label='empty';
  my $correct_filters=undef;
  doit_block
    ($label,$correct_filters,
     'undef'=>undef,string=>'','string ref'=>\'',HASH=>{},ARRAY=>[]
    );

  # single conditions: scalar or scalar ref vs. ARRAY
  my $label='single conditions';
  my $correct_filters=["$filter_idtype/a_2"];
  doit_block
    ($label,$correct_filters,
     'HASH of value (scalar)'=>{$filter_idtype=>"$filter_idtype/a_2"},
     'HASH of value (ARRAY)'=>{$filter_idtype=>["$filter_idtype/a_2"]},
     'HASH of sql (scalar ref)'=>{$filter_idtype=>\ qq(= "$filter_idtype/a_2")},
     'HASH of sql (ARRAY)'=>{$filter_idtype=>[\ qq(= "$filter_idtype/a_2")]},
     'ARRAY of value (scalar)'=>[$filter_idtype=>"$filter_idtype/a_2"],
     'ARRAY of value (ARRAY)'=>[$filter_idtype=>["$filter_idtype/a_2"]],
     'ARRAY of sql (scalar ref)'=>[$filter_idtype=>\ qq(= "$filter_idtype/a_2")],
     'ARRAY of sql (ARRAY)'=>[$filter_idtype=>[\ qq(= "$filter_idtype/a_2")]],
    );

  # various ways of saying 'filters have no effect'
  my $label='get all';
  doit_block
    ($label,
     {string=>qq($filter_idtype LIKE '$filter_idtype%'),
      'string ref'=>qq($filter_idtype LIKE '$filter_idtype%'),
      'HASH of values'=>\@all_filter_ids,
      'HASH of sqls'=>qq($filter_idtype LIKE '$filter_idtype%'),
      'HASH of values & sqls'=>qq($other_idtype LIKE '$other_idtype%'),
      'ARRAY of values'=>\@all_filter_ids,
      'ARRAY of sqls'=>qq($filter_idtype LIKE '$filter_idtype%'),
      'ARRAY of values & sqls'=>,qq($other_idtype LIKE '$other_idtype%'),
     },
     string=>qq(:$filter_idtype LIKE '$filter_idtype%'),
     'string ref'=>\ qq(:$filter_idtype LIKE '$filter_idtype%'),
     'HASH of values'=>{$filter_idtype=>\@all_filter_ids},
     'HASH of sqls'=>{$filter_idtype=>\ qq(LIKE '$filter_idtype%')},
     'HASH of values & sqls'=>{$filter_idtype=>\@all_filter_ids,
			       $other_idtype=>\ qq(LIKE '$other_idtype%')},
     'ARRAY of values'=>[$filter_idtype=>\@all_filter_ids],
     'ARRAY of sqls'=>[$filter_idtype=>\ qq(LIKE '$filter_idtype%')],
     'ARRAY of values & sqls'=>[$filter_idtype=>\@all_filter_ids,
				$other_idtype=>\ qq(LIKE '$other_idtype%')],
    );

  # filters w/ undefs
  my $label='undef (NOT NULL)';
  my $correct_filters=qq($filter_idtype IS NOT NULL);
  doit_block
    ($label,$correct_filters,
     'HASH'=>{$filter_idtype=>undef},
     'HASH of sqls'=>{$filter_idtype=>\ qq(IS NOT NULL)},
     'ARRAY'=>[$filter_idtype=>undef],
     'ARRAY of sqls'=>[$filter_idtype=>\ qq(IS NOT NULL)],
    );
  my $label='undef (NULL)';
  my $correct_filters=[undef];
  doit_block
    ($label,$correct_filters,
     'HASH'=>{$filter_idtype=>[undef]},
     'HASH of sqls'=>{$filter_idtype=>\ qq(IS NULL)},
     'ARRAY'=>[$filter_idtype=>[undef]],
     'ARRAY of sqls'=>[$filter_idtype=>\ qq(IS NULL)],
    );
  my $label='undef & values';
  my $correct_filters=[undef,@std_filter_ids];
  doit_block
    ($label,$correct_filters,
     'HASH of values'=>{$filter_idtype=>[undef,@std_filter_ids]},
     'HASH of sqls'=>
     {$filter_idtype=>\ qq(IS NULL OR 
                           : LIKE $std_filter_likes[0] OR 
                           : LIKE $std_filter_likes[1] OR 
                           : LIKE $std_filter_likes[2])},
     'HASH of values & sqls'=>
     {$filter_idtype=>[undef,@std_filter_ids[0,1],
		       \ qq(LIKE $std_filter_likes[1]),
		       \ qq(LIKE $std_filter_likes[2])]},
      'ARRAY of values'=>[$filter_idtype=>[undef,@std_filter_ids]],
      'ARRAY of sqls'=>[$filter_idtype=>\ qq(IS NULL OR 
                           : LIKE $std_filter_likes[0] OR 
                           : LIKE $std_filter_likes[1] OR 
                           : LIKE $std_filter_likes[2])],
      'ARRAY of values & sqls'=>
      [$filter_idtype=>[undef,@std_filter_ids[0,1],
			\ qq(LIKE $std_filter_likes[1]),
			\ qq(LIKE $std_filter_likes[2])]],
     'repeated ARRAY'=>[$filter_idtype=>[undef],
			$filter_idtype=>[@std_filter_ids[0,1]],
			$filter_idtype=>\ qq(LIKE $std_filter_likes[1]),
			$filter_idtype=>[\ qq(LIKE $std_filter_likes[2])]],
    );

 # string and string ref general. also special case of empty key
  my $label='naked sql';
  my $correct_filters=\@std_filter_ids;
  doit_block
    ($label,$correct_filters,
     'string'=>qq(:$filter_idtype LIKE $std_filter_likes[0] OR 
                  :$other_idtype LIKE $std_other_likes[1] OR 
                  :$filter_idtype LIKE $std_filter_likes[2]),
     'string ref'=>\ qq(:$filter_idtype LIKE $std_filter_likes[0] OR 
                        :$other_idtype LIKE $std_other_likes[1] OR 
                        :$filter_idtype LIKE $std_filter_likes[2]),
     'empty key (HASH)'=>{''=>
			  \ qq(:$filter_idtype LIKE $std_filter_likes[0] OR 
                               :$other_idtype LIKE $std_other_likes[1] OR 
                               :$filter_idtype LIKE $std_filter_likes[2])},
     'empty key (ARRAY)'=>[''=>
			  \ qq(:$filter_idtype LIKE $std_filter_likes[0] OR 
                               :$other_idtype LIKE $std_other_likes[1] OR 
                               :$filter_idtype LIKE $std_filter_likes[2])],
    );
 
  # HASH 1 filter
  my $label='HASH 1 filter';
  my $correct_filters=\@std_filter_ids;
  doit_block
    ($label,
     {''=>$correct_filters,
      'other_type only'=>["$filter_idtype/a_0"],
     },
     'values'=>{$filter_idtype=>\@std_filter_ids},
     'sql not embedded'=>
     {$filter_idtype=>[\ qq(LIKE $std_filter_likes[0]),
		       \ qq(LIKE $std_filter_likes[1]),
                       \ qq(LIKE $std_filter_likes[2])]},
     'sql embedded default front'=>
     {$filter_idtype=>[\ qq(: LIKE $std_filter_likes[0]),
		       \ qq(: LIKE $std_filter_likes[1]),
                       \ qq(: LIKE $std_filter_likes[2])]},
     'sql embedded default middle'=>
     {$filter_idtype=>[\ qq(LIKE $std_filter_likes[0] OR 
                           : LIKE $std_filter_likes[1]),
                       \ qq(LIKE $std_filter_likes[2])]},
     'sql embedded default front & middle'=>
     {$filter_idtype=>[\ qq(: LIKE $std_filter_likes[0]),
                       \ qq(: LIKE $std_filter_likes[1] OR 
		            : LIKE $std_filter_likes[2])]},
     'sql embedded explicit'=>
     {$filter_idtype=>\ qq(:$filter_idtype LIKE $std_filter_likes[0] OR 
                           :$other_idtype LIKE $std_other_likes[1] OR 
                           :$filter_idtype LIKE $std_filter_likes[2])},
     'sql embedded default & explicit'=>
     {$filter_idtype=>\ qq(LIKE $std_filter_likes[0] OR 
                           :$other_idtype LIKE $std_other_likes[1] OR 
                           : LIKE $std_filter_likes[2])},
     'other_type only'=>
     {$filter_idtype=>\ qq(:$other_idtype = '$other_idtype/a_0')},
     );

# ARRAY 1 filter
  my $label='ARRAY 1 filter';
  my $correct_filters=\@std_filter_ids;
  doit_block
    ($label,
     {''=>$correct_filters,
      'other_type only'=>["$filter_idtype/a_0"],
     },
     'values'=>[$filter_idtype=>\@std_filter_ids],
     'sql not embedded'=>
     [$filter_idtype=>[\ qq(LIKE $std_filter_likes[0]),
		       \ qq(LIKE $std_filter_likes[1]),
                       \ qq(LIKE $std_filter_likes[2])]],
     'sql embedded default front'=>
     [$filter_idtype=>[\ qq(: LIKE $std_filter_likes[0]),
		       \ qq(: LIKE $std_filter_likes[1]),
                       \ qq(: LIKE $std_filter_likes[2])]],
     'sql embedded default middle'=>
     [$filter_idtype=>[\ qq(LIKE $std_filter_likes[0] OR 
                           : LIKE $std_filter_likes[1]),
                       \ qq(LIKE $std_filter_likes[2])]],
     'sql embedded default front & middle'=>
     [$filter_idtype=>[\ qq(: LIKE $std_filter_likes[0]),
                       \ qq(: LIKE $std_filter_likes[1] OR 
		            : LIKE $std_filter_likes[2])]],
     'sql embedded explicit'=>
     [$filter_idtype=>\ qq(:$filter_idtype LIKE $std_filter_likes[0] OR 
                           :$other_idtype LIKE $std_other_likes[1] OR 
                           :$filter_idtype LIKE $std_filter_likes[2])],
     'sql embedded default & explicit'=>
     [$filter_idtype=>\ qq(LIKE $std_filter_likes[0] OR 
                           :$other_idtype LIKE $std_other_likes[1] OR 
                           : LIKE $std_filter_likes[2])],
     'other_type only'=>
     [$filter_idtype=>\ qq(:$other_idtype = '$other_idtype/a_0')],
     );

  # ARRAY repeated filter
  my $label='ARRAY repeated filter';
  my $correct_filters=\@std_filter_ids;
  doit_block
    ($label,
     {''=>$correct_filters,
      'other_type only'=>["$filter_idtype/a_0","$filter_idtype/b_1"],
     },
     'values'=>[$filter_idtype=>$std_filter_ids[0],
		$filter_idtype=>$std_filter_ids[1],
		$filter_idtype=>$std_filter_ids[2]],
       'sql not embedded'=>
     [$filter_idtype=>[\ qq(LIKE $std_filter_likes[0]),
		       \ qq(LIKE $std_filter_likes[1])],
      $filter_idtype=>\ qq(LIKE $std_filter_likes[2])],
     'sql embedded default front'=>
     [$filter_idtype=>\ qq(: LIKE $std_filter_likes[0]),
      $filter_idtype=>\ qq(: LIKE $std_filter_likes[1]),
      $filter_idtype=>\ qq(: LIKE $std_filter_likes[2])],
     'sql embedded default middle'=>
     [$filter_idtype=>\ qq(LIKE $std_filter_likes[0] OR 
                           : LIKE $std_filter_likes[1]),
      $filter_idtype=>[\ qq(LIKE $std_filter_likes[2])]],
     'sql embedded default front & middle'=>
     [$filter_idtype=>[\ qq(: LIKE $std_filter_likes[0])],
      $filter_idtype=>[\ qq(: LIKE $std_filter_likes[1] OR 
		            : LIKE $std_filter_likes[2])]],
     'sql embedded explicit'=>
     [$filter_idtype=>[\ qq(:$filter_idtype LIKE $std_filter_likes[0])], 
      $filter_idtype=>[\ qq(:$other_idtype LIKE $std_other_likes[1])],
      $filter_idtype=>[\ qq(:$filter_idtype LIKE $std_filter_likes[2])]],
     'sql embedded default & explicit'=>
     [$filter_idtype=>\ qq(LIKE $std_filter_likes[0] OR 
                           :$other_idtype LIKE $std_other_likes[1]),
      $filter_idtype=>\ qq(: LIKE $std_filter_likes[2])],
     'other_type only'=>
     [$filter_idtype=>\ qq(:$other_idtype = '$other_idtype/a_0'),
      $filter_idtype=>\ qq(:$other_idtype LIKE $std_other_likes[1])],
    );

  # HASH 2 filters
  my $label='HASH 2 filters';
  my $correct_filters=[@std_filter_ids,"$filter_idtype/a_2"];
  doit_block
    ($label,$correct_filters,
     'values'=>{$filter_idtype=>[@std_filter_ids,@like2_filter_ids],
		$other_idtype=>[@std_other_ids,"$other_idtype/a_2"]},
      'sqls'=>{$filter_idtype=>\ qq(: LIKE $std_filter_likes[0] OR 
                                    : LIKE $std_filter_likes[1] OR 
                                    : LIKE $std_filter_likes[2] OR
                                    : LIKE '%2'),
	       $other_idtype=>\ qq(: LIKE $std_other_likes[0] OR 
                                    : LIKE $std_other_likes[1] OR 
                                    : LIKE $std_other_likes[2] OR
                                    : = '$other_idtype/a_2')},
     'values & sqls'=>{$filter_idtype=>[\ qq(: LIKE $std_filter_likes[0] OR 
                                             : LIKE $std_filter_likes[1] OR 
                                             : LIKE $std_filter_likes[2]),
					@like2_filter_ids],
		       $other_idtype=>[\ qq(: LIKE $std_other_likes[0] OR 
                                           : LIKE $std_other_likes[1] OR 
                                           : LIKE $std_other_likes[2]),
				       "$other_idtype/a_2"]},
    );

  # ARRAY 2 filters
  my $label='ARRAY 2 filters';
  my $correct_filters=[@std_filter_ids,"$filter_idtype/a_2"];
  doit_block
    ($label,$correct_filters,
     'values'=>[$filter_idtype=>[@std_filter_ids,@like2_filter_ids],
		$other_idtype=>[@std_other_ids,"$other_idtype/a_2"]],
      'sqls'=>[$filter_idtype=>\ qq(: LIKE $std_filter_likes[0] OR 
                                    : LIKE $std_filter_likes[1] OR 
                                    : LIKE $std_filter_likes[2] OR
                                    : LIKE '%2'),
	       $other_idtype=>\ qq(: LIKE $std_other_likes[0] OR 
                                    : LIKE $std_other_likes[1] OR 
                                    : LIKE $std_other_likes[2] OR
                                    : = '$other_idtype/a_2')],
     'values & sqls'=>[$filter_idtype=>[\ qq(: LIKE $std_filter_likes[0] OR 
                                             : LIKE $std_filter_likes[1] OR 
                                             : LIKE $std_filter_likes[2]),
					@like2_filter_ids],
		       $other_idtype=>[\ qq(: LIKE $std_other_likes[0] OR 
                                           : LIKE $std_other_likes[1] OR 
                                           : LIKE $std_other_likes[2]),
				       "$other_idtype/a_2"]],
    );

  # ARRAY repeated 2 filters
  my $label='ARRAY repeated 2 filters';
  my $correct_filters=[@std_filter_ids,"$filter_idtype/a_2"];
  doit_block
    ($label,$correct_filters,
     'values'=>[$filter_idtype=>\@std_filter_ids,
		$filter_idtype=>\@like2_filter_ids,
		$other_idtype=>\@std_other_ids,
		$other_idtype=>"$other_idtype/a_2"],
      'sqls'=>[$filter_idtype=>\ qq(: LIKE $std_filter_likes[0]), 
               $filter_idtype=>\ qq(: LIKE $std_filter_likes[1]), 
	       $filter_idtype=>\ qq(: LIKE $std_filter_likes[2]),
	       $filter_idtype=>\ qq(: LIKE '%2'),
	       $other_idtype=>\ qq(: LIKE $std_other_likes[0]), 
               $other_idtype=>\ qq(: LIKE $std_other_likes[1]), 
	       $other_idtype=>\ qq(: LIKE $std_other_likes[2]),
               $other_idtype=>\ qq( : = '$other_idtype/a_2')],
     'values & sqls'=>[$filter_idtype=>\ qq(: LIKE $std_filter_likes[0]), 
                       $filter_idtype=>\ qq(: LIKE $std_filter_likes[1]), 
                       $filter_idtype=>\ qq(: LIKE $std_filter_likes[2]),
		       $filter_idtype=>\@like2_filter_ids,
		       $other_idtype=>\ qq(: LIKE $std_other_likes[0]), 
                       $other_idtype=>\ qq(: LIKE $std_other_likes[1]), 
		       $other_idtype=>\ qq(: LIKE $std_other_likes[2]),
		       $other_idtype=>"$other_idtype/a_2"],
    );

  # Filter objects
  my $label='Filter object';
  my $std_obj=new Data::Babel::Filter 
    babel=>$babel,filter_idtype=>$filter_idtype,
      conditions=>\ qq(: LIKE $std_filter_likes[0] OR
                       : LIKE $std_filter_likes[1] OR
                       : LIKE $std_filter_likes[2]);
  my $obj0=new Data::Babel::Filter 
    babel=>$babel,filter_idtype=>$filter_idtype,conditions=>\ qq(: LIKE $std_filter_likes[0]);
  my $obj1=new Data::Babel::Filter 
    babel=>$babel,filter_idtype=>$filter_idtype,conditions=>\ qq(: LIKE $std_filter_likes[1]);
  my $obj2=new Data::Babel::Filter 
    babel=>$babel,filter_idtype=>$filter_idtype,conditions=>\ qq(: LIKE $std_filter_likes[2]);
  my $correct_filters=\@std_filter_ids;
  doit_block
     ($label,$correct_filters,
      'standalone'=>$std_obj,
      'empty key'=>{''=>$std_obj},
      'ARRAY of objects'=>{$filter_idtype=>[$obj0,$obj1,$obj2]},
      'ARRAY of values & objects'=>{$filter_idtype=>
				    [@std_filter_ids[0,1],$obj1,$obj2]},
     );

  # IdType objects
  my $label='IdType object as key';
  my $correct_filters=[@std_filter_ids,"$filter_idtype/a_2"];
  doit_block
     ($label,$correct_filters,
      'HASH'=>{$filter_idtype_obj=>[@std_filter_ids,"$filter_idtype/a_2"]},
      'ARRAY'=>[$filter_idtype_obj=>[@std_filter_ids,"$filter_idtype/a_2"]],
      'HASH repeated'=>
      {$filter_idtype_obj=>[@std_filter_ids[0,1]],
       $filter_idtype=>[@std_filter_ids[1,2],"$filter_idtype/a_2"]},
      'ARRAY repeated'=>
      [$filter_idtype_obj=>[@std_filter_ids[0,1]],$filter_idtype=>[@std_filter_ids[1,2]],
       $filter_idtype_obj=>"$filter_idtype/a_2"],
       'HASH repeated 2 filters'=>
       {$filter_idtype_obj=>\ qq(: LIKE $std_filter_likes[0] OR 
                                 : LIKE $std_filter_likes[1] OR
                                 : LIKE $std_filter_likes[2]),
	$filter_idtype=>\@like2_filter_ids,
	$other_idtype_obj=>\ qq(: LIKE $std_other_likes[0] OR
                                : LIKE $std_other_likes[1] OR
		                : LIKE $std_other_likes[2]),
	$other_idtype=>"$other_idtype/a_2"},
       'ARRAY repeated 2 filters'=>
       [$filter_idtype_obj=>\ qq(: LIKE $std_filter_likes[0]), 
	$filter_idtype=>\ qq(: LIKE $std_filter_likes[1]), 
	$filter_idtype_obj=>\ qq(: LIKE $std_filter_likes[2]),
	$filter_idtype=>\@like2_filter_ids,
	$other_idtype_obj=>\ qq(: LIKE $std_other_likes[0]), 
	$other_idtype=>\ qq(: LIKE $std_other_likes[1]), 
	$other_idtype=>\ qq(: LIKE $std_other_likes[2]),
	$other_idtype_obj=>"$other_idtype/a_2"]
     );
}

# $correct_filters is HASH of 'case'=>conditions, undef, ARRAY of values, or SQL
#   as special case, if key is '', use same value as default for all cases
# %actual_filters is hash of 'case'=>filters
sub doit_block {
  my($label,$correct_filters,%actual_filters)=@_;
  $label.=' history='.(@$history? join(',',@$history): 'none');
  my $default_correct='HASH' eq ref($correct_filters)? $correct_filters->{''}: $correct_filters;
  my $ok=1;
  for my $case (keys %actual_filters) {
    # confess "case $case not in \$correct_filters" unless exists $correct_filters->{$case};
    # confess "case $case not in \$actual_filters" unless exists $actual_filters->{$case};
    my $correct=('HASH' eq ref($correct_filters) && exists $correct_filters->{$case})?
      $correct_filters->{$case}: $default_correct;
    my $actual=$actual_filters{$case};
    if (!defined $correct) {$correct={filters=>undef}}
    elsif (ref $correct) {$correct={filters=>{$filter_idtype=>$correct}}}
    else {$correct={query=>$correct}}
    my $ok1=doit_case("$label - $case",$correct,$actual); $ok&&=$ok1;
  }
  report_pass($ok,$label);
}
# $correct_filters is HASH of type=>undef,type=>[values] or query=>SQL
# $actual_filters is actual filters argument
sub doit_case {
  my($label,$correct_filters,$actual_filters)=@_;
  doit_one("$label: output=$output_idtype",$correct_filters,$actual_filters,$output_idtype) 
    or return 0;
  if ($OPTIONS{develop}) {
    doit_one("$label: outputs=evens",$correct_filters,$actual_filters,@even_idtypes) or return 0;
    doit_one("$label: outputs=odds",$correct_filters,$actual_filters,@odd_idtypes) or return 0;
    doit_one("$label: outputs=all",$correct_filters,$actual_filters,@all_idtypes) or return 0;
  }
  # pass($label);
  1;
}
sub doit_one {
  my($label,$correct_filters,$actual_filters,@output_idtypes)=@_;
  my $label1="$label input_ids=all";
  my @args=(input_idtype=>$input_idtype,input_ids=>\@all_input_ids,
	    output_idtypes=>\@output_idtypes);
  # translate
  my $correct=select_ur(babel=>$babel,@args,%$correct_filters);
  my $actual=$babel->translate(@args,filters=>$actual_filters);
  cmp_table_quietly($actual,$correct,"translate $label1") or return 0;
  # count
  my $actual=$babel->translate(count=>1,@args,filters=>$actual_filters);
  is_quietly($actual,scalar(@$correct),"count $label1") or return 0;
  # validate
  my $correct=select_ur(babel=>$babel,validate=>1,@args,%$correct_filters);
  my $actual=$babel->translate(validate=>1,@args,filters=>$actual_filters);
  cmp_table_quietly($actual,$correct,"validate $label1") or return 0;
  # count + validate
  my $actual=$babel->translate(count=>1,validate=>1,@args,filters=>$actual_filters);
  is_quietly($actual,scalar(@$correct),"count+validate $label1") or return 0;
  return 1 unless $OPTIONS{develop};

  # do it again with input_ids=>undef
  my $label1="$label input_ids=undef";
  my @args=(input_idtype=>$input_idtype,output_idtypes=>\@output_idtypes);
  # translate
  my $correct=select_ur(babel=>$babel,@args,%$correct_filters);
  my $actual=$babel->translate(@args,filters=>$actual_filters);
  cmp_table_quietly($actual,$correct,"translate $label1") or return 0;
  # count
  my $actual=$babel->translate(count=>1,@args,filters=>$actual_filters);
  is_quietly($actual,scalar(@$correct),"count $label1") or return 0;
  # validate
  my $correct=select_ur(babel=>$babel,validate=>1,@args,%$correct_filters);
  my $actual=$babel->translate(validate=>1,@args,filters=>$actual_filters);
  cmp_table_quietly($actual,$correct,"validate $label1") or return 0;
  # count + validate
  my $actual=$babel->translate(count=>1,validate=>1,@args,filters=>$actual_filters);
  is_quietly($actual,scalar(@$correct),"count+validate $label1") or return 0;

  1;
}

# adapted from babel.012.filter_object/filter_object.pm & filter_object.040.sql.t
sub init {
  my $autodb=new Class::AutoDB(database=>'test',create=>1); 
  isa_ok_quietly($autodb,'Class::AutoDB','sanity test - $autodb') or return 0;
  my $dbh=$autodb->dbh;
  cleanup_db($autodb);	# cleanup database from previous test
  # make component objects and Babel.
  my @idtypes=
    map {new Data::Babel::IdType(name=>"type_$_",sql_type=>'VARCHAR(255)')} 0..$num_idtypes-1;
  my @masters=map {
    new Data::Babel::Master
      (name=>"type_${_}_master",idtype=>$idtypes[$_],
       explicit=>has_history($_),history=>has_history($_))} 0..$#idtypes;
  my @maptables=map {
    new Data::Babel::MapTable(name=>"maptable_$_",idtypes=>[@idtypes[$_,$_+1]])} 
    0..$num_maptables-1;
  $babel=new Data::Babel
    (name=>'test',autodb=>$autodb,idtypes=>\@idtypes,masters=>\@masters,maptables=>\@maptables);
  isa_ok_quietly($babel,'Data::Babel','sanity test - $babel') or return 0;
  # setup the database
  # maptables
  for (my $i=0; $i<@maptables; $i++) {
    my $j=$i+1;
    my @data=map {["type_${i}/a_$_","type_${j}/a_$_"],
		    ["type_${i}/b_$_","type_${j}/b_$_"],
		      ["type_${i}/b_$_",undef],[undef,"type_${j}/b_$_"]} 0..$num_ids-1;
    load_maptable($babel,"maptable_$i",sort_data(@data));
  }
  # masters with histories
  for (my $i=0; $i<@idtypes; $i++) {
    next unless has_history($i);
    my @data=map {["type_${i}/a_$_","type_${i}/a_$_"]} 0..$num_ids-1;
    push(@data,map {["type_${i}/b_$_","type_${i}/b_$_"]} 0..$num_ids-1);
    push(@data,map {["type_${i}/x_$_","type_${i}/a_$_"]} 0..$num_ids-1);
    push(@data,map {["type_${i}/y_$_",undef]} 0..$num_ids-1); # retired ids
    load_master($babel,"type_${i}_master",sort_data(@data));
  }
  $babel->load_implicit_masters;
  load_ur($babel,'ur');

  $filter_idtype_obj=$babel->name2idtype($filter_idtype);
  $other_idtype_obj=$babel->name2idtype($other_idtype);

  # setup global id lists used in tests
  @all_input_ids=sort 
    (undef,map {("$input_idtype/a_$_","$input_idtype/b_$_","$input_idtype/c_$_",
		 "$input_idtype/x_$_","$input_idtype/y_$_")} 0..$num_ids-1);
  @all_filter_ids=sort 
    (map {("$filter_idtype/a_$_","$filter_idtype/b_$_","$filter_idtype/c_$_",
	   "$filter_idtype/x_$_","$filter_idtype/y_$_")} 0..$num_ids-1);
  @all_other_ids=sort 
    (map {("$other_idtype/a_$_","$other_idtype/b_$_","$other_idtype/c_$_",
	   "$other_idtype/x_$_","$other_idtype/y_$_")} 0..$num_ids-1);
  # filter ids used in standard tests
  @std_filter_ids=("$filter_idtype/a_0","$filter_idtype/b_1","$filter_idtype/x_2");
  @std_other_ids=("$other_idtype/a_0","$other_idtype/b_1","$other_idtype/x_2");
  # SQL LIKE patterns used in standard tests
  @std_filter_likes=("'$filter_idtype%a%0'","'$filter_idtype%b%1'","'$filter_idtype%x%2'");
  @std_other_likes=("'$other_idtype%a%0'","'$other_idtype%b%1'","'$other_idtype%x%2'");

  # TODO; drop ones that aren't used
  @like0_filter_ids=grep /0$/,@all_filter_ids;
  @like1_filter_ids=grep /1$/,@all_filter_ids;
  @like2_filter_ids=grep /2$/,@all_filter_ids;
  @likea_filter_ids=grep /\/a/,@all_filter_ids;
  @likeb_filter_ids=grep /\/b/,@all_filter_ids;
  @likec_filter_ids=grep /\/c/,@all_filter_ids;
  @likex_filter_ids=grep /\/x/,@all_filter_ids;
  @likey_filter_ids=grep /\/y/,@all_filter_ids;

  return 1;
}
# $history is ARRAY of type indexs with history
sub has_history {
  my $i=shift;
  $i=~s/type_//;		# strip 'type_' prefix if present
  scalar(grep {$_==$i} @$history);
}
# sort rows: a before b; full rows before undef
sub sort_data {
  sort {
    (all {defined $_} @$a,@$b)? $a->[0] cmp $b->[0]:
      ((all {defined $_} @$a)? -1:
       ((all {defined $_} @$b)? 1:
	((all {defined $_} @$a[0],@$b[0])? $a->[0] cmp $b->[0]:
	 ((all {defined $_} @$a[1],@$b[1])?  $a->[1] cmp $b->[1]:
	  (defined($a->[0])? -1: 1)))))
    } @_;
}
