package t::utilBabel;
use t::util;
use Carp;
use Test::More;
use Test::Deep qw(cmp_details deep_diag subbagof);
use List::Util qw(first min);
use List::MoreUtils qw(uniq any);
use Hash::AutoHash::Args;
# use Hash::AutoHash::MultiValued;
use Exporter();
use strict;
our @ISA=qw(Exporter);

our @EXPORT=
  (@t::util::EXPORT,
   qw(check_object_basics sort_objects power_subsets cross_product vary_case uniq_rows sql_in
      prep_tabledata load_maptable load_master load_ur select_ur select_ur_sanity cleanup_db
      check_database_sanity check_maptables_sanity check_masters_sanity 
      check_handcrafted_idtypes check_handcrafted_masters check_handcrafted_maptables
      check_handcrafted_name2idtype check_handcrafted_name2master check_handcrafted_name2maptable
      check_handcrafted_id2object check_handcrafted_id2name check_implicit_masters
      load_handcrafted_maptables load_handcrafted_masters
      cmp_table cmp_table_quietly cmp_table_nocase
      cmp_op cmp_op_quietly cmp_op_quickly
      pnames pgraph
    ));
# NG 13-07-16: not used now but keep for future
push(@EXPORT,qw(grep_rows sort_rows check_table 
		cmp_objects cmp_objects_quietly order_tables));
# NG 13-07-16: used internally
#              filter_ur count_ur cleanup_ur
# NG 13-07-16: obsolete. 
#              sort_name_lists

sub check_object_basics {
  my($object,$class,$name,$label)=@_;
  report_fail($object,"$label connected object defined") or return 0;
  $object->name;		# touch object in case still Oid
  # NG 13-09-24: changed to isa_ok_quietly
  # report_fail(UNIVERSAL::isa($object,$class),"$label: class") or return 0;
  isa_ok_quietly($object,$class,$label) or return 0;
  report_fail($object->name eq $name,"$label: name") or return 0;
  return 1;
}
sub check_objects_basics {
  my($objects,$class,$names,$label)=@_;
  my @objects=sort_objects($objects,$label);
  for my $i (0..$#$objects) {
    my $object=$objects->[$i];
    check_object_basics($objects->[$i],$class,$names->[$i],"$label object $i") or return 0;
  }
  return 1;
}
# sort by name.
sub sort_objects {
  my($objects,$label)=@_;
  # hmm.. this doesn't work for Oids. not important anyway, so just bag it
  # TODO: revisit when AutoDB provides public method for fetching Oids.
#   # make sure all objects have names
#   for my $i (0..$#$objects) {
#     my $object=$objects->[$i];
#     report_fail(UNIVERSAL::can($object,'name'),"$label object $i: has name method") 
#       or return ();
#   }
  my @sorted_objects=sort {$a->name cmp $b->name} @$objects;
  wantarray? @sorted_objects: \@sorted_objects;
}
# NG 13-07-07: generate subsets of power set. much faster than Set::Scalar
#             for large sets if number of subsets not too big
# 1st argument is either ARRAY ref or integer
#   if integer, it's universe size; universe is 0..$size-1
#   if ARRAY, it's universe
# min, max are sizes of subsets emitted
# if only one provided, it's max
# if none provided, it's regular power_set. equivalent to min=0, max=size
sub power_subsets {
  my($size,$universe);
  if (ref($_[0])) {
    $universe=shift;
    $size=scalar @$universe;
  } else {
    $size=shift;
  }
  my($min,$max)=@_==1? (0,@_): (@_>1? @_: (0,$size));
  my @subsets=(defined $max && $max==0)? []: _power_subsets(0,$size,$min,$max);
  @subsets=map {[@$universe[@{$_}]]} @subsets if defined $universe;
  wantarray? @subsets: \@subsets;
}
sub _power_subsets {
  my($i,$size,$min,$max)=@_;
  return ([],[$i]) if $i==$size-1;
  my @recurse=_power_subsets($i+1,$size,$min,$max);
  # cases: size refers to size of downstream subset
  # 1) size==max. implies size>=min. pass along, don't add current
  # 2) size<max && size+i>=min.      pass along, and add current
  # 3) size<max && size+1+i>=min.    add current
  # 4) else.  do nothing
  my @out=map {
    scalar(@$_)==$max? $_ :
      (scalar(@$_)+$i>=$min? ($_,[$i,@$_]): 
       (scalar(@$_)+1+$i>=$min? [$i,@$_]: ()))} @recurse;

  @out;
}
# NG 13-07-20: cartesion product of a list of vectors (ARRAYs)
# arguments are either ARRAY refs or integers
#   if integer, it's universe size; universe is 0..$size-1
#   if ARRAY, it's universe
sub cross_product {
  my @out;
  if (any {ref $_} @_) {
    my @sets=@_;
    my @sizes=map {ref $_? scalar(@$_): $_} @sets;
    my @idx_rows=_cross_product(@sizes);
    for my $idx_row (@idx_rows)  {
      my @row=map
	{my $idx=$idx_row->[$_]; ref $sets[$_]? $sets[$_]->[$idx]: $idx;} 0..@sets-1;
      push(@out,\@row);
    }
  } else {
    @out=_cross_product(@_);
  }
  wantarray? @out: \@out;
}
sub _cross_product {
  my @sizes=@_;
  return unless @sizes;
  my $size=shift @sizes;
  return map {[$_]} 0..$size-1 unless @sizes;
  my @recurse=_cross_product(@sizes);
  map {my $i=$_; map {[$i,@$_]} @recurse} 0..$size-1;
}

# NG 13-06-15: added vary_case to test case insensitve comparisons
# vary case for list of ids
sub vary_case {
  my $wantarray=@_==0||@_>1||!ref($_[0]);
  my @in=flatten(@_);
  my @out;
  my $case=0;
  while(my $id=shift @in) {
    if ($case==0) {push(@out,lc($id))}
    elsif ($case==1) {push(@out,uc($id))}
    elsif ($case==2) {push(@out,ucfirst($id))}
    else {push(@out,ucsecond($id))}
    $case=(++$case%4);
  }
  $wantarray? @out: \@out;
}
sub ucsecond {substr($_[0],0,1).ucfirst(substr($_[0],1))}

