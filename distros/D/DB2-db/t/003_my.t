#! perl -w

use Test::More tests => 21;
use Test::NoWarnings;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, File::Spec->updir, 'samples');

my $instance;
BEGIN { 
    $instance = $ENV{DB2INSTANCE};
    use_ok('My::db');
}

# first thing's first - is the instance set up properly?
my $uid = getpwnam($instance);

can_ok('My::db', 'new');

SKIP: {
    skip "No instance - can't do anything", 18 unless $uid;
    skip "No local server", 18 if $ENV{SKIP_LOCAL_SERVER_TEST};

    my $db = My::db->new;
    ok($db, "create derived db object");
    isa_ok($db, 'DB2::db', 'derivation is still ok');
    isa_ok($db, 'My::db', 'derivation is still ok');

    $db->create_db();
    ok($db->connection(), "ensure we can now connect (maybe the server was stopped?)");

    my $table = $db->get_table('My::Employee');
    ok($table, "Can get table");
    isa_ok($table, "My::Employee");
    isa_ok($table, "DB2::Table");

    is($table, $db->get_table('Employee'), "Can get table through shortcut");
    is($table, $db->get_table('Employee'), "Can get table through shortcut again");

    my $row = $table->create_row;
    ok($row, "Can create row");
    isa_ok($row, "My::EmployeeR");
    isa_ok($row, "DB2::Row");
    
    $row->empno("000011");
    $row->firstname("Michael");
    $row->midinit("J");
    $row->lastname("Fox");
    $row->salary("500000.55");
    unless (ok($row->save(), "Saving employee"))
    {
        diag($row->dbi_errstr());
    }

    my $retrieved = $table->find_id("000011");
    ok($retrieved, "Retrieving employee");
    is($retrieved ? $retrieved->firstname : '', "Michael", "retrieved okay");

    my $prod_tbl = $db->get_table('Product');
    ok($prod_tbl, "Can get Product table");

    $row = $prod_tbl->create_row();
    isa_ok($row, 'DB2::Row');
    isa_ok($row, 'My::Row');

    $row->prodname('One Dum Movie');
    $row->baseprice('1500');
    $row->save();
    my $row_id = $row->prodid();

    # test statement attributes.
    eval "package My::Row; sub _prepare_attributes { { db2_txn_isolation => DBD::DB2::Constants::SQL_TXN_READ_UNCOMMITTED } }";
    ok(!$@, "Overriding _prepare_attributes");
    my $obj = $prod_tbl->find_id($row_id);
    is($obj ? $obj->baseprice() : 0, '1500.00', 'Price check at cash 3');

    $db->disconnect();
    # done testing!
    system "db2 drop db " . $db->db_name;
}

