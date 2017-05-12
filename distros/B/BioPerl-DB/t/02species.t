# -*-Perl-*-
# $Id$

use strict;
use warnings;

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 67);
	use_ok('DBTestHarness');
	use_ok('Bio::Species');
}

my $biosql = DBTestHarness->new("biosql");
ok $biosql;

my $db = $biosql->get_DBAdaptor();
ok $db;

my $s = Bio::Species->new('-classification' => [reverse(
    qw(Eukaryota Metazoa Chordata Vertebrata Mammalia Eutheria
    Primates Catarrhini Hominidae Homo), 'Homo sapiens')]);
my $p_s = $db->create_persistent($s);
ok $p_s;
isa_ok $p_s,"Bio::DB::PersistentObjectI";
isa_ok $p_s,"Bio::Species";

$p_s->create();
my $dbid = $p_s->primary_key();
ok $dbid;

my $adp = $db->get_object_adaptor($s);
ok $adp;
isa_ok $adp,"Bio::DB::PersistenceAdaptorI";
my $dbobj = $adp->find_by_primary_key($dbid);

is ($dbobj->species, $s->species);
is ($dbobj->genus, $s->genus);
is (scalar($dbobj->classification), scalar($s->classification));
my @dbclf = $dbobj->classification();
my @clf = $s->classification();
while(@dbclf || @clf) {
    is (shift(@dbclf), shift(@clf));
}

my $dbobj2 = $adp->find_by_unique_key($s);
ok $dbobj2;
if($dbobj2) {
    is ($dbobj2->primary_key(), $dbobj->primary_key());
    is ($dbobj2->species, $s->species);
    is ($dbobj2->genus, $s->genus);
    is ($dbobj2->binomial, $s->binomial);
    is (scalar($dbobj2->classification), scalar($s->classification));
    @dbclf = $dbobj->classification();
    @clf = $s->classification();
    while(@dbclf || @clf) {
	is (shift(@dbclf), shift(@clf));
    }
} else {
    for (1..5) { skip("fetch by UK failed", 0); }
}

# delete and re-insert with NCBI taxon ID

is ($p_s->remove(), 1);
$p_s->ncbi_taxid(9606);
$p_s->common_name("human");
$p_s->sub_species("subsp. sapiens");
ok ($p_s->create());
$dbobj2 = $adp->find_by_unique_key($s);
ok $dbobj2;
ok $dbobj2->primary_key;
cmp_ok($dbobj2->primary_key, '!=', $dbobj->primary_key);
if($dbobj2) {
    is ($dbobj2->species, $s->species);
    is ($dbobj2->genus, $s->genus);
    is ($dbobj2->binomial, $s->binomial);
    is ($dbobj2->ncbi_taxid, $s->ncbi_taxid);
    is ($dbobj2->common_name, $p_s->common_name);
    is ($dbobj2->sub_species, $p_s->sub_species);
    is (scalar($dbobj2->classification), scalar($s->classification));
    @dbclf = $dbobj->classification();
    @clf = $s->classification();
    while(@dbclf || @clf) {
	is (shift(@dbclf), shift(@clf));
    }
} else {
    for (1..8) { skip("fetch by UK failed", 0); }
}

is ($p_s->remove(), 1);
is (undef, $p_s->primary_key());

$dbobj2 = $adp->find_by_unique_key($s);
is (undef, $dbobj2);
