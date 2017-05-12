package translate;
use t::util;
use t::utilBabel;
use t::stash;
use Carp;
use Getopt::Long;
use Hash::AutoHash;
use List::MoreUtils qw(uniq);
use List::Util qw(min);
use Math::BaseCalc;
use POSIX qw(ceil);
use Test::More;
use Text::Abbrev;
use Class::AutoDB;
use Data::Babel;
use strict;
our @ISA=qw(Exporter);

our @EXPORT=qw($OPTIONS $autodb $babel $dbh
	       @filter_subsets @output_subsets
	       load_maptable load_pdups load_master 
	       idtype_subsets id_range input_ids invalid_ids idtype2ids idtype2invalids idtype2col
               init doit make_filter);
our($OPTIONS,%OPTIONS,@OPTIONS,$autodb,$babel,$dbh,
    @idtypes,@idtype_subsets,@filter_subsets,@output_subsets);

# setup options
#
# explicit specifies rate of IdTypes with explicit masters
#  0 (or absent) means none, 1 means all, 2 means 1/2, etc.
# history
#  if explicit set, specifies rate of explicit masters that have histories
#  if explicit not set, specifies rate of explicits and all have histories
#  0 (or absent) means none
# extra_ids
#   if explicit set directly or via history, 
#     specifies rate of explicit masters w/ ids not contained in underlying maptables
#   if explicit not set, specifies rate of explicits and all have extra ids
#  0 (or absent) means none
# extra_idtypes: pair of numbers, eg, '1,2'
#  specifies rate of MapTables w/ added 'leaf' IdTypes and number of extra IdTypes
#  rate 0 means none, 1 means all, 2 means 1/2, etc.
#  if just 1 number it's rate, and number=1
#  default: 1
# pdups specifies rate of MapTables w/ added row that induce pdups
#  0 (or absent) means none, 1 means all, 2 means 1/2, etc.
#
# active test options
# 
# count causes 'count' option to be added to translate
# validate causes 'validate' option to be added to translate
# keep_pdups causes 'keep_pdups' option to be added to translate
#
# filter set automatically - controls calculation of @filter_subsets
# num_invalid_ids added to input_ids
# num_input_ids, num_invalid_ids, num_outputs, num_filters specify min,max, eg '1,5'
#   if min absent, eg, ',5', min=0
#   if max absent, eg, '1,', max=number of idtypes
#   if only one number, eg, '5', it's exact: min=max=number
#   'all' permitted for max (except for num_invalid_ids)
#   negative values equivalent to all minus value, eg, '-2' is all-2
#   if option missing or empty, corresponding option 'frozen' - see below
#     freeze outputs, freeze filters
#       for very fast tests, these guys take on a single value
#     freeze input_ids, freeze invalid_ids
#       same as min=max=<some default value> 
#       not really useful, but included for consistency
# input_ids_all - include inut_ids=>undef in cycle
# filter_none - include filter that matches nothing
# filter_all - include filter that matches everything
# filter_undef - add undef to each filter
#
# options controlling pdups removal algorithm - see Babel.pm for definitions
# pdups_group_cutoff
# pdups_prefixmatcher_cutoff
# pdups_prefixmatcher_class

@OPTIONS=qw(explicit=i history=i extra_ids=i extra_idtypes=s pdups=i
	    db_type=s graph_type=s link_type=s basecalc=i num_maptables=i arity=i
	    count validate keep_pdups
	    filter filter_none filter_all filter_undef
	    num_input_ids=s num_invalid_ids=s num_outputs=s num_filters=s
	    input_ids_all
	    pdups_group_cutoff=i pdups_prefixmatcher_cutoff=i pdups_prefixmatcher_class=s);
our %db_type=abbrev qw(binary staggered basecalc);
our %graph_type=abbrev qw(star chain tree);
our %link_type=abbrev qw(starlike chainlike);

# defaults appropriate for quick CPAN install
our %DEFAULTS=
  (db_type=>'staggered',graph_type=>'star',link_type=>'chainlike',basecalc=>2,arity=>4,
   num_maptables=>4,extra_idtypes=>1,op=>'translate',
  );

