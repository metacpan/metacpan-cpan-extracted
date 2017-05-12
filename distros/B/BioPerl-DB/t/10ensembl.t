# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 18);

	use_ok('DBTestHarness');
	use_ok('Bio::DB::BioSQL::DBAdaptor');
	use_ok('Bio::SeqIO');
}
#END { unlink( 't/ensembl_test.gb') }

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => test_input_file('AP000868.gb'));
my $seq = $seqio->next_seq();
ok $seq;

my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->store();
ok $pseq->primary_key();

my $seqadp = $db->get_object_adaptor($seq);

# try/finally block
eval {
    $dbseq = $seqadp->find_by_primary_key($pseq->primary_key());
    ok $dbseq;
    
    is ($dbseq->display_id, $seq->display_id);
    is ($dbseq->accession, $seq->accession);
    is ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    is ($dbseq->subseq(1,15), $seq->subseq(1,15) );
    is ($dbseq->length, $seq->length);
    is ($dbseq->seq, $seq->seq);

    is ($dbseq->desc, $seq->desc);

#$out = Bio::SeqIO->new('-file' => '>t/ensembl_test.gb' ,
#		       '-format' => 'GenBank');
#$out->write_seq($dbseq);
};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);


