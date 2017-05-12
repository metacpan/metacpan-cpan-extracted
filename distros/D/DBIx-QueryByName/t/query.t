#!/usr/bin/perl

use strict;
use warnings;
use utf8;
use FindBin;
use lib File::Spec->catdir("..","lib"), File::Spec->catdir($FindBin::Bin,"..","lib");
use Test::More;
use Data::Dumper;
use File::Temp qw(tempfile);
use Fcntl;

BEGIN {

    # skip test if missing dependency
    foreach my $m ('XML::Parser','XML::SimpleObject','DBI','DBD::SQLite','Test::Exception') {
        eval "use $m";
        plan skip_all => "test require missing module $m" if $@;
    }

    plan tests => 67;

    use_ok("DBIx::QueryByName");
}

# before testing anything, we need to setup a simple test database
my (undef,$tmpdb) = tempfile();

my @sqls = (
    # a job table
    'CREATE TABLE jobs (id INTEGER PRIMARY KEY, username CHAR(50), description CHAR(100), status INTEGER);',
    );

my $dbhlite = DBI->connect("DBI:SQLite:$tmpdb", { RaiseError => 1 });
foreach my $sql (@sqls) {
    my $rs = $dbhlite->prepare($sql);

    die "ERROR: 'prepare' failed for [$sql]: ".$dbhlite->errstr
	if (!$rs || $rs->err);

    die "ERROR: 'execute' failed for [$sql]: ".$rs->errstr
	if (!$rs->execute());
}
$dbhlite->disconnect;

# now we can start testing!
my $dbh = DBIx::QueryByName->new();
is(ref $dbh, 'DBIx::QueryByName', "new: bless properly");

# load some queries
sub print_to_file {
    my $file = shift;
    my $str = shift;
    open(FILE,"> $file") or die "failed to open file $file: $!";
    print FILE $str;
    close(FILE);
}

my (undef,$tmpq) = tempfile();

my $queries = <<__ENDQ1__;
<queries>
    <query name="AddJob" params="id,username,description">INSERT INTO jobs (id, username, description, status) VALUES (?,?,?,0)</query>
</queries>
__ENDQ1__

print_to_file($tmpq,$queries);
lives_ok { $dbh->load(session => 'one', from_xml_file => $tmpq) } "load queries for session one (using from_xml_file)";

$queries = <<__ENDQ2__;
<queries>
    <query name="GetAllUserJobs" params="username">SELECT id, description, status FROM jobs WHERE username=?</query>
    <query name="GetUserJobsWithStatus" params="username,status">SELECT id, description FROM jobs WHERE username=? AND status=?</query>
</queries>
__ENDQ2__

lives_ok { $dbh->load(session => 'two', from_xml => $queries) } "load queries for session two (using from_xml)";

# connection settings
throws_ok { $dbh->AddJob( { id => 1, username => 'bob', description => 'do this' } ) } qr/don't know how to open connection/, "can't query until connect() called";
$dbh->connect('one',"dbi:SQLite:$tmpdb");
$dbh->connect('two',"dbi:SQLite:$tmpdb");

# can?
is($dbh->can("AddJob"), 1, "can(AddJob)");
is($dbh->can("GetAllUserJobs"), 1, "can(GetAllUserJobs)");
is($dbh->can("BoB"), 0, "can(BoB)");

# params
is_deeply([$dbh->params("AddJob")], [qw(id username description)]);
is_deeply([$dbh->params("GetAllUserJobs")], [qw(username)]);
is_deeply([$dbh->params("BoB")], []);

# add a few rows
my $sth;
throws_ok { $sth = $dbh->AddJob() } qr/parameter .* is missing from argument hash/, "AddJob fails if no params";
throws_ok { $sth = $dbh->AddJob(id => 1) } qr/AddJob expects a list of hash refs as parameters/, "AddJob fails if param is scalar";
throws_ok { $sth = $dbh->AddJob( [id => 1] ) } qr/AddJob expects a list of hash refs as parameters/, "AddJob fails if param is array ref";
throws_ok { $sth = $dbh->AddJob( {id => 1} ) } qr/parameter username is missing/, "AddJob fails if only one param but missing value";
throws_ok { $sth = $dbh->AddJob( {id => 1}, {id => 2} ) } qr/parameter username is missing/, "AddJob fails if multiple params but missing value";