sub init {
  my $setup=shift;
  $autodb=new Class::AutoDB(database=>'test',create=>$setup); 
  isa_ok($autodb,'Class::AutoDB','sanity test - $autodb');
  $OPTIONS=get_options($setup);
  unless ($setup) {
    # expect 'old' to return the babel
    $babel=old Data::Babel(name=>'test',autodb=>$autodb);
    isa_ok($babel,'Data::Babel','sanity test - old Babel returned Babel object');
    @idtypes=@{$babel->idtypes};
    my @maptables=@{$babel->maptables};
    is(scalar @maptables,$OPTIONS->num_maptables,
       'sanity test - old Babel has expected number of maptables');

    # deal with subsets of idtypes
    # NG 13-07-07: idtype_subsets now uses power_subsets
    #              much faster than Set::Scalar for large sets if number of subsets not too big
    # # sort power sets to make runs reproducible and debugging easier
    # my $power_set=Set::Scalar->new(map {$_->name} @idtypes)->power_set;
    # @idtype_subsets=sort_name_lists(map {[$_->members]} $power_set->members);
    @filter_subsets=idtype_subsets('num_filters','link') if $OPTIONS{filter};
    @output_subsets=idtype_subsets('num_outputs','leaf');
    # set pdups removal options if necessary
    my($pdups_group_cutoff,$pdups_prefixmatcher_cutoff,$pdups_prefixmatcher_class)=
      @$OPTIONS{qw(pdups_group_cutoff pdups_prefixmatcher_cutoff pdups_prefixmatcher_class)};
    $babel->pdups_group_cutoff($pdups_group_cutoff) if defined $pdups_group_cutoff;
    $babel->pdups_prefixmatcher_cutoff($pdups_prefixmatcher_cutoff) 
      if defined $pdups_prefixmatcher_cutoff;
    $babel->pdups_prefixmatcher_class($pdups_prefixmatcher_class) 
      if defined $pdups_prefixmatcher_class;
  } else {			# setup new database
    cleanup_db($autodb);		# cleanup database from previous test
    Data::Babel->autodb($autodb);
    # rest of setup done by test
  }
  $dbh=$autodb->dbh;
}
# returns Hash::AutoHash
sub get_options {
  my $setup=shift;
  # initialize to defaults then overwrite with ones explicitly set
  %OPTIONS=%DEFAULTS;
  if (!$setup) {
    # if not setup, add in options saved from setup
    my $saved_options=get t::stash autodb=>$autodb,id=>'translate_options';
    @OPTIONS{keys %$saved_options}=values %$saved_options if $saved_options;
  }
  GetOptions(\%OPTIONS,@OPTIONS);
  # if setup, save options for later tests
  put t::stash autodb=>$autodb,id=>'translate_options',data=>\%OPTIONS if $setup;
  
  # deal with range options
  for my $option (qw(num_input_ids num_invalid_ids num_outputs num_filters)) {
    my $value=$OPTIONS{$option};
    $value=~s/^\s+|\s+$//g;	# strip leading, trailing whitespace
    if (!length($value) || $value=~/freeze/i) {
      # option missing or undef: set 'freeze'
      $OPTIONS{$option}=undef;
    } else {
      my @range=split(/\s*[\s,.]+\s*/,$value,2);
      my($min,$max)=@range==1? ($range[0],$range[0]): @range;
      $min=0 unless length $min;
      $max=0 unless length $max;
      $OPTIONS{$option}=[$min,$max];
    }}
  # expand abbreviations
  for my $option (qw(db_type graph_type link_type)) {
    next unless defined $OPTIONS{$option};
    my %abbrev=eval "\%$option";
    $OPTIONS{$option}=$abbrev{$OPTIONS{$option}} or confess "illegal value for option $option";
  }
  # history - if explicit not set, specifies rate of explicits and all have histories
  if (!defined $OPTIONS{explicit}  && defined $OPTIONS{history}) {
    $OPTIONS{explicit}=$OPTIONS{history};
    $OPTIONS{history}=1;
  }
  # extra_ids - if explicit not set, specifies rate of explicits and all have extra ids
  if (!defined $OPTIONS{explicit}  && defined $OPTIONS{extra_ids}) {
    $OPTIONS{explicit}=$OPTIONS{extra_ids};
    $OPTIONS{extra_ids}=1;
  }
  # extra_idtypes is 'rate,number'. if just rate, number defaults to 1
  # if either 0, no extra_idtypes
  my $option='extra_idtypes';
  my $value=$OPTIONS{$option};
  $value=~s/^\s+|\s+$//g;	# strip leading, trailing whitespace
  my($rate,$num)=split(/\s*[\s,.]+\s*/,$value,2);
  $num=1 unless defined $num;
  $OPTIONS{$option}=($rate==0||$num==0)? undef: [$rate,$num];
  
  # adjust history and extra_ids to absolute rates
  $OPTIONS{history}=$OPTIONS{explicit}*$OPTIONS{history};
  $OPTIONS{extra_ids}=$OPTIONS{explicit}*$OPTIONS{extra_ids};

  # filter set automatically from script name
  $OPTIONS{filter}=1 if !defined($OPTIONS{filter}) && scriptbasename=~/filter/;

  $OPTIONS=new Hash::AutoHash %OPTIONS;
}

