# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 70);
	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
	use_ok('Bio::PrimarySeq');
}

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'fasta',
			    '-file' => test_input_file('parkin.fasta'));
my $seq = $seqio->next_seq();
ok $seq;

my $pseq = $db->create_persistent($seq);
ok $pseq;
isa_ok $pseq,"Bio::DB::PersistentObjectI";
isa_ok $pseq,"Bio::PrimarySeqI";

$pseq->namespace("mytestnamespace");
$pseq->store();
my $dbid = $pseq->primary_key();
ok $dbid;

# test long sequence
$seqio->close();
$seqio = Bio::SeqIO->new('-format' => 'fasta',
                         '-file' => test_input_file('Titin.fasta') );
my $lseq = $seqio->next_seq();
$seqio->close();
$lseq->namespace("mytestnamespace");
my ($acc) = grep { /^NM/ } split(/\|/, $lseq->primary_id);
$acc =~ s/\.(\d+)$//;
$lseq->version($1);
$lseq->accession_number($acc);
$lseq->primary_id(undef);
$lseq->display_id($acc);
is ($lseq->accession_number, "NM_003319");
is ($lseq->version, 2);
is ($lseq->length, 82027);
my $plseq = $db->create_persistent($lseq);
$plseq->create();

my $adp = $db->get_object_adaptor($seq);
ok $adp;
isa_ok $adp,"Bio::DB::PersistenceAdaptorI";

# start try/finally
eval {
    my $dbseq = $adp->find_by_primary_key($dbid);
    ok $dbseq;
    is ($dbseq->primary_key(), $dbid);

    is ($dbseq->display_id, $seq->display_id);
    is ($dbseq->accession_number, $seq->accession_number);
    is ($dbseq->namespace, $seq->namespace);
    # the following two may take different call paths depending on whether the
    # sequence has been requested yet or not
    is ($dbseq->length, $seq->length);
    is ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    is ($dbseq->seq, $seq->seq);
    is ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    is ($dbseq->subseq(1,15), $seq->subseq(1,15) );
    is ($dbseq->length, $seq->length);
    is ($dbseq->length, length($dbseq->seq));
    is ($dbseq->desc, $seq->desc);

    my $sequk = Bio::PrimarySeq->new(
			      -accession_number => $pseq->accession_number(),
			      -namespace => $pseq->namespace());
    my $adp2 = $db->get_object_adaptor($sequk);
    $dbseq = $adp2->find_by_unique_key($sequk);
    ok $dbseq;
    is ($dbseq->primary_key, $pseq->primary_key());

    # test correct retrieval of long sequence
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version,
                                  -namespace => $lseq->namespace);
    $dbseq = $adp2->find_by_unique_key($sequk);
    ok $dbseq;
    is ($dbseq->accession_number, $lseq->accession_number);
    is ($dbseq->length, $lseq->length);
    is ($dbseq->namespace, $lseq->namespace);
    is ($dbseq->version, $lseq->version);
    is ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    is ($dbseq->seq, $lseq->seq);

    # test correct update of properties if seq object is updated (but
    # not the sequence)
    $dbseq->version($lseq->version() + 1);
    ok $dbseq->store();
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version() + 1,
                                  -namespace => $lseq->namespace);
    $dbseq = $adp2->find_by_unique_key($sequk);
    is ($dbseq->length, $lseq->length);
    is ($dbseq->version, $lseq->version() + 1);
    is ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    is ($dbseq->seq, $lseq->seq);

    # test correct update of properties if seq object is not updated
    ok !$dbseq->is_dirty;
    ok $dbseq->store();
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version() + 1,
                                  -namespace => $lseq->namespace);
    $dbseq = $adp2->find_by_unique_key($sequk);
    is ($dbseq->length, $lseq->length);
    is ($dbseq->version, $lseq->version() + 1);
    is ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    is ($dbseq->seq, $lseq->seq);

    # test whether a null sequence will not clobber the sequence in
    # the database
    $dbseq->seq(undef);
    is ($dbseq->length, 0);
    is ($dbseq->seq, undef);
    $dbseq->length($lseq->length);
    is ($dbseq->seq, undef);
    is ($dbseq->length, $lseq->length);
    ok $dbseq->is_dirty;
    ok $dbseq->store;
    # re-retrieve and test
    $sequk = Bio::PrimarySeq->new(-accession_number =>$lseq->accession_number,
                                  -version => $lseq->version() + 1,
                                  -namespace => $lseq->namespace);
    $dbseq = $adp2->find_by_unique_key($sequk);
    is ($dbseq->length, $lseq->length);
    is ($dbseq->version, $lseq->version() + 1);
    is ($dbseq->subseq(40100,40400), $lseq->subseq(40100,40400));
    is ($dbseq->seq, $lseq->seq);

    # test automatic casting of numeric values to string (varchar) -
    # this may be an issue with PostgreSQL v8.3+ (but shouldn't be)
    my $nseq = Bio::PrimarySeq->new(-accession_number => 123456,
                                    -primary_id => 654321,
                                    -display_id => 3457,
                                    -desc => "test only",
                                    -seq => "ACGTACGATGCTAGTAGCATCG",
                                    -namespace => $lseq->namespace());
    my $pnseq = $db->create_persistent($nseq);
    # insert:
    $pnseq->create();
    ok $pnseq->primary_key;
    # update:
    $pnseq->primary_id(987654);
    $pnseq->store();
    # select (and test for update effect):
    $sequk = Bio::PrimarySeq->new(-accession_number => 123456,
                                  -namespace => $lseq->namespace());
    $dbseq = $adp2->find_by_unique_key($sequk);
    ok ($dbseq);
    is ($dbseq->accession_number, 123456);
    is ($dbseq->primary_id, 987654);
    is ($dbseq->display_id, 3457);
    is ($dbseq->desc, "test only");
    is ($dbseq->seq, "ACGTACGATGCTAGTAGCATCG");
    # and delete again
    is ($dbseq->remove(), 1);
};

print STDERR $@ if $@;

# delete seqs and namespace
is ($plseq->remove(), 1);
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);
