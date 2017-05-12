# -*-Perl-*-
# $Id$

BEGIN {
    use lib 't';
    use Bio::Root::Test;
    test_begin(-tests => 23);
    use_ok('BioSQLBase');
    use_ok('Bio::DB::BioSQL::DBAdaptor');
    use_ok('Bio::BioEntry');
    use_ok('Bio::DB::Persistent::BioNamespace');
}

my $biosql = DBTestHarness->new("biosql");
ok $biosql;

my $dbc = $biosql->get_DBContext();
ok $dbc;

my $db = $dbc->dbadaptor();
isa_ok $db,"Bio::DB::DBAdaptorI";
isa_ok $db,"Bio::DB::BioSQL::DBAdaptor";

# test connection
my $dbh = $dbc->dbi()->new_connection($dbc);
ok $dbh;
my $rc = $dbh->ping();
ok ($rc && ($rc ne '0 but true'));

# test that the -dsn option works as advertised
my $dsn = $dbc->dbi()->build_dsn($dbc); # that's what's used for connecting
my $db2 = Bio::DB::BioDB->new(-database => "biosql", -dsn => $dsn);
my $dbc2 = $db2->dbcontext;
is ($dbc2->dbi->build_dsn($dbc2), $dsn);
$dbc2->host("i.dont.exist.com");
$dbc2->port(9876);
is ($dbc2->dbi->build_dsn($dbc2), $dsn); # dsn is to be taken verbatim
$db2 = undef;
# test the dsn parsing results
$dbc2 = Bio::DB::SimpleDBContext->new(-dsn => $dsn);
is ($dbc2->driver, $dbc->driver);
is ($dbc2->dbname, $dbc->dbname);
is ($dbc2->host, $dbc->host);
is ($dbc2->port, $dbc->port);

# test that transaction control is active by trying to roll back
my $ns = Bio::BioEntry->new(-namespace => "__dummy__", -authority => "nobody");
my $adp = $db->get_object_adaptor("BioNamespace");
# we need to disable caching, or otherwise it will bite us
$adp->caching_mode(0);
my $pns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $ns,
                                                 -adaptor => $adp);
is ($pns->namespace, $ns->namespace);
is ($pns->authority, $ns->authority);
# try to find it - this should fail
my $dbns = $adp->find_by_unique_key($pns);
if ($dbns) {
    warn("found __dummy__ namespace - leftover from previously aborted test?");
    # remove it
    $dbns->remove();
    # we need to commit here or otherwise we can't safely test for rollback
    $dbns->commit;
}
ok $pns->create();
# now we should find it - sanity check
$dbns = Bio::DB::Persistent::BioNamespace->new(-identifiable => $ns);
$dbns = $adp->find_by_unique_key($dbns);
ok ($dbns);
is ($dbns->primary_key, $pns->primary_key);
is ($dbns->namespace, $pns->namespace);
# now rollback
$adp->rollback();
$dbns = $adp->find_by_unique_key($pns);
is ($dbns, undef);
if ($dbns) {
    warn("your RDBMS does not have transactions enabled - please fix this\n");
}

# and the namespace should be gone
$dbh->disconnect();



