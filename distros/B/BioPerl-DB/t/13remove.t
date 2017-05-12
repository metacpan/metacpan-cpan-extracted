# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 61);

    use_ok('DBTestHarness');
    use_ok('Bio::SeqIO');
}

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
                            '-file' => test_input_file('test.genbank'));

my ($seq, $pseq);
my @seqs = ();
my @arr = ();

eval {
    my $pk = -1;
    while($seq = $seqio->next_seq()) {
        $pseq = $db->create_persistent($seq);
        $pseq->namespace("mytestnamespace");
        $pseq->create();
        ok $pseq->primary_key();
        cmp_ok $pseq->primary_key(), '!=', $pk;
        $pk = $pseq->primary_key();
        push(@seqs, $pseq);
    }
    is (scalar(@seqs), 4);
    $pseq = $seqs[@seqs-1];

    $seqadp = $db->get_object_adaptor("Bio::SeqI");
    ok $seqadp;

    # re-fetch from database
    $pseq = $seqadp->find_by_primary_key($pseq->primary_key());
    
    # features
    @arr = $pseq->top_SeqFeatures();
    is (scalar(@arr), 26);

    # references
    @arr = $pseq->annotation()->get_Annotations("reference");
    is (scalar(@arr), 1);

    # all feature qualifier/value pairs
    @arr = ();
    foreach my $feat ($pseq->top_SeqFeatures()) {
        foreach ($feat->get_all_tags()) {
            push(@arr, $feat->each_tag_value($_));
        }
    }
    is (scalar(@arr), 38);

    # delete all features
    foreach my $feat ($pseq->top_SeqFeatures()) {
        is ($feat->remove(), 1);
    }

    # delete all references
    foreach my $ref ($pseq->annotation()->get_Annotations("reference")) {
        is ($ref->remove(), 1);
    }

    # re-fetch sequence and retest
    $pseq = $seqadp->find_by_primary_key($pseq->primary_key());
    
    # features
    @arr = $pseq->top_SeqFeatures();
    is (scalar(@arr), 0);

    # references
    @arr = $pseq->annotation()->get_Annotations("reference");
    is (scalar(@arr), 0);

    # test removing associations:

    # add the same comment to both seq0 and seq1
    my $cmt = Bio::Annotation::Comment->new(
                                        -tagname => "comment",
                                        -text => "this is a simple comment");
    # add the same simple value to both seq0 and seq1
    my $sv = Bio::Annotation::SimpleValue->new(-tagname => "Fancy",
                                               -value => "a simple value");
    $seqs[0]->annotation->add_Annotation($cmt);
    $seqs[0]->annotation->add_Annotation($sv);
    $seqs[1]->annotation->add_Annotation($cmt);
    $seqs[1]->annotation->add_Annotation($sv);
    ok $seqs[0]->store();
    ok $seqs[1]->store();
    # delete all annotation from seq0 (also shares a reference with seq1)
    ok $seqs[0]->annotation->remove(-fkobjs => [$seqs[0]]);

    # now re-fetch seq0 and seq1 by primary key
    $pseq = $seqadp->find_by_primary_key($seqs[0]->primary_key);
    my $pseq1 = $seqadp->find_by_primary_key($seqs[1]->primary_key);
    # test annotation counts and whether seq1 was unaffected
    is (scalar($pseq->annotation->get_Annotations()), 0);
    is (scalar($pseq1->annotation->get_Annotations("reference")), 3);
    is (scalar($pseq1->annotation->get_Annotations("comment")), 1);
    my ($cmt1) = $pseq1->annotation->get_Annotations("comment");
    is ($cmt1->text, $cmt->text);
    is (scalar($pseq1->annotation->get_Annotations("Fancy")), 1);
    my ($sv1) = $pseq1->annotation->get_Annotations("Fancy");
    is ($sv1->value, $sv->value);
};

print STDERR $@ if $@;

# delete seq
foreach $pseq (@seqs) {
    is ($pseq->remove(), 1);
}
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);

