use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 26;
}
use DBIx::DBStag;
use FileHandle;
use strict;

my $dbh = DBIx::DBStag->new;

if (1) {
    my $sql =
      q[
 SELECT avg(abs(exon.start-exon.end)) AS av FROM x
      ];
    
    my $s = $dbh->parser ->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 1);
    ok($cols[0]->get_alias eq 'av');
    my $f = $s->get_from;
    my @tbls = sort map {$_->get_name} $f->find_leaf;
    print "T=@tbls\n";
    ok("@tbls" eq "x");
}

if (1) {
    my $sql =
      q[
 SELECT avg(abs(y)) AS av FROM x
      ];
    
    my $s = $dbh->parser ->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 1);
    ok($cols[0]->get_alias eq 'av');
    my $f = $s->get_from;
    my @tbls = sort map {$_->get_name} $f->find_leaf;
    print "T=@tbls\n";
    ok("@tbls" eq "x");
}

if (1) {
    my $sql =
      q[
 SELECT * FROM   f_type NATURAL JOIN featureloc   INNER JOIN feature_relationship ON (f_type.feature_id = objfeature_id)    NATURAL LEFT OUTER JOIN dbxref   WHERE name = 'CG17018'
      ];
    
    my $s = $dbh->parser ->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 1);
    ok($cols[0]->get_name eq '*');
    my $f = $s->get_from;
    my @tbls = sort map {$_->get_name} $f->find_leaf;
    print "T=@tbls\n";
    ok(@tbls == 4);
}
if (1) {
    my $sql =
      q[
	SELECT *
	FROM
	dna     INNER JOIN    contig  USING (dna_id)
        NATURAL JOIN z
	WHERE   contig_id = 5

       ];
    
    my $s = $dbh->parser ->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 1);
    ok($cols[0]->get_name eq '*');
    my $f = $s->get_from;
    my @tbls = sort map {$_->get_name} $f->find_leaf;
    print "T=@tbls\n";
    ok(@tbls == 3);
}
if (1) {
    my $sql =
      q[
	SELECT *
	FROM
	dna     INNER JOIN    contig      USING (dna_id)
	INNER JOIN    clone       USING (clone_id)

	WHERE   contig_id = 5

       ];
    
    my $s = $dbh->parser ->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 1);
    ok($cols[0]->get_name eq '*');
    my $f = $s->get_from;
    my @tbls = sort map {$_->get_name} $f->find_leaf;
    print "T=@tbls\n";
    ok(@tbls == 3);
}
if (1) {
    my $sql =
      q[
	SELECT * FROM x NATURAL JOIN y
       ];
    
    my $s = $dbh->parser->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 1);
    ok($cols[0]->get_name eq '*');
    my $f = $s->get_from;
    my @tbls = sort map {$_->get_name} $f->find_leaf;
    print "@tbls\n";
    ok("@tbls" eq "x y");
}
if (1) {
    my $sql =
      q[
	SELECT a, b AS y FROM x
       ];
    
    my $s = $dbh->parser->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 2);
    ok($cols[0]->get_name eq 'a');
    my $f = $s->get_from;
}
if (1) {
    my $sql =
      q[
	SELECT somefunc(x.foo), func2(bar), func3(y) AS r FROM x
       ];
    
    my $s = $dbh->parser->selectstmt($sql);
    print $s->sxpr; 
    my @cols = $s->get_cols->get_col;
    ok(@cols == 3);
    ok($cols[0]->get_func->get_name eq 'somefunc');
    ok($cols[0]->get_func->get_args->get_col->get_name eq 'x.foo');
    ok($cols[1]->get_func->get_args->get_col->get_name eq 'bar');
}
if (0) {

    # TODO - expressions
    my $sql =
      q[
	SELECT 5+3 FROM x
       ];
    
    my $s = $dbh->parser->selectstmt($sql);
#    print $s->sxpr; 
}

if (1) {
    my $sql =
      q[
SELECT 
  transcript.name, transcript_loc.nbeg, transcript_loc.nend, exon.name, exon_loc.nbeg, exon_loc.nend 
FROM
  feature_relationship INNER JOIN 
  f_type AS transcript ON (feature_relationship.subjfeature_id = transcript.feature_id)
  INNER JOIN featureloc AS transcript_loc ON (transcript_loc.feature_id = transcript.feature_id)
  INNER JOIN f_type AS exon ON (feature_relationship.objfeature_id = exon.feature_id)
  INNER JOIN featureloc AS exon_loc ON (exon_loc.feature_id = exon.feature_id)
WHERE 
  transcript.type = 'transcript' AND
  exon.type = 'exon' AND
  transcript.name = 'CG12345-RA';
       ];
    
    my $s = $dbh->parser->selectstmt($sql);
    print $s->sxpr; 
    ok(1);
}
if (1) {
    my $sql =
      q[
        SELECT 
          F1.feature_id, F1.dbxrefstr, FL1.nbeg, FL1.nend
        FROM 
        feature AS F2 
          INNER JOIN 
        featureloc AS FL2 ON (F2.feature_id = FL2.feature_id),
        feature AS F1 
         INNER JOIN 
        featureloc AS FL1 ON (F1.feature_id = FL1.feature_id) 
        WHERE 
        FL1.nbeg >= FL2.nbeg AND FL1.nend <= FL2.nend
        and F2.feature_id = 47 and FL2.srcfeature_id =
        FL1.srcfeature_id and F1.dbxrefstr != '';
       ];
#      q[
#        SELECT 
#          F1.feature_id, F1.dbxrefstr, FL1.nbeg, FL1.nend
#        FROM 
#        feature  F2 
#          INNER JOIN 
#        featureloc FL2 ON(F2.feature_id = FL2.feature_id),
#        feature F1 
#         INNER JOIN 
#        featureloc FL1 ON (F1.feature_id = FL1.feature_id) 
#        WHERE 
#        FL1.nbeg >= FL2.nbeg AND FL1.nend <= FL2.nend
#        and F2.feature_id = 47 and FL2.srcfeature_id =
#        FL1.srcfeature_id and F1.dbxrefstr != '';
#       ];
    
    my $s = $dbh->parser->selectstmt($sql);
    print $s->sxpr; 
    ok(1);
}
