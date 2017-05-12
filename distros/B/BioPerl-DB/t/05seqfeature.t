# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 52);
	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
	use_ok('Bio::Root::IO');
}

$biosql = DBTestHarness->new("biosql");
$db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => test_input_file('parkin.gb'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");

# set up feature and its location
$feat = Bio::SeqFeature::Generic->new;
$feat->start(1);
$feat->end(10);
$feat->strand(-1);

$feat->primary_tag('tag1');
$feat->score(12345);
$feat->source_tag('some-source');
$feat->add_tag_value('tag12',18);
$feat->add_tag_value('tag12','another damn value');
$feat->add_tag_value('another-tag','something else');

# make persistent
my $pfeat = $db->create_persistent($feat);
isa_ok $pfeat, "Bio::DB::PersistentObjectI";

# store seq
$pseq->create();
ok $pseq->primary_key();

# attach seq (the foreign key)
$pfeat->attach_seq($pseq);

# try/finally (we need to make sure the seq is removed at the end of the test)
eval {
    # store the feature (this will actually be a create)
    $pfeat->store();
    ok $pfeat->primary_key();

    # and re-retrieve
    $fadp = $db->get_object_adaptor($feat);
    ok $fadp;
    $dbf = $fadp->find_by_primary_key($pfeat->primary_key());
    ok $dbf;
    is ($dbf->primary_key, $pfeat->primary_key);
    is ($dbf->primary_tag, $feat->primary_tag);
    is ($dbf->source_tag, $feat->source_tag);
    is ($dbf->score, $feat->score);
    
    is ($dbf->location->start, $feat->location->start);
    is ($dbf->location->end, $feat->location->end);
    is ($dbf->location->strand, $feat->location->strand);
    ok ! $dbf->location->is_remote;
    
    is (scalar($dbf->get_tag_values('tag12')), 2);
    
    ($value) = $dbf->get_tag_values('another-tag');
    is( $value , 'something else');

    # add a tag value and update
    $dbf->add_tag_value('tag13','value for tag13');
    $dbf->attach_seq($pseq); # we need a FK seq to successfully update
    ok $dbf->store();
    # re-retrieve by seq
    my $dbseq = $db->get_object_adaptor("Bio::SeqI")->find_by_primary_key(
						           $pseq->primary_key);
    ok $dbseq;
    ($dbf) = grep { $_->primary_tag eq 'tag1'; } $dbseq->top_SeqFeatures();
    ok $dbf;
    # check previous tags and for added tag
    is (scalar($dbf->get_tag_values('tag12')), 2);
    ($value) = $dbf->get_tag_values('another-tag');
    is( $value , 'something else');
    ($value) = $dbf->get_tag_values('tag13');
    is( $value , 'value for tag13');

    # test remote feature locations
    # without explicit namespace:
    is ($pfeat->remove(), 1);
    $pfeat->location->is_remote(1);
    $pfeat->location->seq_id('AB123456');
    $pfeat->create();
    # re-retrieve and test
    $dbf = $fadp->find_by_primary_key($pfeat->primary_key());
    ok $dbf;
    is ($dbf->primary_key, $pfeat->primary_key);
    is ($dbf->start, 1);
    is ($dbf->end, 10);
    ok $dbf->location->is_remote;
    is ($dbf->location->seq_id, "mytestnamespace:AB123456");
    # with explicit namespace:
    is ($pfeat->remove(), 1);
    $pfeat->location->is_remote(1);
    $pfeat->location->seq_id('XZ:AB123456.4');
    $pfeat->create();
    # re-retrieve and test
    $dbf = $fadp->find_by_primary_key($pfeat->primary_key());
    ok $dbf;
    is ($dbf->primary_key, $pfeat->primary_key);
    is ($dbf->start, 1);
    is ($dbf->end, 10);
    ok $dbf->location->is_remote;
    is ($dbf->location->seq_id, "XZ:AB123456.4");
    # redundant namespace removal
    is ($pseq->remove, 1);
    ok $pfeat->remove;
    $pseq->flush_SeqFeatures();
    $pseq->annotation->remove_Annotations();
    $pseq->add_SeqFeature($pfeat);
    ok $pseq->store;
    # re-retrieve
    $dbseq = $pseq->adaptor->find_by_primary_key($pseq->primary_key);
    ($dbf) = $dbseq->top_SeqFeatures();
    ok $dbf;
    is ($dbf->location->seq_id, "XZ:AB123456.4"); # no removal
    # same game as before but now with implicit namespace
    $pfeat->location->seq_id('AB123456');
    ok $pfeat->store();
    # re-retrieve
    $dbseq = $pseq->adaptor->find_by_primary_key($pseq->primary_key);
    ($dbf) = $dbseq->top_SeqFeatures();
    ok $dbf;
    is ($dbf->location->seq_id, "AB123456");
};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);
