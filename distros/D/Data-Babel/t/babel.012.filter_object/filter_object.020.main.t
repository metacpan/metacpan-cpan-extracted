########################################
# 016.filter_objects -- test Data::Babel::Filter
# don't worry about use of filters in 'translate' - tested separately
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

# $history declared in filter_object
for $history (qw(none all even odd)) {
  init($history);
  my($col0,$col1,$col2,$col3)=map {colname($_)} 0..3;
  ## test conditions of increasing complexity
  ## '' 
  my $label="empty string - history=$history"; 
  my $id='';
  my $qid=$dbh->quote($id);
  my $correct=qq($col0=$qid);
  my $ok=test_filter($id,$correct,$label);
  report_pass($ok,$label);

  ## \''
  my $label="empty SQL - history=$history"; 
  my $sql=\'';
  my $ok=test_filter($sql,qq(FALSE),$label);
  report_pass($ok,$label);
  
  ## []
  my $label="empty array - history=$history"; 
  my $id=[];
  my $ok=test_filter($id,qq(FALSE),$label);
  report_pass($ok,$label);
  
  ## undef
  my $label="undef - history=$history"; 
  my $id=undef;
  my $ok=test_filter($id,qq($col0 IS NOT NULL),$label,undef,qq($col0 IS NULL));
  report_pass($ok,$label);
 
  ## id
  my $ok=1;
  my $label="id - history=$history";
  while (my($label,$id)=each %ids) {
    my $qid=$dbh->quote($id);
    my $correct=qq($col0=$qid);
    $label="id=$label - history=$history";
    $ok&&=test_filter($id,$correct,$label);
  }
  my $in=join(',',@qids);
  my $correct=qq($col0 IN ($in));
  $ok&&=test_filter(\@ids,$correct,"ARRAY of multiple ids",0);
  report_pass($ok,$label);

  ## simple SQL
  my $ok=1;
  my $label="simple SQL - history=$history";
  for my $op (@ops) {
    while (my($label,$id)=each %ids) {
      my $qid=$dbh->quote($id);
      my $correct=qq($col0 $op $qid);
      $label="simple SQL - $op $label - history=$history";
      $ok&&=test_filter(\"$op $qid",$correct,$label);
    }}
  # do it with ARRAY of everything
  my $array=[map {my $op=$_; map {my $qid=$_; \"$op $qid"} @qids} @ops];
  my $correct=
    join(' OR ',map {my $op=$_; map {my $qid=$_; "($col0 $op $qid)"} @qids} @ops);
  $ok&&=test_filter($array,$correct,"ARRAY of multiple simple SQL fragments",0);
  report_pass($ok,$label);

  ## Filter object
  my $ok=1;
  my $label="Filter object - history=$history";
  my $id='filter object';
  my $qid=$dbh->quote($id);
  my $object=new Data::Babel::Filter
    (babel=>$babel,filter_idtype=>'type_0',conditions=>\"LIKE $qid");
  my $correct=qq($col0 LIKE $qid);
  $label="Filter object - history=$history";
  $ok&&=test_filter($object,$correct,$label);
  # do with ARRAY of everything. uses @ids, @qids, $array, $in from paragraphs above
  push(@$array,@ids,$object);
  $correct=join(' OR ',
		(map {my $op=$_; map {my $qid=$_; "($col0 $op $qid)"} @qids} @ops),
		"($correct)",
		"($col0 IN ($in))");
  $ok&&=test_filter($array,$correct,"ARRAY of multiple simple SQL fragments, object, ids",0);
  report_pass($ok,$label);

  ## simple SQL with embedded default idtype
  my $ok=1;
  my $label="simple SQL with embedded default idtype - history=$history";
  while (my($label,$id)=each %ids) {
    my $op='LIKE';
    my $qid=$dbh->quote($id);
    my $correct=qq($col0 $op $qid);
    $label="embedded default idtype - : $op $label - history=$history";
    $ok&&=test_filter(\": $op $qid",$correct,$label);
  }
  # do it with ARRAY of everything
  my $array=[map {my $op=$_; map {my $qid=$_; \": $op $qid"} @qids} @ops];
  my $correct=
    join(' OR ',map {my $op=$_; map {my $qid=$_; "($col0 $op $qid)"} @qids} @ops);
  $ok&&=test_filter($array,$correct,
	      "ARRAY of multiple simple SQL fragments with embeddd default idtype",0);
  report_pass($ok,$label);

  ## more complex SQL with embedded default idtype
  my $ok=1;
  my $label="more complex SQL with embedded default idtype - history=$history";
  my $op0='LIKE'; my $op1='!=';
  while (my($label,$id)=each %ids) {
    my $qid=$dbh->quote($id);
    my $condition=": $op0 $qid AND : $op1 $qid";
    my $correct=qq($col0 $op0 $qid AND $col0 $op1 $qid);
    $label="embedded default idtype 2 - : $op0 AND : $op1 $label - history=$history";
    $ok&&=test_filter(\$condition,$correct,$label);
  }
  # do it with ARRAY of everything
  my $array=[map {my $qid=$_; \": $op0 $qid AND : $op1 $qid"} @qids];
  my $correct=
    join(' OR ',map {my $qid=$_; "($col0 $op0 $qid AND $col0 $op1 $qid)"} @qids);
  $ok&&=
    test_filter($array,$correct,"ARRAY of multiple SQL fragments with embedded default idtype",0);
  report_pass($ok,$label);

  ## more complex SQL with embedded idtypes
  my $ok=1;
  my $label="more complex SQL with embedded idtype - history=$history";
  my $op0='LIKE'; my $op1='!=';
  while (my($label,$id)=each %ids) {
    my $qid=$dbh->quote($id);
    my $condition=":type_0 $op0 $qid OR :type_1 $op1 $qid";
    my $correct=qq($col0 $op0 $qid OR $col1 $op1 $qid);
    $ok&&=test_filter(\$condition,$correct,$label,undef,undef,[qw(type_0 type_1)]);
  }
  # do it with ARRAY of everything
  my $array=[map {my $op=$_; 
		  map {my $qid=$_; \":type_0 $op0 $qid AND :type_1 $op1 $qid"} @qids} @ops];
  my $correct=
    join(' OR ',map {my $op=$_; 
		     map {my $qid=$_; "($col0 $op0 $qid AND $col1 $op1 $qid)"} @qids} @ops);
  $ok&&=test_filter($array,$correct,"ARRAY of multiple SQL fragments with embedded idtypes 2",
	      0,undef,[qw(type_0 type_1)]);
  report_pass($ok,$label);
 
  ## even more complex SQL with embedded idtypes
  my $ok=1;
  my $label="even more complex SQL with embedded idtype - history=$history";
  my $op0='LIKE'; my $op1='!='; my $op2='>'; my $op3='NOT LIKE';
  while (my($label,$id)=each %ids) {
    my $qid=$dbh->quote($id);
    my $condition=
      qq{:type_0 $op0 $qid OR :type_1 $op1 $qid AND (:type_2 $op2 $qid OR (:type_3 $op3 $qid))};
    my $correct=
      qq{$col0 $op0 $qid OR $col1 $op1 $qid AND ($col2 $op2 $qid OR ($col3 $op3 $qid))};
    $label="complex SQL with embedded idtypes 4 - history=$history";
    $ok&&=test_filter(\$condition,$correct,$label,undef,undef,[qw(type_0 type_1 type_2 type_3)]);
  }
  # do it with ARRAY of everything
  my $array=
    [map {my $qid=$_; 
	  \qq{:type_0 $op0 $qid OR :type_1 $op1 $qid AND (:type_2 $op2 $qid OR (:type_3 $op3 $qid))};
	} @qids];
  my $correct=
    join(' OR ',
	 map {my $qid=$_; 
	      qq{($col0 $op0 $qid OR $col1 $op1 $qid AND ($col2 $op2 $qid OR ($col3 $op3 $qid)))};
	    } @qids);
  $ok&&=test_filter($array,$correct,"ARRAY of multiple SQL fragments with embedded idtypes 4",
		    0,undef,[qw(type_0 type_1 type_2 type_3)]);
  report_pass($ok,$label);
}
done_testing();
