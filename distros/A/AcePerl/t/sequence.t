#!/usr/local/bin/perl -w


# Tests of Ace::Sequence and Ace::Sequence::Feature
######################### We start with some black magic to print on failure.
use lib '..','../blib/lib','../blib/arch';
use constant HOST => $ENV{ACEDB_HOST} || 'aceserver.cshl.org';
use constant PORT => $ENV{ACEDB_PORT} || 2007;

BEGIN {$| = 1; print "1..54\n"; }
END {print "not ok 1\n" unless $loaded;}
use Ace::Sequence;
$loaded = 1;

print "ok 1\n";

######################### End of black magic.

sub test {
    local($^W) = 0;
    my($num, $true,$msg) = @_;
    print($true ? "ok $num\n" : "not ok $num $msg\n");
}

test(2,$db = Ace->connect(-host=>HOST,-port=>PORT,-timeout=>50),"connection failure");

# uncomment to use with SMap test database (only valid on Lincoln's test machine)
#test(2,$db = Ace->connect(-path=>'~acedb/tempdb'),"connection failure");

die "Couldn't establish connection to database.  Aborting tests.\n" unless $db;

# test whole clones
test(3,$clone = $db->fetch(Sequence=>'ZK154'),"fetch failure");

test(4,$zk154 = Ace::Sequence->new($clone),"new() failure");
test(5,$zk154->start==1,"start() failure");
test(6,$zk154->end==26547,"end() failure");

test(7,$zk154s = Ace::Sequence->new(-seq=>$clone,
				    -offset=>100,
				    -Length=>100),"new() failure");
test(8,$zk154s->start==101,"start() failure (2)");
test(9,$zk154s->end==200,"end() failure (2)");

test(10,$zk154s->length == 100,"length() failure");
test(11,length($zk154s->dna)==100,"dna() failure");

test(12,$zk154r = Ace::Sequence->new(-seq=>$clone,
				     -offset =>  100,
				     -Length => -100),"new() failure");
test(13,$zk154r->start==101,"start() failure (3)");
test(14,$zk154r->end==2,"end() failure (3)");
test(15,$zk154r->length == -100,"length() failure");
test(16,length($zk154r->dna) == 100,"dna() failure");
# print "ok 14 # Skip, persistent off-by-one errors\n";
# print "ok 15 # Skip, persistent off-by-one errors\n";
# print "ok 16 # Skip, persistent off-by-one errors\n";

@features = sort { $a->start <=> $b->start; }  $zk154->features('exon');

test(17,@features,'features() error');

test(18,$features[0]->start > 0,'features()->start error');
test(19,$features[0]->end-$features[0]->start +1 == $features[0]->length,'features()->end error');

test(20,$gff = $zk154->gff,'gff() error');

if (eval q{local($^W)=0; require GFF;}) {
#  print STDERR "Expect a seek() on unopened file error from GFF module...\n";
  test(21,$gff = $zk154->GFF,'GFF() error');
} else {
  print "ok 21 # Skip no GFF module installed\n";
}

# Test that we can do the same thing on forward and reverse predicted genes
test(22,$gene = $db->fetch(Predicted_gene=>'ZK154.1'),"fetch failure");
test(23,$zk154_1 = Ace::Sequence->new($gene),"new() failure");
test(24,$zk154_1->start > 0,"start() failure");
test(25,$zk154_1->length ==$zk154_1->end-$zk154_1->start+1,"length() failure");
@features = sort { $a->start <=> $b->start; }  $zk154_1->features('exon');
test(26,$features[0]->start == 1,'features() error');
test(27,$features[0]->end == 99,'features() error');
test(28,length($features[0]->dna) == 99,'dna() error');

# ZK154.3 is a reversed gene
test(29,$gene = $db->fetch(Predicted_gene=>'ZK154.3'),"fetch failure");
test(30,$zk154_3 = Ace::Sequence->new($gene),"new() failure");
test(31,$zk154_3->start > 0,"start() failure");
test(32,$zk154_3->end-$zk154_3->start+1 == $zk154_3->length,"length() failure");
@features = $zk154_3->features('exon');
@features = sort { $a->start <=> $b->start; }  @features;
test(33,$features[0]->start == 1,'features() error');
test(34,$features[0]->end == 57,'features() error');
test(35,length($features[0]->dna) == 57,'dna() error');

# test that relative offsets are working
$zk154 = Ace::Sequence->new(-seq=>$gene,-Length=>11);
$zk154_3 = Ace::Sequence->new(-seq=>$gene,-offset=>1,-Length=>10);
test(36,substr($zk154->dna,1,10) eq $zk154_3->dna,'offset error');


# Test that absolute coordinates are working
test(37,$zk154_3 = Ace::Sequence->new(-seq=>$gene,-refseq=>'CHROMOSOME_X'),'absolute coordinate error');
test(38,abs($zk154_3->end-$zk154_3->start) + 1 == 1596,'absolute coordinate error');
@features = sort {$b->start <=> $a->start } $zk154_3->features('exon');
test(39,@features,'absolute coordinate error');
test(40,abs($features[0]->end-$features[0]->start) + 1 == 57,'absolute coordinate error');
$features[0]->refseq('ZK154.3');
test(41,$features[0]->start  == 1,'absolute coordinate error');
test(42,$features[0]->end    == 57,'absolute coordinate error');
test(43,$features[0]->length == 57,'absolute coordinate error');

# Test the Ace::Sequence::Gene thing
$zk154 = Ace::Sequence->new(-seq=>'ZK154',-db=>$db);
@genes = $zk154->transcripts;
test(44,scalar(@genes),'gene fetch error');
$forward = (grep {$_->strand > 0} @genes)[0];
$reverse = (grep {$_->strand < 0} @genes)[0];
test(45,$forward && $reverse,'failed to find forward and reverse genes');
@exons1 = $forward->exons;
test(46,scalar @exons1,'failed to find exons on forward gene');
$forward->relative(1);
@exons2 = $forward->exons;
test(47,scalar @exons2,'failed to find relative exons on forward gene');
test(48,$exons2[0]->start == 1,"relative exons on forward gene don't start with 1");
test(49,$exons1[0]->dna eq $exons2[0]->dna,"absolute and relative exons don't match");

@exons1 = $reverse->exons;
test(50,scalar @exons1,'failed to find exons on reverse gene');
$reverse->relative(1);
@exons2 = $reverse->exons;
test(51,scalar @exons2,'failed to find relative exons on reverse gene');
test(52,$exons2[0]->start == 1,"relative exons on reverse gene don't start with 1");
test(53,$exons1[-1]->dna eq $exons2[0]->dna,"absolute and relative exons don't match (1)");
test(54,$exons1[0]->dna eq $exons2[-1]->dna,"absolute and relative exons don't match (2)");