# generate idtype subsets
# @idtypes, @idtype_subsets global!!
sub idtype_subsets {
  my($option,$freeze_type)=@_;
  my @subsets;
  my $num_subsets=$OPTIONS->$option;
  if (defined $num_subsets) {
    # NG 13-07-07: support negative limits
    # $min=@idtypes if $min eq 'all';
    # $max=@idtypes if $max eq 'all';
    my($min,$max)=map {$_=~/all/? scalar(@idtypes): ($_<0? scalar(@idtypes)+$_: $_)}
      @$num_subsets;
    # NG 13-07-07: use power_subsets. much faster than Set::Scalar for large sets 
    #              if number of subsets not too big
    # @subsets=grep {@$_>=$min && @$_<=$max} @idtype_subsets;
    my @idtype_names=map {$_->name} @idtypes;
    @subsets=power_subsets(\@idtype_names,$min,$max);
    } else {
      @subsets=[sort grep /$freeze_type/,map {$_->name} @idtypes];
    }
  wantarray? @subsets: \@subsets;
}
# generate id num ranges for input, invalid
sub id_range {
  my($what,$idtype,$freeze_num)=@_;
  my $option="num_${what}_ids";
  my($min,$max);
  my @ids=$what=~/input/? idtype2ids($idtype): idtype2invalids($idtype);
  my $range=$OPTIONS->$option;
  if (defined $range) {
    # NG 13-07-07: support negative limits
    # ($min,$max)=@$range;
    # $min=@ids if $min eq 'all';
    # $max=@ids if $max eq 'all';
    ($min,$max)=map {$_=~/all/? scalar(@ids): ($_<0? scalar(@ids)+$_: $_)} @$range;
  } else {
      ($min,$max)=($freeze_num,$freeze_num);
    }
  ($min,$max);
}
# generate input ids list
# infeasible to iterate over whole range, so cycle through
# deals with input_ids_all, and max='all'
sub input_ids {
  my($idtype,$num,$min,$max,$input_ids_all)=@_;
  my $ids;
  return(undef,$min) if $input_ids_all && $num>$max;
  $num=$min if $num>$max;
  $ids=idtype2ids($idtype,$num);
  return($ids,$num+1);
} 
# generate invalid ids list
# unwise to iterate over whole range, so cycle through
sub invalid_ids {
  my($idtype,$num,$min,$max)=@_;
  $num=$min if $num>$max;
  my $ids=idtype2invalids($idtype,$num);
  return($ids,$num+1);
} 

