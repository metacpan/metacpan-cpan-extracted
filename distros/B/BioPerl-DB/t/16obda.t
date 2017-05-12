# -*-Perl-*-
# $Id$

use vars qw($old_obda_path);

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 16);

	$old_obda_path = $ENV{OBDA_SEARCH_PATH} 
	   if defined $ENV{OBDA_SEARCH_PATH};
	$ENV{OBDA_SEARCH_PATH} = 't/data/';

	use_ok('DBTestHarness');
	use_ok('Bio::SeqIO');
	use_ok('Bio::DB::Persistent::BioNamespace');
	use_ok('Bio::DB::Registry');
}

my $biosql = DBTestHarness->new("biosql");
my $db = $biosql->get_DBAdaptor();
ok $db;

my $registry_file = test_input_file("seqdatabase.ini");
my $obda_name = "mytestbiosql";
# create a temporary seqdatabase.ini file specific for this test database
write_registry($registry_file);

my $seqio = Bio::SeqIO->new('-format' => 'genbank',
			    '-file' => test_input_file('parkin.gb'));
my $seq = $seqio->next_seq();
ok $seq;
my $pseq = $db->create_persistent($seq);
$pseq->namespace("mytestnamespace");
$pseq->store(); # this will raise warnings if there are duplicates
ok $pseq->primary_key();
$pseq->commit;

# try/finally block
eval {
	my $registry = Bio::DB::Registry->new;
	ok $registry;
	my $biodb = $registry->get_database($obda_name);
	ok $biodb;
	my $seq = $biodb->get_Seq_by_acc('AB019558');
	is $seq->primary_id, 5456929;
	$seq = $biodb->get_Seq_by_id(5456929);
	is $seq->accession, "AB019558";
	$seq = $biodb->get_Seq_by_version('AB019558.1');
	is $seq->primary_id, 5456929;
};

print STDERR $@ if $@;

# delete seq
is ($pseq->remove(), 1);
my $ns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $pseq);
ok $ns = $db->get_object_adaptor($ns)->find_by_unique_key($ns);
ok $ns->primary_key();
is ($ns->remove(), 1);
$ns->commit;

END {
	unlink $registry_file if (-e $registry_file);
	$ENV{OBDA_SEARCH_PATH} = $old_obda_path if defined $old_obda_path;
}

sub write_registry {
	my $file = shift;
	my $c = $db->dbcontext;
	my ($host,$port,$dbname,$pass,$user,$driver) =
	 ($c->host||'',$c->port||'',$c->dbname||'',$c->password||'',$c->username||'',$c->driver||'');

        open my $F,">$file";
	print $F <<OBDA;
VERSION=1.00

[$obda_name]
protocol=biosql
location=$host:$port
dbname=$dbname
passwd=$pass
user=$user
driver=$driver
OBDA
    close $F;
}
