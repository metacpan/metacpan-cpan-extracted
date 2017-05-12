#
# Test the database / node / DCS directory functions
#
# $Id: 45dir.t,v 165.1 2009/02/24 14:49:07 biersma Exp $
#

use strict;
use Test::More tests => 18;
BEGIN { use_ok('DB2::Admin'); }

$| = 1;

my %fake_db = ('Alias'          => 'NOSUCHDB',
               'DBType'         => 'Remote',
               'Database'       => 'SAMPLE',
               'NodeName'       => 'NOSUCHND',
               'Comment'        => 'No such database',
               'Authentication' => 'Server',
              );
my %fake_node = ('NodeName'    => 'NOSUCHND',
                 'HostName'    => 'Bogus',
                 'ServiceName' => '3700',
                 'Comment'     => 'No such node',
                 'Protocol'    => 'TCP/IP',
                );
my %fake_dcs = ('Database'    => 'NOSUCHDB',
                'Target'      => 'NONESUCH',
                'Comment'     => 'No such DCS database',
               );

my $rc = DB2::Admin->SetOptions('RaiseError' => 1,
                            'PrintError' => 0);
ok ($rc, "SetOptions");

#
# Do some cleanup in case a previous test failed halfway through
#
{
    local $SIG{__WARN__} = sub {};
    eval { DB2::Admin::->UncatalogDCSDatabase('Database' => $fake_dcs{Database}) };
    eval { DB2::Admin::->UncatalogDatabase('Alias' => $fake_db{Alias}) };
    eval { DB2::Admin::->UncatalogNode('NodeName' => $fake_node{NodeName}) };
}

#
# Get global database directory
#
my @db_dir = DB2::Admin::->GetDatabaseDirectory();
ok (scalar(@db_dir), "GetDatabaseDirectory - global");

#
# Get database directory for a specific path (i.e. specific database)
#
my $path;
foreach my $entry (@db_dir) {
    $path = $entry->{Path};
    next unless (defined $path);
    last;
}
SKIP: {
    skip("No local database in directory", 1) unless (defined $path);
    my @local_db_dir = DB2::Admin::->GetDatabaseDirectory('Path' => $path);
    ok (scalar(@local_db_dir), "GetDatabaseDirectory - path");
}

#
# Get node directory
# SQL code -1027: no node directory exists
# SQL code -1037: node directory empty
#
my @node_dir = DB2::Admin::->GetNodeDirectory();
ok ((scalar(@node_dir) ||
     DB2::Admin::sqlcode() == -1037 ||
     DB2::Admin::sqlcode() == -1027), "GetNodeDirectory");

#
# Get DCS directory
# SQL code 1311/1312: DCS directory empty / not exists
#
my @dcs_dir = eval { DB2::Admin::->GetDCSDirectory() };
ok ((scalar(@dcs_dir) ||
     DB2::Admin::sqlcode() == 1311 ||
     DB2::Admin::sqlcode() == 1312), "GetDCSDirectory");


#
# Add a node to the node directory.  We'll use this node for the
# database directory test.
#
$rc = DB2::Admin::->CatalogNode(%fake_node);
ok ($rc, "Catalog Node - add new entry");

#
# Check the node has been added correctly
#
$rc = 0;
@node_dir = DB2::Admin::->GetNodeDirectory();
foreach my $entry (@node_dir) {
    next unless ($entry->{NodeName} eq $fake_node{NodeName});
    $rc = 1;
    foreach my $key (keys %fake_node) {
        next if ($entry->{$key} eq $fake_node{$key});
        warn "Node catalog entry '$key' differs: set '$fake_db{$key}', read '$entry->{$key}'";
       $rc = 0;
    }
    last;
}
ok ($rc, "Catalog node - check entry");


#
# Add a database to the directory
#
$rc = DB2::Admin::->CatalogDatabase(%fake_db);
ok ($rc, "Catalog Database - add new entry");

#
# Check the database has been added correctly
#
$rc = 0;
@db_dir = DB2::Admin::->GetDatabaseDirectory();
foreach my $entry (@db_dir) {
    next unless ($entry->{Alias} eq $fake_db{Alias});
    $rc = 1;
    foreach my $key (keys %fake_db) {
        next if ($entry->{$key} eq $fake_db{$key});
        warn "Database catalog entry '$key' differs: set '$fake_db{$key}', read '$entry->{$key}'";
        $rc = 0;
    }
    last;
}
ok ($rc, "Catalog database - check entry");


#
# Add a DCS database to the directory
#
$rc = DB2::Admin::->CatalogDCSDatabase(%fake_dcs);
ok ($rc, "Catalog DCS Database - add new entry");

#
# Check the DCS database has been added correctly
#
$rc = 0;
@dcs_dir = DB2::Admin::->GetDCSDirectory();
foreach my $entry (@dcs_dir) {
    next unless ($entry->{Database} eq $fake_dcs{Database});
    $rc = 1;
    foreach my $key (keys %fake_dcs) {
        next if ($entry->{$key} eq $fake_dcs{$key});
        warn "DCS catalog entry '$key' differs: set '$fake_db{$key}', read '$entry->{$key}'";
        $rc = 0;
    }
    last;
}
ok ($rc, "Catalog DCS database - check entry");

#
# Uncatalog the DCS database
#
$rc = DB2::Admin::->UncatalogDCSDatabase('Database' => $fake_dcs{Database});
ok ($rc, "Uncatalog DCS Database - remove new entry");

#
# Check the DCS entry is gone
#
$rc = 1;
@dcs_dir = DB2::Admin::->GetDCSDirectory();
foreach my $entry (@dcs_dir) {
    next unless ($entry->{Database} eq $fake_dcs{Database});
    warn "Found entry '$fake_dcs{Database}' after uncatalog";
    $rc = 0;
}
ok($rc, "Unncatalog DCS database - check entry");

#
# Uncatalog the database
#
$rc = DB2::Admin::->UncatalogDatabase('Alias' => $fake_db{Alias});
ok ($rc, "Uncatalog Database - remove new entry");

#
# Check the entry is gone
#
$rc = 1;
@db_dir = DB2::Admin::->GetDatabaseDirectory();
foreach my $entry (@db_dir) {
    next unless ($entry->{Alias} eq $fake_db{Alias});
    warn "Found entry '$fake_db{Alias}' after uncatalog";
    $rc = 0;
}
ok ($rc, "Uncatalog Database - check entry");

#
# Uncatalog the node
#
$rc = DB2::Admin::->UncatalogNode('NodeName' => $fake_node{NodeName});
ok ($rc, "Uncatalog Node - remove new entry");

#
# Check the entry is gone
#
$rc = 1;
@node_dir = DB2::Admin::->GetNodeDirectory();
foreach my $entry (@node_dir) {
    next unless ($entry->{NodeName} eq $fake_node{NodeName});
    warn "Found entry '$fake_node{NodeName}' after uncatalog";
    $rc = 0;
}
ok ($rc, "Uncatalog Node - check entry");

