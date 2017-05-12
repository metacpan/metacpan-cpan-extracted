# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 21);
	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
	use_ok('Bio::DB::Persistent::BioNamespace');
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
$pseq->store();
ok $pseq->primary_key();

my $dbl = Bio::Annotation::DBLink->new();
$dbl->database("new-db");
$dbl->primary_id("primary-id-12");

# try/finally block
eval {
    my $pdbl = $db->create_persistent($dbl);
    $pdbl->store();
    ok $pdbl->primary_key();
    
    my $dbladp = $db->get_object_adaptor("Bio::Annotation::DBLink");
    my $fromdb = $dbladp->find_by_primary_key($pdbl->primary_key());
    ok $fromdb;
    is ($fromdb->primary_key, $pdbl->primary_key);
    is ($fromdb->database, $dbl->database);
    is ($fromdb->primary_id, $dbl->primary_id);

    ok $dbladp->add_association(-objs => [$pseq, $pdbl]);

    my $dbseq = $pseq->adaptor()->find_by_primary_key($pseq->primary_key());
    ok $dbseq;
    my @mydbls = grep {
	$_->database() eq "new-db";
    } $dbseq->annotation->get_Annotations("dblink");
    is (scalar(@mydbls), 1);
    is ($mydbls[0]->primary_id, $dbl->primary_id);
    is ($mydbls[0]->primary_key, $pdbl->primary_key);

    is ($fromdb->remove(), 1);
};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);