# args are idtype names
sub doit {
  my($input_name,$input_ids,$filters,$output_names,$file,$line)=@_;
  $filters={} unless defined $filters;
  my $ok=1;
  my @filter_names=keys %$filters;
  my @args=(input_idtype=>$input_name,filters=>$filters,output_idtypes=>$output_names);
  push(@args,count=>1) if $OPTIONS->count;
  push(@args,validate=>1) if $OPTIONS->validate;
  push(@args,keep_pdups=>1) if $OPTIONS->keep_pdups;
  my $label;
  if ($input_ids ne 'all') {
    push(@args,input_ids=>$input_ids);
    $label=$OPTIONS->db_type.": input=$input_name, num input_ids=".
      (defined $input_ids? scalar(@$input_ids): 'all').
	" filters=@filter_names, outputs=@$output_names";
  } else {
    push(@args,input_ids_all=>1);
    $label=$OPTIONS->db_type.": input=$input_name, input_ids_all=1, filters=@filter_names, outputs=@$output_names";
  }
  my $correct=select_ur(babel=>$babel,@args);
  my $actual=$babel->translate(@args);
  my $op=!$OPTIONS->count? 'translate': 'count';
  $ok&&=cmp_op_quietly($actual,$correct,$op,"$op $label",$file,$line);
  $ok;
}

