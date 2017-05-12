########################################
# 030.mechanics -- make sure some SQL works
########################################
use t::lib;
use t::utilBabel;
use filter_object;
use Carp;
use Class::AutoDB;
use File::Spec;
use Test::Deep;
use Test::More;
use Data::Babel;
use Data::Babel::Filter;
use strict;

# only works for even, odd - database loading code assumes ur has 6 columns
# easily fixed if desired
#
for $history (qw(none all even odd)) {
  init($history);
  my $ncols=4+scalar(grep {$_->history} @{$babel->idtypes});
  # create data & load database
  # one row for each standard id (all columns) plus one row with standard id + suffix
  # just load ur - no need for maptables, masters, etc.
  my @values=map {join(', ',($dbh->quote($_)) x $ncols),
		    join(', ',($dbh->quote("$_ XXX")) x $ncols)} @ids;
  my $values=join(",\n",map {"($_)"} @values);
  # one column's worth of data - test code greps this as needed to get 'correct'
  my @idsxxx=map {$_,"$_ XXX"} @ids;
  $dbh->do(qq(INSERT INTO ur VALUES\n$values));
  ok(!$dbh->errstr,'load data');
  diag('database error message: ',$dbh->errstr) if $dbh->errstr;

  ## test conditions of increasing complexity
  ## '' 
  my $label="empty string - history=$history"; 
  my $id='';
  my $ok=test_sql($id,[],$label);
  report_pass($ok,$label);

  ## \''
  my $label="empty SQL - history=$history"; 
  my $sql=\'';
  my $ok=test_sql($sql,[],$label);
  report_pass($ok,$label);
  
  ## []
  my $label="empty array - history=$history"; 
  my $id=[];
  my $ok=test_sql($id,[],$label);
  report_pass($ok,$label);
  
  ## undef
  my $label="undef - history=$history"; 
  my $id=undef;
  my $ok=test_sql($id,\@idsxxx,$label);
  report_pass($ok,$label);

  ## id
  my $ok=1;
  my $label="id - history=$history";
  while (my($label,$id)=each %ids) {
    # my $qid=$dbh->quote($id);
    $label="id=$label - history=$history";
    $ok&&=test_sql($id,[$id],$label);
  }
  my $in=join(',',@qids);
  $ok&&=test_sql(\@ids,\@ids,"ARRAY of multiple ids");
  report_pass($ok,$label);

  ## simple SQL
  my $ok=1;
  while (my($label,$id)=each %ids) {
    my $qid=$dbh->quote($id);
    $label="simple SQL - LIKE $label - history=$history";
    $ok&&=test_sql(\"LIKE $qid",[$id],$label);
  }
  while (my($label,$id)=each %ids) {
    my $qid=$dbh->quote("$id%");
    $label="simple SQL - LIKE $label% - history=$history";
    $ok&&=test_sql(\"LIKE $qid",[$id,"$id XXX"],$label);
  }
  # do it with ARRAY of everything
  my $array=[map {my $qid=$_; \"LIKE $qid"} @qids];
  $ok&&=test_sql($array,\@ids,"ARRAY of multiple LIKEs");
  my $array=[map {my $qid=$dbh->quote("$_%"); \"LIKE $qid"} @ids];
  $ok&&=test_sql($array,\@idsxxx,"ARRAY of multiple LIKE%s");
  report_pass($ok,$label);

  ## Filter object
  my $ok=1;
  my $label="Filter object - history=$history";
  my $id=$ids[0];
  my $qid=$dbh->quote($id);
  my $object=new Data::Babel::Filter
    (babel=>$babel,filter_idtype=>'type_0',conditions=>\"LIKE $qid");
  $label="Filter object - history=$history";
  $ok&&=test_sql($object,[$id],$label);
  # do with ARRAY of everything. uses @ids, @qids, $array, $in from paragraphs above
  push(@$array,@ids,$object);
  $ok&&=test_sql($array,\@idsxxx,"ARRAY of multiple simple SQL fragments, object, ids");
  report_pass($ok,$label);

  ## simple SQL with embedded default idtype
  my $ok=1;
  my $label="simple SQL with embedded default idtype - history=$history";
  while (my($label,$id)=each %ids) {
    my $qid=$dbh->quote($id);
    $label="embedded default idtype - : LIKE $label - history=$history";
    $ok&&=test_sql(\": LIKE $qid",[$id],$label);
  }
  # do it with ARRAY of everything
  my $array=[map {my $qid=$_; \": LIKE $qid"} @qids];
  $ok&&=test_sql($array,\@ids,
	      "ARRAY of multiple simple SQL fragments with embeddd default idtype");
  report_pass($ok,$label);

  ## more complex SQL with embedded default idtype
  my $ok=1;
  my $label="more complex SQL with embedded default idtype - history=$history";
  my $op0='LIKE'; my $op1='!=';
  while (my($label,$id)=each %ids) {
    my $qid0=$dbh->quote("$id%");
    my $qid1=$dbh->quote($id);
    my $condition=": $op0 $qid0 AND : $op1 $qid1";
    $label="embedded default idtype 2 - : $op0 AND : $op1 $label - history=$history";
    $ok&&=test_sql(\$condition,["$id XXX"],$label);
  }
  # do it with ARRAY of everything
  my $array=[map {my $qid0=$dbh->quote("$_%"); my $qid1=$dbh->quote($_);
		  \": $op0 $qid0 AND : $op1 $qid1"} @ids];
  my @correct=grep /XXX$/,@idsxxx;
  $ok&&=
    test_sql($array,\@correct,"ARRAY of multiple SQL fragments with embedded default idtype");
  report_pass($ok,$label);

  ## more complex SQL with embedded idtypes
  my $ok=1;
  my $label="more complex SQL with embedded idtype - history=$history";
  my $op0='LIKE'; my $op1='!=';
  while (my($label,$id)=each %ids) {
    my $qid0=$dbh->quote("$id%");
    my $qid1=$dbh->quote($id);
    my $condition=":type_0 $op0 $qid0 AND :type_1 $op1 $qid1";
    $ok&&=test_sql(\$condition,["$id XXX"],$label);
  }
  # do it with ARRAY of everything
  my $array=[map {my $qid0=$dbh->quote("$_%"); my $qid1=$dbh->quote($_);
		  \":type_0 $op0 $qid0 AND :type_1 $op1 $qid1"} @ids];
  my @correct=grep /XXX$/,@idsxxx;
  $ok&&=test_sql($array,\@correct,"ARRAY of multiple SQL fragments with embedded idtypes");
  report_pass($ok,$label);
 
  ## even more complex SQL with embedded idtypes
  my $ok=1;
  my $label="even more complex SQL with embedded idtype - history=$history";
  my $op0='LIKE'; my $op1='NOT LIKE'; my $op2='!='; my $op3='LIKE';
  while (my($label,$id)=each %ids) {
    my $qid0=$dbh->quote("$id%");
    my $qid1=$dbh->quote($id);
    my $qid2=$dbh->quote("$id XXX");
    my $qid3=$dbh->quote("$id%");
    my $condition=
      qq{:type_0 $op0 $qid0 AND :type_1 $op1 $qid1 OR (:type_2 $op2 $qid2 AND (:type_3 $op3 $qid3))};
    $ok&&=test_sql(\$condition,[$id,"$id XXX"],$label);
  }
  # do it with ARRAY of everything
  my $array=
    [map {my $qid0=$dbh->quote("$_%");
	  my $qid1=$dbh->quote($_);
	  my $qid2=$dbh->quote("$_ XXX");
	  my $qid3=$dbh->quote("$_%");
	  \qq{:type_0 $op0 $qid0 AND :type_1 $op1 $qid1 OR (:type_2 $op2 $qid2 AND (:type_3 $op3 $qid3))};
	} @ids];
  $ok&&=test_sql($array,\@idsxxx,$label);
  report_pass($ok,$label);
}
done_testing();
