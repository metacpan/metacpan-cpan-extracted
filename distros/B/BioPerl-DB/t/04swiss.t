# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 55);
	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
	use_ok('Bio::Seq::SeqFactory');
}

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'swiss',
			    '-file' => test_input_file('swiss.dat'));
my $seq = $seqio->next_seq();
ok $seq;

my $pseq = $db->create_persistent($seq);
ok $pseq;
isa_ok $pseq, "Bio::DB::PersistentObjectI";
isa_ok $pseq, "Bio::SeqI";

$pseq->namespace("mytestnamespace");
$pseq->create();
my $dbid = $pseq->primary_key();
ok $dbid;

my $adp = $db->get_object_adaptor($seq);
ok $adp;
isa_ok $adp, "Bio::DB::PersistenceAdaptorI";

my $seqfact = Bio::Seq::SeqFactory->new(-type => "Bio::Seq::RichSeq");
ok $seqfact;
isa_ok $seqfact, "Bio::Factory::ObjectFactoryI";

# try/finally
eval {
    $dbseq = $adp->find_by_primary_key($dbid, $seqfact);
    ok $dbseq;

    is ($dbseq->display_id, $seq->display_id);
    like ($dbseq->primary_id, qr/=HASH/);
    like ($seq->primary_id, qr/=HASH/);
    is ($dbseq->accession_number, $seq->accession_number);
    is ($dbseq->species->binomial, $seq->species->binomial);
    is ($dbseq->subseq(3,10), $seq->subseq(3,10) );
    is ($dbseq->seq, $seq->seq);
    is ($dbseq->length, $seq->length);
    is ($dbseq->length, length($dbseq->seq));

    is ($dbseq->desc, $seq->desc);

    my @dbarr = $dbseq->annotation->get_Annotations('dblink');
    my @arr = $seq->annotation->get_Annotations('dblink');
    is (scalar(@dbarr), scalar(@arr));

    @dbarr = sort { $a->primary_id cmp $b->primary_id } @dbarr;
    @arr = sort { $a->primary_id cmp $b->primary_id } @arr;
    is ( $dbarr[0]->primary_id, $arr[0]->primary_id);

    @dbarr = $dbseq->annotation->get_Annotations('reference');
    @arr = $seq->annotation->get_Annotations('reference');
    is (scalar(@dbarr), scalar(@arr));

    @dbarr = sort { $a->primary_id cmp $b->primary_id } @dbarr;
    @arr = sort { $a->primary_id cmp $b->primary_id } @arr;
    is ( $dbarr[0]->primary_id, $arr[0]->primary_id);
    is (scalar(grep { $_->start() && $_->end(); } @dbarr),
	scalar(grep { $_->start() && $_->end(); } @arr));

    foreach (@dbarr) {
	my $ref = shift(@arr);
	is ($_->authors, $ref->authors);
	is ($_->title, $ref->title);
	is ($_->location, $ref->location);
	is ($_->medline, $ref->medline);
    }
    
    @dbarr = $dbseq->annotation->get_Annotations('gene_name');
    @arr = $seq->annotation->get_Annotations('gene_name');
    ok (scalar(@dbarr));
    is (scalar(@dbarr), scalar(@arr));
    @dbarr = sort { $a->value() cmp $b->value() } @dbarr;
    @arr = sort { $a->value() cmp $b->value() } @arr;
    for(my $i = 0; $i < @dbarr; $i++) {
	is ($dbarr[$i]->value(), $arr[$i]->value());
    }

    @dbarr = $dbseq->top_SeqFeatures();
    @arr = $seq->top_SeqFeatures();
    is (scalar(@dbarr), scalar(@arr));
    @dbarr = sort { $a->primary_tag() cmp $b->primary_tag() } @dbarr;
    @arr = sort { $a->primary_tag() cmp $b->primary_tag() } @arr;
    for(my $i = 0; $i < @dbarr; $i++) {
	is ($dbarr[$i]->primary_tag(), $arr[$i]->primary_tag());
    }

};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);