########################################
# these functions generate data loaded into database or used in queries
########################################
# arg is maptable number
sub load_maptable {
  my($maptable)=@_;
  my $name=$maptable->name;
  my($i)=$name=~/_(\d+)$/;
  my @idtype_names=map {$_->name} @{$maptable->idtypes};
  my @data;
  unless ($OPTIONS->db_type eq 'basecalc') {
    my @series=data_series($i);	# make data series for $OPTIONS->db_type
    # for each value in series, create a row
    for my $val (@series) {
      push(@data,[map {"$_/$val"} @idtype_names]);
    }
  } else { # all strings of length @idtype_names digits over base $basecalc
    my $calc=new Math::BaseCalc(digits=>[0..$OPTIONS->basecalc-1]);
    my $numdigits=@idtype_names;
    for (my $i=0; $i<$OPTIONS->basecalc**$numdigits; $i++) {
      my @digits=split('',sprintf("%0.*i",$numdigits,$calc->to_base($i)));
      push(@data,[map {"$idtype_names[$_]/d_$digits[$_]"} 0..$numdigits-1]);
    }
  }
  # add in 'multi' rows: links are 'multi','multi'; leafs are 'multi_000','multi_001']
  push(@data,[map {/^leaf/? "$_/multi_000": "$_/multi"} @idtype_names]);
  push(@data,[map {/^leaf/? "$_/multi_001": "$_/multi"} @idtype_names]);
  t::utilBabel::load_maptable($babel,$maptable,@data);

  # add rows that generate pseudo-duplicates if necessary
  my $pdups=$OPTIONS->pdups;
  load_pdups($maptable) if $pdups && $i%$pdups==0;
}
# add rows that generate pseudo-duplicates
sub load_pdups {
  my($maptable)=@_;
  # code adapted from utilBabel::load_maptable
  my $table=$maptable->tablename;
  my @idtypes=@{$maptable->idtypes};
  my @columns=map {$_->name} @idtypes;
  my $columns=join(',',@columns);
  for (my $i=0; $i<@columns; $i++) {
    my $column=$columns[$i];
    my @select=(('NULL')x$i,$column,('NULL')x($#columns-$i));
    my $select=join(',',@select);
    my $where="$column IS NOT NULL AND $column NOT LIKE 'nomatch%'";
    my $sql=qq(INSERT INTO $table ($columns) 
               (SELECT DISTINCT $select FROM $table WHERE $where));
    $dbh->do($sql);
    # initialize @select to nomatch in all columns, then drop in this column
    my @select=map {"'$_/nomatch_$table'"} @columns;
    $select[$i]=$column;
    my $select=join(',',@select);
    my $where="$column IS NOT NULL AND $column NOT LIKE 'nomatch%'";
    my $sql=qq(INSERT INTO $table ($columns) 
               (SELECT DISTINCT $select FROM $table WHERE $where));
    $dbh->do($sql);
  }
}

# arg is Master object
sub load_master {
  my($master)=@_;
  my $idtype=$master->idtype;
  my @maptables=@{$idtype->maptables};
  my @maptable_names=map {$_->name} @maptables;
  my $column=$idtype->name;
  my @inner_sql=!$master->history?
    (map {qq(SELECT DISTINCT $column FROM $_ WHERE $column IS NOT NULL)} @maptable_names):
    (map {(qq(SELECT DISTINCT $column,$column AS _X_$column FROM $_ WHERE $column IS NOT NULL),
	    qq(SELECT DISTINCT $column,CONCAT('_x_',$column) AS _X_$column FROM $_ WHERE $column IS NOT NULL))} 
     @maptable_names);
  my $inner_sql=join("\nUNION\n",@inner_sql);
  my $columns=$column.($master->history? ", _X_$column": '');
  my $name=$master->name;
  # my $sql=qq(CREATE TABLE $name ($columns) AS $inner_sql);
  my $sql=qq(CREATE TABLE $name AS $inner_sql);
  $dbh->do($sql);
  # add extra rows if needed
  my $extra_ids=$OPTIONS->extra_ids;
  my($i)=$column=~/_(\d+)$/;
  if ($extra_ids && $i%$extra_ids==0) {
    my @nums=map {sprintf("%03d",$_)} (0,1,2);
    my @values=!$master->history?
      map {"('$column/nomatch_$_')"} @nums :
	((map {"('$column/nomatch_$_','_x_$column/nomatch_$_')"} @nums),
	 (map {"(NULL,'_x_$column/retired_$_')"} @nums));
    my $values=join(', ',@values);
    my $sql=qq(INSERT INTO $name ($columns) VALUES $values);
    $dbh->do($sql);
  }
}    

# all valid input id for a given type
# arg is IdType or name
our %IDS;			# cache of id lists
our %IDX_NEXT;			# idx of next id to use - so we cycle through them...
sub idtype2ids {
  my($idtype,$name)=ref $_[0]? ($_[0],$_[0]->name): ($babel->name2idtype($_[0]),$_[0]);
  my $ids=$IDS{$name} || ($IDS{$name}=fetch_ids($idtype,$name));
  my $all=scalar @$ids;
  my $num=@_>1? $_[1]: $all;
  my $next=defined $IDX_NEXT{$name}? $IDX_NEXT{$name}: ($IDX_NEXT{$name}=0);
  my @idxs=map {($next+$_)%$all} (0..$num-1);
  my @ids=@$ids[@idxs];
  $IDX_NEXT{$name}++;
  wantarray? @ids: \@ids;
}
sub fetch_ids {
  my($idtype,$name)=@_;
  my $column=!$idtype->history? $name: "_X_$name";
  my $table=$idtype->master->name;
  my $sql=qq(SELECT $column FROM $table);
  my $ids=$dbh->selectcol_arrayref($sql);
}

# helper function that takes into account history
sub idtype2col {
  my($idtype,$name)=ref $_[0]? ($_[0],$_[0]->name): ($babel->name2idtype($_[0]),$_[0]);
  !$idtype->history? $name: "_X_$name"
}
# helper function that generates standard looking invalid ids
sub idtype2invalids {
  my($idtype,$name)=ref $_[0]? ($_[0],$_[0]->name): ($babel->name2idtype($_[0]),$_[0]);
  my $num=@_>1? $_[1]: 3;
  my @nums=map {sprintf("%03d",$_)} (0..$num-1);
  my @ids=map {"$name/invalid_$_"} @nums;
  wantarray? @ids: \@ids;
}
# generate series of raw values for use in maptables, masters, and IN clauses
sub data_series {
  my($i)=@_;
  eval $OPTIONS->db_type.'_series($i)';
}
sub binary_series {
  my($i)=@_;
  my @series=_binary_series($OPTIONS->num_maptables,$i);
  map {"a_$_"} @series;
}
sub staggered_series {
  my($i)=@_;
  my $last_maptable=$OPTIONS->num_maptables-1;
  defined $i?
    ((map {'b_'.sprintf('%03d',$_)} ($i..$last_maptable)),
     (map {'c_'.sprintf('%03d',$last_maptable-$_)} (0..$i))):
       (map {('b_'.sprintf('%03d',$_),'c_'.sprintf('%03d',$_))} (0..$last_maptable));
}
sub basecalc_series {
  map {"d_$_"} 0..$OPTIONS->basecalc-1;
}
sub _binary_series {
  my($bits,$my_bit)=@_;
  if (defined $my_bit) {	# return $bits-wide numbers with $my_bit set
    my $mask=1<<$my_bit;
    return map {sprintf '%0*b',$bits,$_} grep {$_&$mask} (0..2**$bits-1);
  } else {			# return all $bits-wide numbers
    return map {sprintf '%0*b',$bits,$_} (0..2**$bits-1);
  }
}

# for debugging. args are number of bits, and number to convert
sub as_binary_string {sprintf '%0*b',@_}

########################################
# these functions used by filter tests to get filter ids that generate
#   results of desired size
########################################
# NG 13-06-21: original implementation hopelessly slow 'cuz it calls select_ur repeatedly

# make filters HASH. 
#   $filters arg is ARRAY of filter idtype names
#   if $multi is true, include 'multi' ids
sub make_filter {
  my($input,$input_ids,$filters,$outputs,$multi)=@_;
  return undef unless @$filters;
  $input_ids=undef if $input_ids eq 'all';
  my $input_col=idtype2col($input);
  my @filter_cols=map {idtype2col($_)} @$filters;
  my @output_cols=@$outputs;
  my $filter={};
  if ($OPTIONS->db_type eq 'basecalc') {
    # for basecalc db, each digit selects approx 1/basecalc rows
    my $basecalc=$OPTIONS->basecalc;
    for my $name (@$filters) {
      my @filter_ids=
	((map {"$name/d_$_"} 0..($basecalc-1)),
	 # add 'multi' values if desired: links are 'multi'; leafs are 'multi_000','multi_001'
	 ($multi? ($name=~/^leaf/? "$name/multi_000": "$name/multi"): ()));
      $filter->{$name}=\@filter_ids;
    }
  } else {
    ########################################
    # for other db_types, look at ur to choose ids that generate diverse results
    # not always possible
    my @columns=uniq($input,@filter_cols,@output_cols);
    my $columns=join(',',@columns);
    my %col2idx=val2idx(@columns);
    my $where;
    if (defined $input_ids) {
      my @input_ids=map {$dbh->quote($_)} @$input_ids;
      $where="WHERE $input_col IN ".'('.join(', ',@input_ids).')';
    }
    my $sql=qq(SELECT DISTINCT $columns FROM ur $where);
    my $table=$dbh->selectall_arrayref($sql);
    unless (@$table) {
      # input_ids already too selective. all we can test is filter mechanics
      # filter ids don't matter. just pick increasing number of arbitray ids
      my $num_ids;
      for my $name (@$filters) {
	my $filter_ids=idtype2ids($name,++$num_ids);
	$filter->{$name}=$filter_ids;
      }
    } else {
      # group rows by number of NULLs in output columns. use filter_ids from each group
      # initialize filter_ids to hashes temporarily
      map {$filter->{$_}={}} @$filters;
      my %groups=group {scalar grep {!defined $_} @$_[@col2idx{$input_col,@output_cols}]}
	@$table;
      # my $row=$group->[0];
      # map {push(@{$filter->{$_}},$row->[$col2idx{$_}])} @$filters;
      for my $group (values %groups) {
	for my $name (@$filters) {
	  for my $row (@$group) {
	    my $id=$row->[$col2idx{idtype2col($name)}];
	    next if $filter->{$name}->{$id};
	    $filter->{$name}->{$id}=1, last unless exists $filter->{$name}->{$id};
	  }}}
      # convert hashes to lists
      map {$filter->{$_}=[map {$_ ne ''? $_: undef} keys %{$filter->{$_}}]} @$filters;
      # add 'multi' values if desired: links are 'multi'; leafs are 'multi_000','multi_001'
      if ($multi) {
	map {push(@{$filter->{$_}},($_=~/^leaf/? "$_/multi_000": "$_/multi"))} @$filters;
      }}}
  return $filter;
}

1;
