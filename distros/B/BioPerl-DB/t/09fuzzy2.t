# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 23);
# -----------------------------------------------
# REQUIREMENTS TESTED: (not yet!)
# unknown start/end (eg like we find in SP)
# must be handled gracefully
# cjm@fruitfly.org
# -----------------------------------------------
	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
}

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'embl',
			    '-file' => test_input_file('AB030700.embl'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->create();
ok $pseq->primary_key();

my $seqadp = $db->get_object_adaptor($seq);
ok $seqadp;

eval {
    my $sequk = Bio::Seq::RichSeq->new(-accession_number => "AB030700",
				       -version   => 1,
				       -namespace => "mytestnamespace");
    $dbseq = $seqadp->find_by_unique_key($sequk);
    ok $dbseq;

    is ($dbseq->display_id, $seq->display_id);
    is ($dbseq->accession, $seq->accession);
    is ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    is ($dbseq->subseq(1,15), $seq->subseq(1,15) );
    is ($dbseq->length, $seq->length);
    is ($dbseq->seq, $seq->seq);
    is ($dbseq->desc, $seq->desc);

    @dblinks = sort {
	$a->primary_id cmp $b->primary_id
	} $dbseq->annotation->get_Annotations('dblink');
    @stdlinks = sort {
	$a->primary_id cmp $b->primary_id
	} $seq->annotation->get_Annotations('dblink');

    ok (scalar(@dblinks));
    is (scalar(@dblinks), scalar(@stdlinks));

    for(my $i = 0; $i < @dblinks; $i++) {
	is($dblinks[$i]->database, $stdlinks[$i]->database);
	is($dblinks[$i]->primary_id, $stdlinks[$i]->primary_id);
	TODO: {
		local $TODO = 'optional_id() for dblinks is not working yet';
		is($dblinks[$i]->optional_id, $stdlinks[$i]->optional_id);
	}
    }
};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);