throws_ok { $sth = $dbh->AddJob( {id => 1, username => {}, description => "bleh"} ) } qr/expected a scalar value for parameter username but got/, "AddJob fails if param is not scalar or an arrayref";
throws_ok { $sth = $dbh->AddJob( {id => 1, username => 'bob', description => "bleh"}, {id => 2, username => {}, description => "bleh"} ) } qr/expected a scalar value for parameter username but got/, "AddJob fails if param is not scalar";

lives_ok { $sth = $dbh->AddJob( { id => 1, username => 'bob', description => 'do this' } ) } "load row via session one";

lives_ok { $sth = $dbh->AddJob( { id => 666, username => ['bob'], description => 'do this' } ) } "accepts even arrayref arguments";

# try reloading
lives_ok { $sth = $dbh->unload(session => "two") } "calling unload";
is($dbh->can("AddJob"), 1, "can(AddJob)");
is($dbh->can("GetAllUserJobs"), 0, "can(GetAllUserJobs)");

# skip this test: it causes a bus error :)
#throws_ok { $dbh->AddJob( { id => 1, username => 'bob', description => 'do that' } ) } qr/primary key must be unique/i, "insert fail if non unique primary key";
lives_ok { $dbh->AddJob( { id => 2, username => 'bob', description => 'do that' } ) } "load row via session one";
lives_ok { $dbh->AddJob( { id => 3, username => 'joe', description => 'do something else' } ) } "load row via session one";

# but cannot call unloaded queries
throws_ok { $dbh->GetAllUserJobs() } qr/unknown database query name/, "error on unloaded query";
lives_ok { $dbh->load(session => 'two', from_xml => $queries) } "reloading queries for session two";
is($dbh->can("AddJob"), 1, "can(AddJob)");
is($dbh->can("GetAllUserJobs"), 1, "can(GetAllUserJobs)");

# mess up query arguments
#throws_ok { $dbh->AddJob( { username => 'joe', description => 'bob' } ) } qr/called with 2 bind variables when 3 are needed/, "missing one query param";
# ooops. that one caused a segfault :)

# a query that doesn't exist
throws_ok { $dbh->CallWhatever() } qr/unknown database query name/, "error if unknown method";

# now call some selects
$sth = $dbh->GetAllUserJobs( { username => 'bob' } );
my @row1 = $sth->fetchrow_array();
is_deeply(\@row1, [ 1, 'do this', 0 ], "first row ok");
my @row2 = $sth->fetchrow_array();
is_deeply(\@row2, [ 2, 'do that', 0 ], "second row ok");
ok(!defined $sth->fetchrow_array(), "only 2 rows to fetch");

# sqlite forces us to call finish explicitely
$sth->finish;

# test begin_work/rollback
throws_ok { $dbh->begin_work() } qr/undefined session argument in begin_work/, "begin_work needs session argument";
lives_ok  { $dbh->begin_work('one') } "begin_work ok";
lives_ok  { $dbh->AddJob( { id => 4, username => 'billy', description => 'pif' } ) } "load 1 row after begin_work";
lives_ok  { $dbh->AddJob( { id => 5, username => 'billy', description => 'paf' } ) } "load 1 row after begin_work";

$sth = $dbh->GetAllUserJobs( { username => 'billy' } );
ok(!defined $sth->fetchrow_array(), "no rows inserted between calls to begin_work and rollback");
$sth = $dbh->GetAllUserJobs( { username => 'bob' } );
is_deeply( [ $sth->fetchrow_array() ], [ 1, 'do this', 0 ], "but previous rows are still committed");
$sth->finish;