# scrunch whitespace
sub scrunch {
  my($x)=@_;
  $x=~s/\s+/ /g;
  $x=~s/^\s+|\s+$//g;
  $x;
}
sub scrunched_eq {scrunch($_[0]) eq scrunch($_[1]);}

########################################
# these functions deal w/ relational tables

# prepare table data
# data can be 
#   string: one line per row; each row is whitespace-separated values
#   list or ARRAY of strings: each string is row
#   list or ARRAY of ARRAYs: each sub-ARRAY is row
# CAUTION: 2nd & 3rd cases ambiguous: list of 1 ARRAY could fit either case!
sub prep_tabledata {
  # NG 12-08-24: fixed to handle list or ARRAY of ARRAYs as documented
  # my @rows=(@_==1 && !ref $_[0])? split(/\n+/,$_[0]): flatten(@_);
  my @rows=(@_==1 && !ref $_[0])? split(/\n+/,$_[0]): (@_==1)? flatten(@_): @_;
  # clean whitespace and split rows 
  @rows=map {ref($_)? $_: do {s/^\s+|\s+$//g; s/\s+/ /g; [split(' ',$_)]}} @rows;
  # convert NULLS into undefs
  for my $row (@rows) {
    map {$_=undef if 'NULL' eq uc($_)} @$row;
  }
  \@rows;
}
sub load_maptable {
  my($babel,$maptable)=splice(@_,0,2);
  my $data=prep_tabledata(@_);
  ref $maptable or $maptable=$babel->name2maptable($maptable);

  # code adapted from ConnectDots::LoadMapTable Step
  my $tablename=$maptable->tablename;
  my @idtypes=@{$maptable->idtypes};
  my @column_names=map {$_->name} @idtypes;
  my @column_sql_types=map {$_->sql_type} @idtypes;
  my @column_defs=map {$column_names[$_].' '.$column_sql_types[$_]} (0..$#idtypes);
  my @indexes=@column_names;

  # code adapted from MainData::LoadData Step
  my $dbh=$babel->autodb->dbh;
  $dbh->do(qq(DROP TABLE IF EXISTS $tablename));
  my $columns=join(', ',@column_defs);
  $dbh->do(qq(CREATE TABLE $tablename ($columns)));

  # new code: insert data into table
  my @values=map {'('.join(', ',map {$dbh->quote($_)} @$_).')'} @$data;
  my $values=join(",\n",@values);
  $dbh->do(qq(INSERT INTO $tablename VALUES\n$values));

  # code adapted from MainData::LoadData Step
  # put parens around single columns
  my @alters=map {"($_)"} @indexes; # put parens around single columns
  my $alters=join(', ',map {"ADD INDEX $_"} @alters);
  $dbh->do(qq(ALTER TABLE $tablename $alters));
}
sub load_master {
  my($babel,$master)=splice(@_,0,2);
  ref $master or $master=$babel->name2master($master);
  if ($master->implicit) {
  TODO: {
      fail("futile to load data for implicit master. use load_implicit_master instead");
      return;
    }}
  my $data=prep_tabledata(@_);

  # code adapted from ConnectDots::LoadMaster, ConnectDots::LoadImpMaster, MainData::LoadData
  my $tablename=$master->tablename;
  my $idtype=$master->idtype;
  my $column_name=$idtype->name;
  my $column_sql_type=$idtype->sql_type;
  my $column_def="$column_name $column_sql_type";
  # NG 12-11-18: add _X_ column for history
  $column_def.=", _X_$column_name $column_sql_type" if $master->history;
  my $column_list=!$master->history? $column_name: " _X_$column_name, $column_name";

  # NG 12-09-30: no longer get here if master implicit
  # my $query=$master->query;

  my $dbh=$babel->autodb->dbh;
  # NG 12-08-24: moved DROPs out conditionals since master could be table in one babel
  #              and view in another
  $dbh->do(qq(DROP VIEW IF EXISTS $tablename));
  $dbh->do(qq(DROP TABLE IF EXISTS $tablename));
  # NG 12-09-30: no longer get here if master implicit
  # if ($master->view) {
  #   $dbh->do(qq(CREATE VIEW $tablename AS\n$query));
  #   return;
  # }
  my $sql=qq(CREATE TABLE $tablename ($column_def));
  # NG 12-09-30: no longer get here if master implicit
  # $sql.=" AS\n$query" if $master->implicit; # if implicit, load data via query
  $dbh->do($sql);
  # NG 12-09-30: no longer get here if master implicit
  # if (!$master->implicit) {
  # new code: insert data into table
  my @values=map {'('.join(', ',map {$dbh->quote($_)} @$_).')'} @$data;
  my $values=join(",\n",@values);
  $dbh->do(qq(INSERT INTO $tablename ($column_list) VALUES\n$values));
  # }
  # code adapted from MainData::LoadData Step
  $dbh->do(qq(ALTER TABLE $tablename ADD INDEX ($column_name)));
  # NG 12-11-18: add _X_ column for history
  $dbh->do(qq(ALTER TABLE $tablename ADD INDEX ("_X_$column_name"))) if $master->history;

}
# create universal relation (UR)
# algorithm: natual full outer join of all maptables and explicit masters
#            any pre-order traversal of schema graph will work (I think!)
# sadly, since MyQSL still lacks full outer joins, have to emulate with left/right
# joins plus union. do it step-by-step: I couldn't figure out how to do it in
# one SQL statement...
# >>> assume that lexical order of maptables gives a valid pre-order <<<
# NG 13-06-12: assumption above is certainly worng in some tests and probably wrong 
#              in many others.  scary this wasn't cught sooner.
#              as a first step towards a solution, add @tables arg to let caller
#              pass in a valid join order
sub load_ur {
  my($babel,$urname,@tables)=@_;
  $urname or $urname='ur';
  # if @tables not given, ASSUME lexical order of maptables is valid pre-order
  # this will change soon
  if (@tables) {
    @tables=map {$babel->name2maptable($_)} @tables;
  } else {
    @tables=sort {$a->tablename cmp $b->tablename} @{$babel->maptables};
  }
  # add in explicit Masters. order doesn't matter so long as they're last
  push(@tables,grep {$_->explicit} @{$babel->masters});
  # %column2type maps column_names to sql types
  my %column2type;
  my @idtypes=@{$babel->idtypes};
  @column2type{map {$_->name} @idtypes}=map {$_->sql_type} @idtypes;
  my @x_idtypes=grep {$_->history} @idtypes;
  @column2type{map {'_X_'.$_->name} @x_idtypes}=map {$_->sql_type} @x_idtypes;

  my $left=shift @tables;
  while (my $right=shift @tables) {
    my $result_name=@tables? undef: $urname; # final answer is 'ur'
    $left=full_join($babel,$left,$right,$result_name,\%column2type);
  }
  $left;
}
# NG 11-01-21: added 'translate all'
# NG 12-08-22: added 'filters'
# NG 12-09-04: rewrote to do filtering in Perl - seems more robust test strategy
# NG 12-09-21: added support for input_ids=>scalar, filters=>ARRAY,  
#              all semantics of filter=>undef
# NG 12-11-18: added support for histories
# NG 12-11-20: fixed input column for histories: 0th column is '_X_' if input has history
# NG 12-11-23: added validate
# NG 13-06-10: changed to do case insensitive comparisons, eg, searching for 'htt' as gene_symbol
# NG 13-10-14: added query
# select data from ur (will actually work for any table)
sub select_ur {
  my $args=new Hash::AutoHash::Args(@_);
  my($babel,$urname,$input_idtype,$input_ids,$output_idtypes,$filters,$query,$validate,$nocase)=
    @$args{qw(babel urname input_idtype input_ids output_idtypes filters query validate nocase)};
  confess "input_idtype must be set. call select_ur_sanity instead" unless $input_idtype;
  # confess "Only one of inputs_ids or input_ids_all may be set" if $input_ids && $input_ids_all;
  $urname or $urname=$args->tablename || 'ur';
  my $input_idtype=ref $input_idtype? $input_idtype->name: $input_idtype;
  if (defined $input_ids) {
    $input_ids=[$input_ids] unless ref $input_ids;
    confess "bad input id: ref or stringified ref"
      if grep {ref($_) || $_=~/ARRAY|HASH/} @$input_ids;
    # NG 12-11-14: drop duplicate input ids so validate won't get extra invalid ids
    $input_ids=[uniq(@$input_ids)];
  }
  my @output_idtypes=map {ref $_? $_->name: $_} @$output_idtypes;
  $filters=filters_array($filters) if ref $filters eq 'ARRAY';
  my @filter_idtypes=keys %$filters;
  
  my $dbh=$babel->autodb->dbh;
  # NG 10-08-25: removed 'uniq' since duplicate columns are supposed to be kept
  # my @columns=uniq grep {length($_)} ($input_idtype,@output_idtypes);
  # NG 12-09-04: include filter_idtypes so we can do filtering in Perl
  # NG 12-09-04: test for length obsolete, since input_idtype required
  # my @columns=grep {length($_)} ($input_idtype,@filter_idtypes,@output_idtypes);
  # NG 12-11-20: 0th column is '_X_' if input has history
  my @columns=((!_has_history($babel,$input_idtype)? $input_idtype: "_X_$input_idtype"),
	       @filter_idtypes,@output_idtypes);
  # NG 12-11-18: tack on filter history columns
  push(@columns,map {"_X_$_"} grep {_has_history($babel,$_)} @filter_idtypes);
  my $columns=join(', ',@columns);
  my $sql=qq(SELECT DISTINCT $columns FROM $urname WHERE $columns[0] IS NOT NULL);
  my $table=$dbh->selectall_arrayref($sql);
  # hang onto valid input ids if doing validate
  # NG 13-06-10: added 'lc' for case insensitive comparisons
  my %valid=map {lc $_->[0]=>1} @$table if $validate;
  # NG 13-10-14: added query. have to do query after validate.
  $sql.=" AND ($query)" if $query;
  my $table=$dbh->selectall_arrayref($sql);

  # now do filtering. columns are input, filters, then outputs, finally history columns
  my %name2idx=map {$columns[$_]=>$_} 0..$#columns;
  $table=filter_ur($table,0,$input_ids);
  for(my $j=0; $j<@filter_idtypes && @$table; $j++) {
    my $filter_ids=$filters->{$filter_idtypes[$j]};
    $table=filter_ur($table,$name2idx{"_X_$columns[$j+1]"}||$j+1,$filter_ids);
  }
  # remove filter_idtype columns
  map {splice(@$_,1,@filter_idtypes)} @$table;
  # NG 12-11-18: remove history columns
  map {splice(@$_,1+@output_idtypes)} @$table;
  # remove duplicate rows. dups can arise when filter columns spliced out
  $table=uniq_rows($table);

  # NG 10-11-10: remove rows whose output columns are all NULL, because translate now skips these
  # NG 12-09-04: rewrote loop to one-liner below
  # NG 12-11-23: don't remove NULL rows when validate set
  unless ($validate) {
    @$table=grep {my @row=@$_; grep {defined $_} @row[1..$#row]} @$table if @output_idtypes;
  } else {
    # %id2valid maps input ids to validity
    # %have_id tells which input ids are in result
    # @missing_ids are input ids not in result - some are valid, some not
    $input_ids=[keys %valid] unless $input_ids; # input_ids_all
    # NG 13-06-10: added 'lc' for case insensitive comparisons
    my %id2valid=map {my $id=lc $_; $id=>$valid{$id}||0} @$input_ids;
    my %have_id=map {lc $_->[0]=>1} @$table;
    my @missing_ids=grep {!$have_id{lc $_}} @$input_ids;
    # existing rows are valid - splice in 'valid' column
    map {splice(@$_,1,0,1)} @$table;
    # add rows for missings ids - some valid, some not
    # NG 13-06-15: added '||0' for case insensitive comparisons
    push(@$table,map {[$_,$id2valid{$_}||0,(undef)x@$output_idtypes]} @missing_ids);
  }
  # NG 13-07-15: remove partial duplicates
  $table=remove_pdups($table) unless $args->keep_pdups;
  $table;
}

sub remove_pdups {
  my $table=shift;

  my %groups=group {$_->[0]} @$table;
  my $pseudo_dups=0;
  $table=[];
  for my $group (values %groups) {
    push(@$table,@$group),next unless scalar(@$group)>1;
    my @rows=sort {undefs($a)<=>undefs($b)} @$group;
    my %rows=map {$_=>$rows[$_]} (0..$#rows);
    my %pseudo_dups;
    for(my $i=0; $i<@rows-1; $i++) {
      next unless $rows{$i};
      for(my $j=$i+1; $j<@rows; $j++) {
	next unless $rows{$j};
	delete $rows{$j}, $pseudo_dups++ if pseudo_dup($rows[$i],$rows[$j]);
      }
    }
    push(@$table,values %rows);
  }
  # TODO: put this under some sort of flag...
  # diag('+++ select_ur pseudo_dups='.$pseudo_dups) if $pseudo_dups;
  # diag('+++ select_ur pseudo_dups='.$pseudo_dups);

  $table;
}
# used to sort by number of undefs
sub undefs {scalar grep {!defined $_} @{$_[0]};}
# row $j is pseudo-dup of $i if they agree wherever both defined, else $j is undef
sub pseudo_dup {
  my($rowi,$rowj)=@_;
  for(my $k=0; $k<=@$rowi; $k++) {
    return 0 if defined $rowj->[$k] && $rowi->[$k] ne $rowj->[$k];
  }
  1;
}

# NG 13-06-10: changed to do case insensitive comparisons
sub filter_ur {
  my($table,$col,$ids)=@_;
  if (defined $ids) {
    $ids=[$ids] unless ref $ids;
    confess "bad filter id for column $col: ref or stringified ref"
      if grep {ref($_) || $_=~/ARRAY|HASH/} @$ids;
    if (@$ids) {
      my(@table1,@table2);
      my @defined_ids=grep {defined $_} @$ids;
      # NG 12-10-29: changed pattern to match entire field
      my $pattern=join('|',map {"\^$_\$"} @defined_ids);
      # NG 13-06-01: added 'i' for case insensitive matching
      $pattern=qr/$pattern/i;
      @table1=grep {$_->[$col]=~/$pattern/} @$table if @defined_ids;
      @table2=grep {!defined $_->[$col]} @$table if @defined_ids!=@$ids;
      @$table=(@table1,@table2);
    } else {			# empty list of ids - result empty
      @$table=();
    }
  } else {			# filter=>undef
    @$table=grep {defined $_->[$col]} @$table;
  }
  $table;
}
# NG 13-06-10: changed to do case insensitive comparisons
# remove duplicate rows from table
sub uniq_rows {
  my($rows)=@_;
  # NG 13-06-10: added 'lc' for case insensitive comparisons
  my @row_strings=map {lc join($;,@$_)} @$rows;
  my %seen;
  my @uniq_rows;
  for(my $i=0; $i<@$rows; $i++) {
    my $row_string=$row_strings[$i];
    push(@uniq_rows,$rows->[$i]) unless $seen{$row_string}++;
  }
  # $uniq_rows;
  wantarray? @uniq_rows: \@uniq_rows;
}
# NG 13-06-21: moved from 050/translate.pm and renamed from grep_table
sub grep_rows {
  my($table,$col,$ids)=@_;
  my $pattern=join('|',map {"\^$_\$"} @$ids);
  $pattern=qr/$pattern/;
  [grep {$_->[$col]=~/$pattern/} @$table];
}
# NG 13-06-19: sort arrays of names, typically output subsets produced by power_set
# NG 13-07-16: renamed 
sub sort_rows {
  sort {@$a<=>@$b || first {$_} map {$a->[$_] cmp $b->[$_]} 0..$#$a} @_;
}
# make SQL IN clauses for test queries. 
# arguments are 1) single value, 2) ARRAY of values, or 3) column=>values pairs
sub sql_in {
  my $sql;
  if (@_==1) {
    my @values=flatten(shift);
    $sql='IN ('.join(',',map {"'$_'"} @values).')';
  } else {
    my %args=@_;
    my @sql;
    while (my($column,$values)=each %args) {
      my @values=flatten($values);
      push(@sql,"$column IN (".join(',',map {"'$_'"} @values).')');
    }
    $sql=join(' AND ',@sql);
  }
  $sql;
}

# process filters ARRAY - a bit hacky 'cuz filter=>undef not same as filter=>[undef]
sub filters_array {
  my @filters=@{$_[0]};
  my(%filters,%filter_undef);
  # code adapted from Hash::AutoHash::MultiValued
  while (@filters>1) { 
    my($key,$value)=splice @filters,0,2; # shift 1st two elements
    if (defined $value || $filter_undef{$key}) { 
      # store value if defined or key has multiple occurrences of undef
      my $list=$filters{$key}||($filters{$key}=[]);
      if (defined $value) {
	push(@$list,$value) unless ref $value;
	push(@$list,@$value) if ref $value;
      }
    } else {
      $filter_undef{$key}++;
    }}
  # add the undefs to %filters
  for my $key (keys %filter_undef) {
    my $list=$filters{$key};
    if (defined $list) {
      push(@$list,undef);
    } else {
      $filters{$key}=undef;
    }
   }
  \%filters;
}

# NG 12-09-04: separated ur sanity tests from real tests
sub select_ur_sanity {
  my $args=new Hash::AutoHash::Args(@_);
  my($babel,$urname,$output_idtypes)=@$args{qw(babel urname output_idtypes)};
  my @output_idtypes=map {ref $_? $_->name: $_} @$output_idtypes;

  my $dbh=$babel->autodb->dbh;
  my $columns=join(', ',@output_idtypes);
  my $sql=qq(SELECT DISTINCT $columns FROM $urname);
  my $table=$dbh->selectall_arrayref($sql);

  # remove NULL rows (probably aren't any)
  @$table=grep {my @row=@$_; grep {defined $_} @row} @$table;
  $table;
}
# NG 12-09-23: added count_ur. simple wrapper around select_ur
sub count_ur {
  my $table=select_ur(@_);
  scalar @$table;
}
# NG 12-11-18: check that table exists and is non-empty
sub check_table {
  my($babel,$table,$label)=@_;
  my $dbh=$babel->autodb->dbh;
  my $ok=1;
  my $sql=qq(SHOW TABLES LIKE '$table');
  my $tables=$dbh->selectcol_arrayref($sql);
  $ok&&=report_fail(!$dbh->err,"$label database query failed: ".$dbh->errstr) or return 0;
  $ok&&=report_fail(scalar @$tables,"$label table $table does not exist") or return 0;
  $ok&&=cmp_quietly($tables,[$table],"$label SHOW TABLES got incorrect result") or return 0;
  my $sql=qq(SELECT COUNT(*) FROM $table);
  my($count)=$dbh->selectrow_array($sql);
  $ok&&=report_fail(!$dbh->err,"$label database query failed: ".$dbh->errstr) or return 0;
  report_fail($count,"$label table $table is empty");
}
# NG 12-11-18: check database for sanity
sub check_database_sanity {
  my($babel,$label,$num_maptables)=@_;
  my $ok=1;
  $ok&&=check_maptables_sanity($babel,"$label check maptables",$num_maptables);
  $ok&&=check_masters_sanity($babel,"$label check masters");
  $ok;
}

# NG 12-11-18: check maptables for sanity
sub check_maptables_sanity {
  my($babel,$label,$num_maptables)=@_;
  my $dbh=$babel->autodb->dbh;
  my $ok=1;
  my @maptables=@{$babel->maptables};
  $ok&&=
    is_quietly($num_maptables,scalar @maptables,"$label BAD NEWS: number of maptables wrong!!")
      or return 0;
  for my $table (map {$_->name} @maptables) {
    $ok&&=check_table($babel,$table,"$label MapTable $table");
  }
  $ok;
}
# NG 12-11-18: check master tables for sanity
sub check_masters_sanity {
  my($babel,$label)=@_;
  my $dbh=$babel->autodb->dbh;
  my $ok=1;
  my @maptables=@{$babel->maptables};
  for my $maptable (@maptables) {
    my $maptable_name=$maptable->name;
    my @idtypes=@{$maptable->idtypes};
    for my $idtype (@idtypes) {
      my $idtype_name=$idtype->name;
      my $master=$idtype->master;
      my $master_name=$master->name;
      $ok&&=is_quietly
	($master_name,"${idtype_name}_master", "$label BAD NEWS: master name wrong!!") 
	  or return 0;
      my $sql=qq(SELECT $idtype_name FROM $maptable_name WHERE $idtype_name NOT IN 
                  (SELECT $idtype_name FROM $master_name));
      my $missing=$dbh->selectcol_arrayref($sql);
      $ok&&=report_fail(!$dbh->err,"$label database query failed: ".$dbh->errstr) or return 0;
      $ok&&=report_fail(@$missing==0,"$label some ids in $maptable_name missing from $master_name; here are a few: ".join(', ',@$missing[0..2])) or return 0;
    }
  }
  $ok;
}

# cmp ARRAYs of Babel component objects (anything with an 'id' method will work)
# like cmp_bag but 
# 1) reports errors the way we want them
# 2) sorts the args to avoid Test::Deep's 'bag' which is ridiculously slow...
sub cmp_objects {
  my($actual,$correct,$label,$file,$line)=@_;
  my $ok=cmp_objects_quietly($actual,$correct,$label,$file,$line);
  report_pass($ok,$label);
}
sub cmp_objects_quietly {
  my($actual,$correct,$label,$file,$line)=@_;
  my @actual_sorted=sort {$a->id cmp $b->id} @$actual;
  my @correct_sorted=sort  {$a->id cmp $b->id} @$correct;
  cmp_quietly(\@actual_sorted,\@correct_sorted,$label,$file,$line);
}
# like cmp_bag but 
# 1) reports errors the way we want them
# 2) sorts the args to avoid Test::Deep's 'bag' which is ridiculously slow...
# NG 10-11-08: extend to test limit. CAUTION: limit should be small or TOO SLOW!
sub cmp_table {
  my($actual,$correct,$label,$file,$line,$limit)=@_;
  my $ok=cmp_table_quietly($actual,$correct,$label,$file,$line,$limit);
  report_pass($ok,$label);
}
# NG 13-06-10: added cmp_table_nocase for case insensitive comparisons, eg,
#   searching for 'htt' as gene_symbol
sub cmp_table_nocase {
  my($actual,$correct,$label,$file,$line,$limit)=@_;
  my @actual=map {_lc_row($_)} @$actual;
  my @correct=map {_lc_row($_)} @$correct;
  my $ok=cmp_table_quietly(\@actual,\@correct,$label,$file,$line,$limit);
  report_pass($ok,$label);
}
sub _lc_row {
  my @row=@{$_[0]};
  @row=map {lc($_)} @row;
  \@row;
}

sub cmp_table_quietly {
  my($actual,$correct,$label,$file,$line,$limit)=@_;
  unless (defined $limit) {
    my @actual_sorted=sort cmp_rows @$actual;
    my @correct_sorted=sort cmp_rows @$correct;
    # my $ok=cmp_quietly($actual,bag(@$correct),$label,$file,$line);
    return cmp_quietly(\@actual_sorted,\@correct_sorted,$label,$file,$line);
  } else {
    my $correct_count=min(scalar(@$correct),$limit);
    report_fail(@$actual==$correct_count,
		"$label: expected $correct_count row(s), got ".scalar @$actual,$file,$line)
      or return 0;
    return cmp_quietly($actual,subbagof(@$correct),$label,$file,$line);
  }
  1;
}
# cmp_op & cmp_op_quietly used for merged translate/count tests
# $actual can be table or count
# $correct always table
# $op is 'translate' or 'count'
sub cmp_op {
  my($actual,$correct,$op,$label,$file,$line,$limit)=@_;
  if ($op eq 'translate') {
    cmp_table($actual,$correct,$label,$file,$line,$limit);
  } elsif ($op eq 'count') {
    $correct=@$correct;
    $correct=min($correct,$limit) if defined $limit;
    my($ok,$details)=cmp_details($actual,$correct);
    report($ok,$label,$file,$line,$details);
  } else {
    confess "Unknow op $op: should be 'translate' or 'count'";
  }
}

sub cmp_op_quietly {
  my($actual,$correct,$op,$label,$file,$line,$limit)=@_;
  if ($op eq 'translate') {
    cmp_table_quietly($actual,$correct,$label,$file,$line,$limit);
  } elsif ($op eq 'count') {
    $correct=@$correct;
    $correct=min($correct,$limit) if defined $limit;
    cmp_quietly($actual,$correct,$label,$file,$line);
  } else {
    confess "Unknow op $op: should be 'translate' or 'count'";
  }
}
# used by big IN tests, because cmp_op way too slow. assumes $correct bigger than $actual
# quiet, even though name doesn't say so
sub cmp_op_quickly {
  my($actual,$correct,$op,$label,$file,$line,$limit)=@_;
  my $correct_count=defined $limit? min(@$correct,$limit): @$correct;
  if ($op eq 'count') {
    return cmp_quietly($actual,$correct_count,$label,$file,$line);
  } elsif ($op eq 'translate') {
    my $actual_count=@$actual;
    my $ok=cmp_quietly($actual_count,$correct_count,$label,$file,$line) or return 0;
    my %correct=map {join($;,@$_)=>1} @$correct;
    my @actual=map {join($;,@$_)} @$actual;
    my @bad=grep {!$correct{$_}} @actual;
    return 1 unless @bad;
    ($file,$line)=called_from($file,$line);
    fail($label);
    diag("from $file line $line") if defined $file;
    diag('actual has ',scalar(@bad),' row(s) that are not in correct',"\n",
	 'sorry I cannot provide details...');
    return 0;
  } else {
    confess "Unknown op $op: should be 'translate' or 'count'" ;
  }
}
# sort subroutine: $a, $b are ARRAYs of strings. should be same lengths. cmp element by element
sub cmp_rows {
  my $ret;
  for (0..$#$a) {
    return $ret if $ret=$a->[$_] cmp $b->[$_];
  }
  # equal up to here. if $b has more, then $a is smaller
  $#$a <=> $#$b;
}
# NG 13-06-12: construct pre-order traversal of schema 'table-graph';
sub order_tables {
  my($babel)=@_;
  my $graph=new Graph::Undirected;
  my @tables=@{$babel->maptables};
  for my $table (@tables) {
    my @idtypes=@{$table->idtypes};
    my @neighbors=grep {$_!=$table} map {@{$_->maptables}} @idtypes;
    my $me=$table->name;
    map {$graph->add_edge($me,$_->name)} @neighbors;
  }
  my $tree=$graph->minimum_spanning_tree;
  # now do a pre-order traversal, eg, depth-first
  my @nodes=$tree->vertices;
  my %avbl=map {$_=>1} @nodes;
  my @future=$nodes[0];
  my @traversal;
  while (@future) {
    my $node=shift @future;
    next unless $avbl{$node};	# don't process if already visited
    push(@traversal,$node);
    $avbl{$node}=0;		# mark as visited
    push(@future,grep {$avbl{$_}} $tree->neighbors($node));
  }
  wantarray? @traversal: \@traversal;
}
# emulate natural full outer join. return result table
# $result is optional name of result table. if not set, unique name generated
# TODO: add option to delete intermediate tables as we go.
sub full_join {
  my($babel,$left,$right,$resultname,$column2type)=@_;
  my $leftname=$left->tablename;
  my $rightname=$right->tablename;
 # left is usually t::FullOuterJoinTable but can be MapTable or Master
  my @column_names=
    $left->isa('t::FullOuterJoinTable')? @{$left->column_names}: map {$_->name} @{$left->idtypes};
  # right is always MapTable or Master
  push(@column_names,map {$_->name} @{$right->idtypes});
  # NG 12-11:18: added histories
  push(@column_names,'_X_'.$left->idtype->name)
    if $left->isa('Data::Babel::Master') && $left->history;
  push(@column_names,'_X_'.$right->idtype->name)
    if $right->isa('Data::Babel::Master') && $right->history;

  @column_names=uniq(@column_names);
  my @column_defs=map {$_.' '.$column2type->{$_}} @column_names;
  my $column_names=join(', ',@column_names);
  my $column_defs=join(', ',@column_defs);
  
  my $result=new t::FullOuterJoinTable(name=>$resultname,column_names=>\@column_names);
  $resultname=$result->tablename;
  # code adapted from MainData::LoadData Step
  my $dbh=$babel->autodb->dbh;
  $dbh->do(qq(DROP TABLE IF EXISTS $resultname));
  my $column_list=join(', ',@column_defs);
  my $query=qq
    (SELECT $column_names FROM $leftname NATURAL LEFT OUTER JOIN $rightname
     UNION
     SELECT $column_names FROM $leftname NATURAL RIGHT OUTER JOIN $rightname);
  $dbh->do(qq(CREATE TABLE $resultname ($column_list) AS\n$query));
  $result;
}
# drop all tables and views associated with Babel tests
#   arg is generally AutoDB
#   do at start, rather than end, to leave bread crumbs for post-run debugging
sub cleanup_db {
  my($autodb,$keep_ur)=@_;
  my $dbh=$autodb->dbh;
  my @tables=(@{$dbh->selectcol_arrayref(qq(SHOW TABLES LIKE '%maptable%'))},
	      @{$dbh->selectcol_arrayref(qq(SHOW TABLES LIKE '%master%'))});
  map {$dbh->do(qq(DROP TABLE IF EXISTS $_))} @tables;
  map {$dbh->do(qq(DROP VIEW IF EXISTS $_))} @tables;
  cleanup_ur($dbh) unless $keep_ur;
}
# arg is dbh, autodb, or babel. clean up intermediate tables created en route to ur
sub cleanup_ur {t::FullOuterJoinTable->cleanup(@_) }

########################################
# these functions test our 'standard' hand-crafted Babel & components

sub check_handcrafted_idtypes {
  my($actual,$mature,$label)=@_;
  $label or $label='idtypes'.($mature? ' (mature)': '');
  my $num=4;
  my $class='Data::Babel::IdType';
  report_fail(@$actual==$num,"$label: number of elements") or return 0;
  my @actual=sort_objects($actual,$label) or return 0;
  for my $i (0..$#actual) {
    my $actual=$actual[$i];
    my $suffix='00'.($i+1);
    report_fail(UNIVERSAL::isa($actual,$class),"$label object $i: class") or return 0;
    report_fail($actual->name eq "type_$suffix","$label object $i: name") or return 0;
    report_fail($actual->id eq "idtype:type_$suffix","$label object $i: id") or return 0;
    report_fail($actual->display_name eq "display_name_$suffix",
		"$label object $i: display_name") or return 0;
    report_fail($actual->referent eq "referent_$suffix","$label object $i: referent") or return 0;
    report_fail($actual->defdb eq "defdb_$suffix","$label object $i: defdb") or return 0;
    report_fail($actual->meta eq "meta_$suffix","$label object $i: meta") or return 0;
    report_fail($actual->format eq "format_$suffix","$label object $i: format") or return 0;
    report_fail($actual->sql_type eq "VARCHAR(255)","$label object $i: sql_type") or return 0;
    report_fail(as_bool($actual->internal)==0,"$label object $i: internal") or return 0;
    report_fail(as_bool($actual->external)==1,"$label object $i: external") or return 0;
    if ($mature) {
      my $babel=$actual->babel;
      check_object_basics($babel,'Data::Babel','test',"$label object $i babel");
      check_object_basics($actual->master,'Data::Babel::Master',
			  "type_${suffix}_master","$label object $i master");
      # NG 13-09-24: added tests for maptables
      my $maptables=$actual->maptables;
      map {isa_ok_quietly($_,'Data::Babel::MapTable',"$label object $i maptable")} @{$maptables}
	or return 0;
      my @correct_maptables=
	($suffix eq '001'? map {$babel->name2maptable("maptable_$_")} qw(001):
	 ($suffix eq '002'? map {$babel->name2maptable("maptable_$_")} qw(001 002): 
	  ($suffix eq '003'? map {$babel->name2maptable("maptable_$_")} qw(002 003): 
	   ($suffix eq '004'? map {$babel->name2maptable("maptable_$_")} qw(003):
	    confess "Unexpected suffix $suffix"))));
      cmp_bag_quietly($maptables,\@correct_maptables,"$label object $i maptables") or return 0;
    }
  }
  pass($label);
}

# masters 2&3 are implicit, hence some of their content is special
# NG 10-11-10: implicit Masters now have clauses to exclude NULLs in their queries
sub check_handcrafted_masters {
  my($actual,$mature,$label)=@_;
  $label or $label='masters'.($mature? ' (mature)': '');
  my $num=$mature? 4: 2;
  my $class='Data::Babel::Master';
  report_fail(@$actual==$num,"$label: number of elements") or return 0;
  my @actual=sort_objects($actual,$label) or return 0;
  for my $i (0..$#actual) {
    my $actual=$actual[$i];
    my $suffix='00'.($i+1);
    my $name="type_${suffix}_master";
    my $id="master:$name";
    # NG 13-09-02: DEPRECATED workflow related attributes
    my($query,$view,$implicit);
    # masters 2&3 are implicit, hence some of their content is special
    if ($i>=2) {
      $implicit=1; $query=1;
      if ($i==3) {
	$view=1;      
      }}
    isa_ok_quietly($actual,$class,"$label object $i: class") or return 0;
    report_fail($actual->name eq $name,"$label object $i: name") or return 0;
    report_fail($actual->id eq $id,"$label object $i: id") or return 0;
    report_fail(as_bool($actual->implicit)==$implicit,"$label object $i: implicit") or return 0;
    if ($mature) {
      report_fail(as_bool($actual->query)==$query,"$label object $i: query") or return 0;
      report_fail(as_bool($actual->view)==$view,"$label object $i: view") or return 0;
      check_object_basics($actual->babel,'Data::Babel','test',"$label object $i babel");
      check_object_basics($actual->idtype,'Data::Babel::IdType',
			  "type_$suffix","$label object $i idtype");
    }
  }
  pass($label);
}

sub check_handcrafted_maptables {
  my($actual,$mature,$label)=@_;
  $label or $label='maptables'.($mature? ' (mature)': '');
  my $num=3;
  my $class='Data::Babel::MapTable';
  report_fail(@$actual==$num,"$label: number of elements") or return 0;
  my @actual=sort_objects($actual,$label) or return 0;
  # NG 13-09-02: DEPRECATED workflow related attributes
  for my $i (0..$#actual) {
    my $actual=$actual[$i];
    my $suffix='00'.($i+1);
    my $suffix1='00'.($i+2);
    my $name="maptable_$suffix";
    my $id="maptable:$name";
    report_fail(UNIVERSAL::isa($actual,$class),"$label object $i: class") or return 0;
    report_fail($actual->name eq $name,"$label object $i: name") or return 0;
    report_fail($actual->id eq $id,"$label object $i: id") or return 0;
    # NG 13-06-12: compare as sets 'cuz perl 5.18 no longer preserves order
     if ($mature) {
      check_object_basics($actual->babel,'Data::Babel','test',"$label object $i babel");
      check_objects_basics($actual->idtypes,'Data::Babel::IdType',
			  ["type_$suffix","type_$suffix1"],"$label object $i idtypes");
    }
  }
  pass($label);
}

sub check_handcrafted_name2idtype {
  my($babel)=@_;
  my $label='name2idtype';
  my %name2idtype=map {$_->name=>$_} @{$babel->idtypes};
  for my $name (qw(type_001 type_002 type_003 type_004)) {
    my $actual=$babel->name2idtype($name);
    report_fail($actual==$name2idtype{$name},"$label: object $name") or return 0;
  }
  pass($label);
}
sub check_handcrafted_name2master {
  my($babel)=@_;
  my $label='name2master';
  my %name2master=map {$_->name=>$_} @{$babel->masters};
  for my $name (qw(type_001 type_002 type_003 type_004)) {
    my $actual=$babel->name2master($name);
    report_fail($actual==$name2master{$name},"$label: object $name") or return 0;
  }
  pass($label);
}
sub check_handcrafted_name2maptable {
  my($babel)=@_;
  my $label='name2maptable';
  my %name2maptable=map {$_->name=>$_} @{$babel->maptables};
  for my $name (qw(type_001 type_002 type_003 type_004)) {
    my $actual=$babel->name2maptable($name);
    report_fail($actual==$name2maptable{$name},"$label: object $name") or return 0;
  }
  pass($label);
}
sub check_handcrafted_id2object {
  my($babel)=@_;
  my $label='id2object';
  my @objects=(@{$babel->idtypes},@{$babel->masters},@{$babel->maptables});
  my %id2object=map {$_->id=>$_} @objects;
  my @ids=
    (qw(idtype:type_001 idtype:type_002 idtype:type_003 idtype:type_004),
     qw(master:type_001_master master:type_002_master master:type_003_master master:type_004_master),
     qw(maptable:maptable_001 maptable:maptable_002 maptable:maptable_003));
  for my $id (@ids) {
    my $actual=$babel->id2object($id);
    report_fail($actual==$id2object{$id},"$label: object $id") or return 0;
  }
  pass($label);
}
sub check_handcrafted_id2name {
  my($babel)=@_;
  my $label='id2name';
  my @ids=
    (qw(idtype:type_001 idtype:type_002 idtype:type_003 idtype:type_004),
     qw(master:type_001_master master:type_002_master master:type_003_master master:type_004_master),
     qw(maptable:maptable_001 maptable:maptable_002 maptable:maptable_003));
  my @names=
    (qw(type_001 type_002 type_003 type_004),
     qw(type_001_master type_002_master type_003_master type_004_master),
     qw(maptable_001 maptable_002 maptable_003));
  my %id2name=map {$ids[$_]=>$names[$_]} (0..$#ids);
  for my $id (@ids) {
    my $actual=$babel->id2name($id);
    report_fail($actual eq $id2name{$id},"$label: object $id") or return 0;
  }
  pass($label);
}

sub load_handcrafted_maptables {
  my($babel,$data)=@_;
  for my $name (qw(maptable_001 maptable_002 maptable_003)) {
    load_maptable($babel,$name,$data->$name->data);
  }
}
sub load_handcrafted_masters {
  my($babel,$data)=@_;
  # explicit masters
  for my $name (qw(type_001_master type_002_master)) {
    load_master($babel,$name,$data->$name->data);
  }
  # # NG 12-09-27. loop below no subsumed in load_implicit_masters
  # # implicit masters have no data
  # for my $name (qw(type_003_master type_004_master)) {
  #   load_master($babel,$name);
  # }
}
# NG 12-09-27: added load_implicit_masters and test below
# must be called after maptables loaded
sub check_implicit_masters {
  my($babel,$data,$label,$file,$line)=@_;
  my $dbh=$babel->dbh;
  my $ok=1;
  for my $master (grep {$_->implicit} @{$babel->masters}) {
    my $name=$master->name;
    my $correct=prep_tabledata($data->$name->data);
    my $actual=$dbh->selectall_arrayref(qq(SELECT * FROM $name));
    $ok&&=cmp_table_quietly($actual,$correct,"$label: $name",$file,$line);
  }
  report_pass($ok,$label);
}

########################################
# utility functions for history idtypes
# arg is IdType object or name
sub _has_history {
  my($babel,$idtype)=@_;
  ref $idtype or $idtype=$babel->name2idtype($idtype);
  $idtype->history;
}
# sub _history_name {
#   my($babel,$idtype)=@_;
#   ref $idtype and $idtype=$idtype->name;
#   "_X_$idtype";
# }

# debugging functions

# print names 
sub pnames {
  my $sep=shift;
  print join($sep,map {$_->name} @_);
}
# print graph, typically as sif
sub pgraph {
  my($graph,$file,$format)=@_;
  length($format)? $format=lc($format): ($format='sif');
  confess "Invalid format $format: must be sif or txt" unless $format=~/sif|txt/;
  if ($file) {
    open(OUT,'>',$file) || confess "Cannot create output file $file: $!";
  } else {
    *OUT=*STDOUT;
  }
  if ($format eq 'sif') {
    print OUT join("\n",map {my($v0,$v1)=@$_;"$v0 - $v1"} $graph->edges),"\n";
  } else {
    print OUT '  ',join("\n  ",map {_edge_str($graph,$_)} _sort_edges($graph->edges)),"\n";
  }
  close OUT if $file;
}
# # NG 13-10-05 print table dumps to track down FAILs seen by 
# #              David Cantrell (reports 34101829, 34102877)
# sub diag_rows {
#   my($rows)=@_;
#   my @diag='----------';
#   for my $row (@$rows) {
#     # replace undef by NULL
#     push(@diag,join("\t",map {defined $_? $_: 'NULL'} @$row));
#   }
#   push(@diag,'----------');
#   my $diag=join("\n",@diag);
#   diag($diag);
#   return 1;
# }
# # NG 13-09-15: print table dumps to track down FAILs seen by 
# #              David Cantrell (reports 34101829, 34102877)
# sub diag_table {
#   my($table,@cols)=@_;
#   my $cols=@cols? join(',',@cols): '*';
#   my $sth=$dbh->prepare(qq(SELECT $cols FROM $table)) or goto FAIL;
#   $sth->execute() or goto FAIL;
#   my @cols=@{$sth->{NAME}};
#   my $rows=$sth->fetchall_arrayref() or goto FAIL;
#   my @diag=("table $table:",join("\t",@cols));
#   for my $row (@$rows) {
#     # replace undef by NULL
#     push(@diag,join("\t",map {defined $_? $_: 'NULL'} @$row));
#   }
#   push(@diag,'----------');
#   my $diag=join("\n",@diag);
#   diag($diag);
#   return 1;
#  FAIL:
#   fail("dump table $table");
#   diag("While trying to dump table $table for diagnostic purposes, we got the following DBI error message\n".DBI->errstr);
#   return 0;
# }
1;

package t::FullOuterJoinTable;
# simple class to represent intermediate tables used to emulate full outer joins
use strict;
use Carp;
use Class::AutoClass;
use vars qw(@AUTO_ATTRIBUTES @OTHER_ATTRIBUTES @CLASS_ATTRIBUTES %SYNONYMS %DEFAULTS);
use base qw(Class::AutoClass);

@AUTO_ATTRIBUTES=qw(name column_names);
@OTHER_ATTRIBUTES=qw(seqnum);
@CLASS_ATTRIBUTES=qw();
%SYNONYMS=(tablename=>'name',columns=>'column_names');
%DEFAULTS=(column_names=>[]);
Class::AutoClass::declare;

our $seqnum=0;
sub seqnum {shift; @_? $seqnum=$_[0]: $seqnum}

sub _init_self {
  my($self,$class,$args)=@_;
  return unless $class eq __PACKAGE__; # to prevent subclasses from re-running this
  my $name=$self->name || $self->name('fulljoin_'.sprintf('%03d',++$seqnum));
}
sub cleanup {
  my($class,$obj)=@_;
  my $dbh;
  if (ref $obj) {$dbh=$obj->isa('DBI::db')? $obj: $obj->dbh;}
  else {$dbh=Data::Babel->autodb->dbh;}

  # drop all tables that look like our intermediates
  my @tables=@{$dbh->selectcol_arrayref(qq(SHOW TABLES LIKE 'fulljoin_%'))};
  # being a bit paranoid, make sure each table ends with 3 digits
  @tables=grep /\d\d\d$/,@tables;
  map {$dbh->do(qq(DROP TABLE IF EXISTS $_))} @tables;

  # drop ur
  $dbh->do(qq(DROP TABLE IF EXISTS ur));
}
1;
