# -*-Perl-*-
# $Id$

use strict;
use warnings;

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 23);

	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
	use_ok('Bio::DB::Persistent::BioNamespace');
}

my $biosql = DBTestHarness->new("biosql");
my $db = $biosql->get_DBAdaptor();
ok $db;

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => test_input_file('parkin.gb'));
my $seq = $seqio->next_seq();
ok $seq;
my $sn = $seq->species->scientific_name;
my $sc = join(", ", $seq->species->classification);

my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->store();
ok $pseq->primary_key();

my $adp = $db->get_object_adaptor($seq);
ok $adp;

my $seqfact = Bio::Seq::SeqFactory->new(-type => "Bio::Seq::RichSeq");
ok $seqfact;

# try/finally block
eval {
    my $dbseq = $adp->find_by_primary_key($pseq->primary_key, $seqfact);
    ok $dbseq;

    is ($dbseq->display_id, $seq->display_id);
    is ($dbseq->accession_number, $seq->accession_number);
    is ($dbseq->namespace, $seq->namespace);
	is ($dbseq->version, $seq->version);
    is ($dbseq->seq_version, 1);
    is ($dbseq->seq_version, $seq->seq_version);
    is ($dbseq->version, 1);
    is ($dbseq->version, $seq->version);
 	is ($dbseq->species->scientific_name, $sn);
 	is (join(", ", $dbseq->species->classification), $sc);
};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);