throws_ok { $dbh->rollback() } qr/undefined session argument in rollback/, "rollback needs session argument";
lives_ok  { $dbh->rollback('one') } "rollback ok";

$sth = $dbh->GetAllUserJobs( { username => 'billy' } );
ok(!defined $sth->fetchrow_array(), "no rows inserted after rollback");
$sth = $dbh->GetAllUserJobs( { username => 'bob' } );
is_deeply( [ $sth->fetchrow_array() ], [ 1, 'do this', 0 ], "but previous rows are still committed");
$sth->finish;

# TODO: test that begin_work/commit indeed are session based. ex: commit is still on on second dbh
# test begin_work/commit
$dbh->begin_work('one');
lives_ok { $dbh->AddJob( { id => 4, username => 'billy', description => 'pif' } ) } "load 1 row after begin_work";
lives_ok { $dbh->AddJob( { id => 5, username => 'billy', description => 'paf' } ) } "load 1 row after begin_work";

$sth = $dbh->GetAllUserJobs( { username => 'billy' } );
ok(!defined $sth->fetchrow_array(), "no rows inserted before commit called");
$sth->finish;

$dbh->commit('one');
$sth = $dbh->GetAllUserJobs( { username => 'billy' } );
is_deeply( [ $sth->fetchrow_array() ], [ 4, 'pif', 0 ], "row 1 was inserted");
is_deeply( [ $sth->fetchrow_array() ], [ 5, 'paf', 0 ], "row 2 was inserted");
ok(!defined $sth->fetchrow_array(), "only 2 rows to fetch");
$sth->finish;

# test query()
throws_ok { $sth = $dbh->query() } qr/undefined session argument/, "query() dies with no argument";
throws_ok { $sth = $dbh->query('one') } qr/undefined sql string argument/, "query() dies with only session argument";
lives_ok  { $sth = $dbh->query('two',"SELECT COUNT(*) FROM jobs") } "calling query()";
is_deeply( [ $sth->fetchrow_array() ], [ 6 ], "got correct row count");
$sth->finish;

# test bulk insertion
my @rows = (
    { id => 6, username => '6', description => 'blabla' },
    { id => 7, username => '7', description => 'blabla' },
    { id => 8, username => '8', description => 'blabla' },
    { id => 9, username => '9', description => 'blabla' },
    );

lives_ok { $dbh->AddJob(@rows) } "insert 4 rows at once";

lives_ok  { $sth = $dbh->query('two',"SELECT COUNT(*) FROM jobs") } "calling query()";
is_deeply( [ $sth->fetchrow_array() ], [ 10 ], "got correct row count");
$sth->finish;

# now let's see that the inserted data was correct
foreach my $row (@rows) {
    my $id = $row->{id};
    lives_ok  { $sth = $dbh->query('one',"SELECT id, username, description, status FROM jobs WHERE id=$id") } "getting row with id $id";
    is_deeply( [ $sth->fetchrow_array() ], [ $id, $row->{username}, $row->{description}, 0 ], "got correct row count");
}

# TODO: simulate db crash

# TRIED: delete db file and see what happens :)
#unlink $tmpdb or die "failed to remove db file";
# -> no error. behave as if database was still there. strange

# TRIED: remove table and see what happens
#$dbhlite = DBI->connect("DBI:SQLite:$tmpdb", { RaiseError => 1 });
#my $rs = $dbhlite->prepare('DROP TABLE jobs');
#$rs->execute();
#$rs->commit;
#-> die on unknown table jobs... strange

# test quote
my @quotes = (
    "bob" => "\'bob\'",
    "bob=?" => "\'bob=?\'",
    "bob='this'" => "\'bob=\'\'this\'\'\'",
    );
while (@quotes) {
    my $r = shift @quotes;
    my $w = shift @quotes;
    is($dbh->quote('one',$r), $w, "quote($r)");
}

# fix problem with sqlite that doesn't properly finish handles
DBD::SQLite->DESTROY();
