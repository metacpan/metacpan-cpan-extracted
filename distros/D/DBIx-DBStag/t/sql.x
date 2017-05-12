use lib 't';

BEGIN {
    # to handle systems with no installed Test module
    # we include the t dir (where a copy of Test.pm is located)
    # as a fallback
    eval { require Test; };
    use Test;    
    plan tests => 1;
}
use DBIx::DBIStag;
use Data::Stag;
use FileHandle;
use Parse::RecDescent;

$::RD_AUTOACTION = q { [@item] };
#$::RD_TRACE = 1;
my $parser = Parse::RecDescent->new(selectgrammar());

#my $x = 
#  $parser->selectstmt(q[
#                        SELECT DISTINCT a, b, count(c) AS nn FROM (p NATURAL JOIN q) INNER JOIN y ON (x.a=y.b AND c=d AND f like y) WHERE r>7 or a like 't%' GROUP BY uu ORDER BY q, i LIMIT 20
#                       ]
#                     );


#my $x = $parser->bool_expr("a like 'b' or !(c != d)");
my $x = $parser->selectstmt(q[
    SELECT 
      srcseq.*,
      gene.*,
      transcript.*,
      exon.*
    FROM
      seq AS srcseq INNER JOIN
      seqfeature AS gene ON (gene.src_seq_id = srcseq.id) INNER JOIN 
        sf_produces_sf ON gene.id = produced_by_sf_id) INNER JOIN
          seqfeature AS transcript ON (transcript.id = produces_sf_id)
            INNER JOIN 
              exon_rank ON (transcript.id = transcript_sf_id) INNER JOIN
                seqfeature AS exon ON (exon.id = exon_sf_id)
    LIMIT 20
                             ]);;

#my $x = $parser->selectstmt(q[SELECT seqfeature.* FROM seqfeature LIMIT 10]);
use Data::Dumper;
#print Dumper $x;
print $x->sxpr;

sub selectgrammar {
    return DBIx::DBIStag->selectgrammar;
}
