# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 14);

	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
	use_ok('Bio::Annotation::Comment');
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
# store seq
$pseq->create();
ok $pseq->primary_key();

$adp = $db->get_object_adaptor("Bio::Annotation::Comment");
ok $adp;

# start try/finally
eval {
    my $comment = Bio::Annotation::Comment->new();
    $comment->text("Some text");
    
    my $pcomment = $adp->create_persistent($comment);
    $pcomment->rank(10);
    $pcomment->create(-fkobjs => [$pseq]);
    ok $pcomment->primary_key();

    my $dbcomment = $adp->find_by_primary_key($pcomment->primary_key());
    
    ok $dbcomment;
    
    is ($dbcomment->text, $comment->text);
};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);
