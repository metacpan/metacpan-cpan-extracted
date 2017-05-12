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

    plan tests => 50;

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

$dbh->connect("main","DBI:SQLite:$tmpdb", { RaiseError => 1 });

my $queries = <<__ENDQ1__;
<queries>
    <query name="AddJob" params="id,username,description">INSERT INTO jobs (id, username, description, status) VALUES (?,?,?,0)</query>

    <query name="GetJobHash" params="username" result="hashref">SELECT id, description, status FROM jobs WHERE username=?</query>
    <query name="GetJobHashIterator" params="username" result="hashrefiterator">SELECT id, description, status FROM jobs WHERE username=?</query>
    <query name="GetJobScalar" params="username" result="scalar">SELECT id, description, status FROM jobs WHERE username=?</query>
    <query name="GetJobScalarIterator" params="username" result="scalariterator">SELECT id, description, status FROM jobs WHERE username=?</query>

    <query name="GetIdScalar" params="username" result="Scalar">SELECT id FROM jobs WHERE username=?</query>
    <query name="GetIdScalarIterator" params="username" result="ScalarIterator">SELECT id FROM jobs WHERE username=?</query>
    <query name="GetIdHash" params="username" result="Hashref">SELECT id FROM jobs WHERE username=?</query>
    <query name="GetIdHashIterator" params="username" result="HashrefIterator">SELECT id FROM jobs WHERE username=?</query>

</queries>
__ENDQ1__

lives_ok { $dbh->load(session => 'main', from_xml => $queries) } "load queries for session main (using from_xml)";

# add a job with different username than bob
$dbh->AddJob({ id => 3, username => 'marley', description => 'whatever'});

#
# what happens when no rows inserted?
#

my $res = $dbh->GetJobHash({ username => "bob" });
ok(!defined $res, "got undef hashref from GetJobHash");

my $it = $dbh->GetJobHashIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::HashIterator", "got a hash iterator");
lives_ok { $res = $it->next('what','ever') } "no error when arguments but no row returned";
is($res,undef, "next returns undef");
$res = $it->next;
is($res,undef, "and does so even the second time");

$res = $dbh->GetJobScalar({ username => "bob" });
ok(!defined $res, "got undef scalar from GetJobScalar");

$it = $dbh->GetJobScalarIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::ScalarIterator", "got a scalar iterator");
$res = $it->next;
is($res,undef, "next returns undef");
$res = $it->next;
is($res,undef, "and does so even the second time");


#
# what happens when only one row inserted?
#

$dbh->AddJob({ id => 1, username => 'bob', description => 'whatever'});

$res = $dbh->GetJobHash({ username => "bob" });
is_deeply($res, { status => 0, id => 1, description => 'whatever'}, "GetJobHash returns correct hashref");

$it = $dbh->GetJobHashIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::HashIterator", "got a hash iterator");
$res = $it->next;
is_deeply($res, { status => 0, id => 1, description => 'whatever'}, "GetJobHashIterator returns correct hashref");
$res = $it->next;
is($res,undef, "then undef");

throws_ok { $dbh->GetJobScalar({ username => "bob" }) } qr/query GetJobScalar returns more than 1 column/, "GetJobScalar fails";

$it = $dbh->GetJobScalarIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::ScalarIterator", "got a scalar iterator");
throws_ok { $it->next } qr/query GetJobScalarIterator returns more than 1 column/, "next fails";

$res = $dbh->GetIdScalar({ username => "bob" });
is($res, 1, "GetIdScalar returns 1 elem");

$it = $dbh->GetIdScalarIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::ScalarIterator", "got a scalar iterator");
$res = $it->next;
is($res, 1, "next returns 1");
$res = $it->next;
is($res,undef, "then undef");

$res = $dbh->GetIdHash({ username => "bob" });
is_deeply($res, { id => 1 }, "GetIdHash returns 1 elem");

$it = $dbh->GetIdHashIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::HashIterator", "got a hash iterator");
$res = $it->next;
is_deeply($res, { id => 1 }, "next returns 1 elem");
$res = $it->next;
is($res,undef, "then undef");

#
# what happens when two rows inserted?
#

$dbh->AddJob({ id => 2, username => 'bob', description => 'and more'});

throws_ok { $dbh->GetJobHash({ username => "bob" }) } qr/query GetJobHash returned more than one row/, "error when hash and 2 rows";

$it = $dbh->GetJobHashIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::HashIterator", "got a hash iterator");
$res = $it->next;
is_deeply($res, { status => 0, id => 1, description => 'whatever'}, "GetJobHashIterator returns correct hashref");
$res = $it->next;
is_deeply($res, { status => 0, id => 2, description => 'and more'}, "GetJobHashIterator returns correct hashref");
$res = $it->next;
is($res,undef, "then undef");

throws_ok { $dbh->GetJobScalar({ username => "bob" }) } qr/query GetJobScalar returns more than 1 column/, "GetJobScalar fails";

$it = $dbh->GetJobScalarIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::ScalarIterator", "got a scalar iterator");
throws_ok { $it->next } qr/query GetJobScalarIterator returns more than 1 column/, "next fails";

throws_ok { $dbh->GetIdScalar({ username => "bob" }) } qr/query GetIdScalar returned more than one row/, "error when scalar and 2 rows";

$it = $dbh->GetIdScalarIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::ScalarIterator", "got a scalar iterator");
$res = $it->next;
is($res, 1, "next returns 1");
$res = $it->next;
is($res, 2, "next returns 2");
$res = $it->next;
is($res,undef, "then undef");

throws_ok { $dbh->GetIdHash({ username => "bob" }) } qr/query GetIdHash returned more than one row/, "error when hash and 2 rows";

$it = $dbh->GetIdHashIterator({ username => "bob" });
is(ref $it, "DBIx::QueryByName::Result::HashIterator", "got a hash iterator");
$res = $it->next;
is_deeply($res, { id => 1 }, "next returns 1 elem");
$res = $it->next;
is_deeply($res, { id => 2 }, "next returns 1 elem");
$res = $it->next;
is($res,undef, "then undef");

#
# test next's arguments
#

# hashref iterator
$it = $dbh->GetJobHashIterator({ username => "bob" });
my @res = $it->next('status','description');
is_deeply(\@res, [ 0, 'whatever' ], "next with 2 valid column names");
throws_ok { $res = $it->next('id','bob') } qr/query GetJobHashIterator does not return any value named bob/, "next with invalid column name";

# again, just to try out syntax
$it = $dbh->GetJobHashIterator({ username => "bob" });
@res = ();
while ( my ($id, $status) = $it->next('id','status') ) {
    last if (!defined $id);
    push @res, $id, $status;
}
is_deeply(\@res, [ 1, 0, 2, 0 ], "in a while loop");

# scalar iterator
$it = $dbh->GetIdScalarIterator({ username => "bob" });
throws_ok { $res = $it->next(1,2,3) } qr/next got unexpected arguments/, "scalar iterator accepts no arguments";

# to_list
$it = $dbh->GetIdScalarIterator({ username => "bob" });
is_deeply([$it->to_list], [1, 2], "transform to list via to_list");

# fix problem with sqlite that doesn't properly finish handles
DBD::SQLite->DESTROY();
