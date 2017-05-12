#!/usr/bin/perl -- -*-cperl-*-

use strict;
use warnings;
use Test::More;
use Data::Dumper;
use vars qw($dbh $SQL $sth $info $expected); ## no critic

## Common error string regexes
my $NORUN   = qr{Invalid statement:};
my $NOMULTI = qr{cannot insert multiple commands};
my $FORBID  = qr{Forbidden statement};

eval { require DBI;	DBI->import; };
if ($@) {
	plan skip_all => 'Must install the DBI module to test DBIx::Safe';
}

eval { require DBIx::Safe; };
$@ and BAIL_OUT qq{Could not load the DBIx::Safe module: $@};

eval {
    $dbh = DBI->connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS},
        {AutoCommit=>0,RaiseError=>1,PrintError=>0});
};
if ($@) {
	plan skip_all => "Cannot test without a valid database connection: make sure DBI_DSN and DBI_USER are set.Error was $@\n";
}
else {
	plan tests => 219;
}

pass("Connected to the test database");
isa_ok($dbh, 'DBI::db', qq{Got a DBI object});

#
# Tests for the new() method
#

my $safe;
eval { $safe = DBIx::Safe->new(); };
like($@, qr{requires a hashref},
    qq{Method new() fails with no arguments});

my $fakedbh;
eval { $safe = DBIx::Safe->new({dbh=>$fakedbh}); };
like($@, qr{not a database handle},
    qq{Method new() fails with invalid "dbh" argument});

## Check for unknown database type
$fakedbh = DBI->connect('dbi:Sponge:', '','',{AutoCommit=>1});
eval { $safe = DBIx::Safe->new({dbh=>$fakedbh}); };
like($@, qr{do not work with that type of database},
    qq{Method new() fails with unhandled database type});

eval { $safe = DBIx::Safe->new({dbh=>$dbh, allow_command=>$dbh}); };
my $dbtype = $dbh->{Driver}{Name};

## May be a bad database
if ($@ =~ /do not work with that/) {
    BAIL_OUT "DBIx::Safe cannot work against the type of database: $dbtype";
}
like($@, qr{allow_command must be passed},
    qq{Method new() fails with invalid "allow_command" argument});

eval { $safe = DBIx::Safe->new({dbh=>$dbh, allow_command=>[' 14964AC8 ']}); };
like($@, qr{invalid argument},
    qq{Method new() fails when "allow_command" arrayref argument contains invalid characters});

eval { $safe = DBIx::Safe->new({dbh=>$dbh, allow_command=>' select '}); };
is($@, q{},
    qq{Method new() works when passed valid arguments});
isa_ok($safe, "DBIx::Safe") or BAIL_OUT qq{Cannot continue without a valid DBIx::Safe object};

my $t=q{ DBIx::Safe object is Dumpable};
eval {
	$info = Dumper $safe;
};
is($@, q{}, $t);

#
# Tests for the allow_command() and unallow_command() methods
#

eval { $info = $safe->allow_command(); };
is($@, q{},
    qq{Method allow_command() returns a list when given no arguments});
is_deeply($info, {select => 0},
    qq{Method allow_command() returns correct list});

eval { $safe->allow_command({foobar => 1}); };
like($@, qr{allow_command must be passed},
    qq{Method allow_command() fails when passed a hashref});

eval { $safe->allow_command([qw(select insert select)]); };
like($@, qr{duplicate argument},
    qq{Method allow_command() fails when passed duplicate commands});

eval { $safe->allow_command('select insert SELECT'); };
like($@, qr{duplicate argument},
    qq{Method allow_command() fails when passed duplicate commands});

eval { $safe->allow_command(['select','insert select']); };
like($@, qr{duplicate argument},
    qq{Method allow_command() fails when passed duplicate commands});

eval { $safe->allow_command('select!'); };
like($@, qr{invalid argument},
    qq{Method allow_command() fails when passed an invalid command});

eval { $info = $safe->allow_command(' update'); };
is($@, q{},
    qq{Method allow_command() works with a single command});
is_deeply($info, {select => 0, update => 0},
    qq{Method allow_command() returns correct list});

eval { $info = $safe->allow_command([' update',' INSERT DELETE ']); };
is($@, q{},
    qq{Method allow_command() works with an arrayref argument});
is_deeply($info, {select => 0, update => 0, insert => 0, delete => 0},
    qq{Method allow_command() returns correct list});

eval { $safe->do("SET foobar=1"); };
like($@, $NORUN,
    qq{Commands not passed to allow_command() cannot be run});

eval { $safe->do("SELECT 123"); };
is($@, q{},
    qq{Commands passed to allow_command() can be run});

eval { $info = $safe->unallow_command(); };
is($@, q{},
    qq{Method unallow_command() returns a list when given no arguments});
is_deeply($info, {select => 1, update => 0, insert => 0, delete => 0},
    qq{Method unallow_command() returns correct list});

eval { $safe->unallow_command(qr{foobar}); };
like($@, qr{unallow_command must be passed},
    qq{Method unallow_command() fails when given a regex});

eval { $safe->unallow_command('delete and delete'); };
like($@, qr{duplicate argument},
    qq{Method unallow_command() fails when passed duplicate commands});

eval { $safe->unallow_command(['delete',' delete']); };
like($@, qr{duplicate argument},
    qq{Method unallow_command() fails when passed duplicate commands});

eval { $safe->unallow_command(['select','insert select']); };
like($@, qr{duplicate argument},
    qq{Method unallow_command() fails when passed duplicate commands});

eval { $info = $safe->unallow_command('update'); };
is($@, q{},
    qq{Method unallow_command() works with a single command});
is_deeply($info, {select => 1, insert => 0, delete => 0},
    qq{Method unallow_command() returns correct list});

eval { $info = $safe->unallow_command([qw(insert delete)]); };
is($@, q{},
    qq{Method unallow_command() works with an arrayref argument});
is_deeply($info, {select => 1},
    qq{Method unallow_command() returns correct list});

eval { $safe->do("DELETE 123"); };
like($@, $NORUN,
    qq{Commands passed to unallow_command() can no longer be run});

## Lots of adding and removing of words
$safe->allow_command("A stitch in time saves nine");
$safe->unallow_command("TIME STITCH"); ## a in saves nine
$safe->allow_command(['Wild','West']);
$safe->unallow_command(['Wild','Nine']); ## a in saves west
$safe->allow_command(['GoWest YoungMan ']);
$info = $safe->unallow_command('youngman A'); ## in saves west gowest
$expected = {
    gowest => 0,
    in => 0,
    saves => 0,
    select => 1,
    west => 0,
};
is_deeply($info, $expected,
    qq{Methods allow_command() and unallow_command() work as expected});
## Cleanup
$safe->unallow_command('gowest in saves west');


#
# Tests for the allow_regex() and unallow_regex() methods
#

my $regex1 = q{LOCK TABLE \w{6} IN (SHARE|EXCLUSIVE) MODE};
my $regex2 = q{create temp table };
my $regex3 = q{SET TIMEZONE};

eval { $info = $safe->allow_regex(); };
is($@, q{},
    qq{Method allow_regex() returns a list when given no arguments});
is_deeply($info, {},
    qq{Method allow_regex() returns correct list});

eval { $safe->allow_regex($regex1); };
like($@, qr{allow_regex must be passed},
    qq{Method allow_regex() fails when passed a string});

eval { $safe->allow_regex({foobar => 1}); };
like($@, qr{allow_regex must be passed},
    qq{Method allow_regex() fails when passed a hashref});

eval { $safe->allow_regex([qr{$regex1}, qr{$regex1}]); };
like($@, qr{duplicate regexes},
    qq{Method allow_regex() fails when passed duplicate regexes});

eval { $safe->allow_regex([qr{$regex1}, $regex2]); };
like($@, qr{allow_regex must be passed},
    qq{Method allow_regex() fails when all items in arrayref are not regexes});


eval { $info = $safe->allow_regex(qr{$regex1}); };
is($@, q{},
    qq{Method allow_regex() works with a single regex});
is_deeply($info, {qr{$regex1} => 0},
    qq{Method allow_regex() returns correct list});

eval { $info = $safe->allow_regex([qr{$regex2}, qr{$regex3}]); };
is($@, q{},
    qq{Method allow_regex() works with an arrayref argument});
is_deeply($info, {qr{$regex1} => 0, qr{$regex2} => 0, qr{$regex3} => 0},
    qq{Method allow_regex() returns correct list});

eval { $safe->do("LOCK TABLE alphabet"); };
like($@, $NORUN,
    qq{Regexes not passed to allow_regex() cannot be run});

$SQL = "LOCK TABLE foobar IN SHARE MODE NOWAIT";
eval { $safe->do("$SQL WITHERROR"); };
like($@, qr{at or near "WITHERROR"},
    qq{Regexes passed to allow_regex() can be run});
$dbh->rollback();

eval { $safe->do("SET $SQL"); };
like($@, $NORUN,
    qq{Method allow_regex() matches with an anchor});

eval { $info = $safe->unallow_regex(); };
is($@, q{},
    qq{Method unallow_regex() returns a list when given no arguments});
is_deeply($info, {qr{$regex1} => 1, qr{$regex2} => 0, qr{$regex3} => 0},
    qq{Method unallow_regex() returns correct list});

eval { $safe->unallow_regex($regex1); };
like($@, qr{unallow_regex must be passed},
    qq{Method unallow_regex() fails when given a string});

eval { $safe->unallow_regex([qr{$regex1}, qr{$regex1}]); };
like($@, qr{duplicate regexes},
    qq{Method unallow_regex() fails when passed duplicate regexes});

eval { $info = $safe->unallow_regex(qr{$regex1}); };
is($@, q{},
    qq{Method unallow_regex() works with a single regex});
is_deeply($info, {qr{$regex2} => 0, qr{$regex3} => 0},
    qq{Method unallow_regex() returns correct list});

eval { $info = $safe->unallow_regex([qr{$regex2}, qr{$regex3}]); };
is($@, q{},
    qq{Method unallow_regex() works with an arrayref argument});
is_deeply($info, {},
    qq{Method unallow_regex() returns correct list});

eval { $safe->do("$SQL WITHERROR"); };
like($@, $NORUN,
    qq{Regexes passed to allow_regex() can be run});
$dbh->rollback();


#
# Tests for the allow_attribute() and unallow_attributes() methods
#

eval { $info = $safe->allow_attribute(); };
is($@, q{},
   qq{Method allow_attribute() returns a list when given no arguments});
is_deeply($info, {},
    qq{Method allow_attribute() returns correct list});

eval { $safe->allow_attribute({foobar => 1}); };
like($@, qr{allow_attribute must be passed},
    qq{Method allow_attribute() fails when passed a hashref});

eval { $safe->allow_attribute([qw(raiseerror printError RaiseError)]); };
like($@, qr{duplicate argument},
    qq{Method allow_attribute() fails when passed duplicate attributes});

eval { $safe->allow_attribute('RaiseError PrintError RaiseError'); };
like($@, qr{duplicate argument},
    qq{Method allow_attribute() fails when passed duplicate attributes});

eval { $safe->allow_attribute(['RaiseError','InsertError raiseError']); };
like($@, qr{duplicate argument},
    qq{Method allow_attribute() fails when passed duplicate attributes});

eval { $safe->allow_attribute('RaiseError!'); };
like($@, qr{invalid argument},
    qq{Method allow_attribute() fails when passed an invalid attribute});

eval { $info = $safe->allow_attribute('PrintError'); };
is($@, q{},
    qq{Method allow_attribute() works with a single attribute});
is_deeply($info, {printerror => 0},
    qq{Method allow_attribute() returns correct list});

eval { $info = $safe->allow_attribute(['RaiseError','PrintError ListError ']); };
is($@, q{},
    qq{Method allow_attribute() works with an arrayref argument});
is_deeply($info, {printerror => 0, raiseerror => 0, listerror => 0},
    qq{Method allow_attribute() returns correct list});

eval { $safe->{foobar}= 1; };
like($@, qr{Cannot change attribute},
    qq{Attributes not passed to allow_attribute() cannot be changed});

eval { $safe->{PrintError} = 2; };
is($@, q{},
    qq{Attributes passed to allow_attribute() can be run});

eval { $info = $safe->unallow_attribute(); };
is($@, q{},
    qq{Method unallow_attribute() returns a list when given no arguments});
is_deeply($info, {printerror => 1, raiseerror => 0, listerror => 0},
    qq{Method unallow_attribute() returns correct list});

eval { $safe->unallow_attribute(qr{foobar}); };
like($@, qr{unallow_attribute must be passed},
    qq{Method unallow_attribute() fails when given a regex});

eval { $safe->unallow_attribute('raiseerror RaiseError'); };
like($@, qr{duplicate argument},
    qq{Method unallow_attribute() fails when passed duplicate attributes});

eval { $safe->unallow_attribute(['printError',' PrintError']); };
like($@, qr{duplicate argument},
    qq{Method unallow_attribute() fails when passed duplicate attributes});

eval { $safe->unallow_attribute(['listerror','listerror raiseerror']); };
like($@, qr{duplicate argument},
    qq{Method unallow_attribute() fails when passed duplicate attributes});

eval { $info = $safe->unallow_attribute('listerror'); };
is($@, q{},
    qq{Method unallow_attribute() works with a single attribute});
is_deeply($info, {printerror => 1, raiseerror => 0},
    qq{Method unallow_attribute() returns correct list});

eval { $info = $safe->unallow_attribute([qw(printerror deleteError)]); };
is($@, q{},
    qq{Method unallow_attribute() works with an arrayref argument});
is_deeply($info, {raiseerror => 0},
    qq{Method unallow_attribute() returns correct list});

eval { $safe->{PrintError} = 0; };
like($@, qr{Cannot change attribute},
    qq{Attributes passed to unallow_attribute() can no longer be run});

eval { $safe->allow_attribute('AutoCommit'); };
like($@, qr{Attribute AutoCommit cannot be changed},
    qq{Attribute AutoCommit cannot be changed});

eval { $safe->{AutoCommit} = 1; };
like($@, qr{Cannot change attribute},
    qq{Attribute AutoCommit cannot be changed});

eval { $safe->{AutoCommit} = 0; };
like($@, qr{Cannot change attribute},
    qq{Attribute AutoCommit cannot be changed});


## We should not be allowed to ever return internal attributes
eval { $info = $safe->{dbixsafe_sdbh}; };
like($@, qr{Invalid access},
   qq{Not allowed to read internal attributes});

eval { $safe->{dbixsafe_cdate} = 123; };
like($@, qr{Invalid access},
   qq{Not allowed to write internal attributes});

## Cheating with package switching should not work either
## no critic
$main::err = '';
{no warnings;
$DBIx::Safe::safe = $safe;
package DBIx::Safe;
eval { $DBIx::Safe::info = $safe->{dbixsafe_sdbh}; };
 $main::err = $@;
}
package main;
like($main::err, qr{Invalid access},
   qq{Not allowed to read internal attributes});
is($DBIx::Safe::info, undef, qq{Using package trickery does not allow access to a raw database handle});
## use critic

#
# Tests for the deny_regex() and undeny_regex() methods
#

$regex1 = q{LOCK TABLE foobar};
$regex2 = q{SELECT 456};
$regex3 = q{SELECT 789};

eval { $info = $safe->deny_regex(); };
is($@, q{},
   qq{Method deny_regex() returns a list when given no arguments});
is_deeply($info, {},
    qq{Method deny_regex() returns correct list});

eval { $safe->deny_regex({foobar => 1}); };
like($@, qr{deny_regex must be passed},
    qq{Method deny_regex() fails when passed a hashref});

eval { $safe->deny_regex($regex1); };
like($@, qr{deny_regex must be passed},
    qq{Method deny_regex() fails when passed a string});

eval { $safe->deny_regex([qr{$regex2}, qr{$regex2}]); };
like($@, qr{duplicate regex},
    qq{Method deny_regex() fails when passed duplicate regexes});

eval { $safe->deny_regex([qr{$regex2}, $regex2]); };
like($@, qr{deny_regex must be passed},
    qq{Method deny_regex() fails when passed an arrayref with a non-regex member});

eval { $info = $safe->deny_regex(qr{$regex1}); };
is($@, q{},
    qq{Method deny_regex() works with a single regex});
is_deeply($info, {qr{$regex1} => 0},
    qq{Method deny_regex() returns correct list});

eval { $info = $safe->deny_regex([qr{$regex1}, qr{$regex2}]); };
is($@, q{},
    qq{Method deny_regex() works with an arrayref argument});
is_deeply($info, {qr{$regex1} => 0, qr{$regex2} => 0},
    qq{Method deny_regex() returns correct list});

eval { $safe->do("SELECT 123"); };
is($@, q{},
    qq{Method deny_regex() allows normal SQL to run});

eval { $safe->do("SELECT 456"); };
like($@, $FORBID,
    qq{Method deny_regex() restricts matching expressions from running});

eval { $safe->do("selECT 456"); };
is($@, q{},
    qq{Method deny_regex() does not restrict case-sensitively by default});

$safe->deny_regex(qr{$regex2}i);
eval { $safe->do("selECT 456"); };
like($@, $FORBID,
    qq{Method deny_regex() checks case-sensitively when asked to});

eval { $safe->do("SELECT 'selECT 456'"); };
like($@, $FORBID,
    qq{Method deny_regex() doe not anchor by default});

eval { $safe->do("SELECT 'selECT 456'"); };
like($@, $FORBID,
    qq{Method deny_regex() does not anchor by default});

$safe->deny_regex(qr{^$regex3}i);
eval { $safe->do("SELECT 'SELECT 789'"); };
is($@, q{},
    qq{Method deny_regex() allows anchoring of expressions});

eval { $info = $safe->undeny_regex(); };
is($@, q{},
    qq{Method undeny_regex() returns a list when given no arguments});
is_deeply($info, {qr{$regex1} => 0, qr{$regex2} => 0, qr{$regex2}i => 0, qr{^$regex3}i => 0},
    qq{Method undeny_regex() returns correct list});

eval { $safe->undeny_regex($regex1); };
like($@, qr{undeny_regex must be passed},
    qq{Method undeny_regex() fails when given a string});

eval { $safe->undeny_regex([qr{$regex1}, qr{$regex1}]); };
like($@, qr{duplicate regexes},
    qq{Method undeny_regex() fails when passed duplicate regexs});

eval { $safe->undeny_regex([qr{$regex2}, $regex2]); };
like($@, qr{undeny_regex must be passed},
    qq{Method undeny_regex() fails when passed an arrayref with a non-regex member});

eval { $info = $safe->undeny_regex(qr{^$regex3}i); };
is($@, q{},
    qq{Method undeny_regex() works with a single regex});
is_deeply($info, {qr{$regex1} => 0, qr{$regex2} => 0, qr{$regex2}i => 0},
    qq{Method undeny_regex() returns correct list});

eval { $info = $safe->undeny_regex([qr{$regex1}, qr{$regex2}i]); };
is($@, q{},
    qq{Method undeny_regex() works with an arrayref argument});
is_deeply($info, {qr{$regex2} => 0},
    qq{Method undeny_regex() returns correct list});

eval { $safe->do("SELECT 789"); };
is($@, q{},
    qq{Method undeny_regex() clears out entries, allowing statements to run});


#
# Tests for transactional methods
#

eval { $safe->begin_work(); };
like($@, qr{not allowed},
    qq{Method begin_work() does not work before being allowed});

eval { $safe->commit(); };
like($@, qr{not allowed},
    qq{Method commit() does not work before being allowed});
eval { $safe->rollback(); };
like($@, qr{not allowed},
    qq{Method rollback() does not work before being allowed});

$safe->allow_command('begin begin_work commit release rollback');
$dbh->{PrintError} = 0;
eval { $safe->begin_work(); };
like($@, qr{in a transaction},
    qq{Method begin_work() can be run when specifically allowed});
eval { $safe->commit(); };
is($@, q{},
    qq{Method commit() can be run when specifically allowed});
eval { $safe->rollback(); };
is($@, q{},
    qq{Method rollback() can be run when specifically allowed});

eval { $safe->do("COMMIT this"); };
like($@, qr{Cannot use},
    qq{Cannot use "commit" in normal SQL});
eval { $safe->do("ROLLBACK that"); };
like($@, qr{Cannot use},
    qq{Cannot use "rollback" in normal SQL});
eval { $safe->do("RELEASE me"); };
like($@, qr{Cannot use},
    qq{Cannot use "release" in normal SQL});
eval { $safe->do("BEGIN again"); };
like($@, qr{Cannot use},
    qq{Cannot use "begin" in normal SQL});
$safe->unallow_command('begin begin_work commit release rollback');


#
# Tests for the do() method
#

eval { $safe->do("SELECT 123"); };
is($@, q{},
    qq{Method do() works with allowed commands});

eval { $safe->do("SELECT 123; SELECT 345"); };
like($@, $NOMULTI,
    qq{Method do() fails with multiple statements});
$dbh->rollback();

eval { $safe->do("SELECT ?::text", 123); };
is($@, q{},
    qq{Method do() works with allowed commands and placeholders});

eval { $safe->do("SELECT ?::text; SELECT 345", 123); };
like($@, $NOMULTI,
    qq{Multiple statements to do() with placeholders fail});
$dbh->rollback();


#
# Test for the prepare() method
#

eval { $sth = $safe->prepare("SELECT 123::text"); };
is($@, q{},
    qq{Method prepare() works with allowed commands});

eval { $sth = $safe->prepare("INSERT 123::text"); };
like($@, $NORUN,
    qq{Method prepare() fails with unallowed commands});

eval { $sth = $safe->prepare("SELECT 123::text ; LISTEN to_me "); };
like($@, $NOMULTI,
    qq{Method prepare() fails with multiple statements});
$dbh->rollback();

eval { $sth = $safe->prepare("SELECT ?::text", "123"); };
is($@, q{},
    qq{Method prepare() works with allowed commands and placeholders});

eval { $sth = $safe->prepare("INSERT ?::text", "123"); };
like($@, $NORUN,
    qq{Method prepare() fails with unallowed commands and placeholders});

eval { $sth = $safe->prepare("SELECT ?::text ; LISTEN to_me ", "123"); };
like($@, $NOMULTI,
    qq{Method prepare() fails with multiple statements and placeholders});
$dbh->rollback();

$sth = $safe->prepare("SELECT 123::text");
isa_ok($sth, 'DBI::st',
    qq{Correct object is returned from method prepare()});

eval { $sth->execute(); };
is($@, q{},
    qq{Handle returned by method prepare() can be executed});

$dbh->{RaiseError} = 0;
$dbh->{PrintError} = 0;
eval { $sth->execute(123); };
like($@, qr{when 0 are needed},
    qq{Handle returned by method prepare() dies with invalid number of arguments});

$sth = $safe->prepare("SELECT ?::text");
eval { $sth->execute(456); };
is($@, q{},
    qq{Handle returned by method prepare() with placeholders can be executed});


#
# Tests of the various dbh 'utility' access methods
#


$SQL = "SELECT 1 AS id, 2, 3";
eval { $info = $safe->selectall_arrayref($SQL); };
is($@, q{},
    qq{Method selectall_arrayref() works});
$expected = $dbh->selectall_arrayref($SQL);
is_deeply($info, $expected,
    qq{Method selectall_arrayaref() returns correct information});
eval { $safe->selectall_arrayref("$SQL; $SQL"); };
like($@, $NOMULTI,
    qq{Method selectall_arrayaref() fails when sent multiple statements});
$dbh->rollback();

eval { $info = $safe->selectall_hashref($SQL,'id'); };
is($@, q{},
    qq{Method selectall_hashref() works});
$expected = $dbh->selectall_hashref($SQL, 'id');
is_deeply($info, $expected,
    qq{Method selectall_hashref() returns correct information});
eval { $safe->selectall_hashref("$SQL;$SQL", 'id'); };
like($@, $NOMULTI,
    qq{Method selectall_hashref() fails when sent multiple statements});
$dbh->rollback();

eval { $info = $safe->selectcol_arrayref($SQL); };
is($@, q{},
    qq{Method selectcol_arrayref() works});
$expected = $dbh->selectcol_arrayref($SQL);
is_deeply($info, $expected,
    qq{Method selectcol_arrayref() returns correct information});
eval { $safe->selectcol_arrayref("$SQL;$SQL", 'id'); };
like($@, $NOMULTI,
    qq{Method selectcol_arrayref() fails when sent multiple statements});
$dbh->rollback();

eval { $info = $safe->selectrow_array($SQL); };
is($@, q{},
    qq{Method selectrow_array() works});
$expected = $dbh->selectrow_array($SQL);
is_deeply($info, $expected,
    qq{Method selectrow_array() returns correct information});
eval { $safe->selectrow_array("$SQL;$SQL", 'id'); };
like($@, $NOMULTI,
    qq{Method selectrow_array() fails when sent multiple statements});
$dbh->rollback();

eval { $info = $safe->selectrow_arrayref($SQL); };
is($@, q{},
    qq{Method selectrow_arrayref() works});
$expected = $dbh->selectrow_arrayref($SQL);
is_deeply($info, $expected,
    qq{Method selectrow_arrayref() returns correct information});
eval { $safe->selectrow_arrayref("$SQL;$SQL", 'id'); };
like($@, $NOMULTI,
    qq{Method selectrow_arrayref() fails when sent multiple statements});
$dbh->rollback();

eval { $info = $safe->selectrow_hashref($SQL); };
is($@, q{},
    qq{Method selectrow_hashref() works});
$expected = $dbh->selectrow_hashref($SQL);
is_deeply($info, $expected,
    qq{Method selectrow_hashref() returns correct information});
eval { $safe->selectrow_hashref("$SQL;$SQL", 'id'); };
like($@, $NOMULTI,
    qq{Method selectrow_hashref() fails when sent multiple statements});
$dbh->rollback();


#
# Tests for the prepare_cached() method
#

eval { $safe->prepare_cached("SELECT 123::int"); };
like($@, qr{not supported yet},
    qq{Method prepare_cached() fails to work});


#
# Tests for read-only database handle methods
#

eval { $safe->quote(q{It's "hammer" time}); };
like($@, qr{Calling method 'quote' is not allowed},
    qq{Method quote() does not work by default});
$safe->allow_command('quote');
eval { $info = $safe->quote(q{It's "hammer" time}); };
is($@, q{},
    qq{Method quote() works});
is($info, qq{'It''s "hammer" time'},
    qq{Method quote() returns the expected output});
$safe->unallow_command('quote');

eval { $safe->quote_identifier(q{It's "hammer" time}); };
like($@, qr{Calling method 'quote_identifier' is not allowed},
    qq{Method quote_identifier() does not work by default});
$safe->allow_command('quote_identifier');
eval { $info = $safe->quote_identifier(q{It's "hammer" time}); };
is($@, q{},
    qq{Method quote_identifier() works});
is($info, qq{"It's ""hammer"" time"},
    qq{Method quote_identifier() returns the expected output});
$safe->unallow_command('quote_identifier');

# Throw an error on purpose
eval { $safe->do("SELECT 1/0"); };
is($@, q{},
    qq{SELECT 1/0 throws an error for future testing});
$dbh->rollback;

eval { $safe->err; };
like($@, qr{Calling method 'err' is not allowed},
    qq{Method err() does not work by default});
$safe->allow_command('err');
eval { $info = $safe->err; };
is($@, q{},
   qq{Method err() did not return an error});
is_deeply($info, $dbh->err,
   qq{Method err() returns the correct value});
$safe->unallow_command('err');

eval { $safe->errstr; };
like($@, qr{Calling method 'errstr' is not allowed},
    qq{Method errstr() does not work by default});
$safe->allow_command('errstr');
eval { $info = $safe->errstr; };
is($@, q{},
   qq{Method errstr() did not return an error});
is_deeply($info, $dbh->errstr,
   qq{Method errstr() returns the correct value});
$safe->unallow_command('errstr');

eval { $safe->state; };
like($@, qr{Calling method 'state' is not allowed},
    qq{Method state() does not work by default});
$safe->allow_command('state');
eval { $info = $safe->state; };
is($@, q{},
   qq{Method state() did not return an error});
is_deeply($info, $dbh->state,
   qq{Method state() returns the correct value});
$safe->unallow_command('state');

## Rollback our errors from above
$dbh->rollback();

eval { $safe->can('execute'); };
like($@, qr{Calling method 'can' is not allowed},
    qq{Method can() does not work by default});
$safe->allow_command('can');
eval { $info = $safe->can('execute'); };
is($@, q{},
   qq{Method can() did not return an error});
is_deeply($info, $dbh->can('execute'),
   qq{Method can() returns the correct value});
$safe->allow_command('can');

eval { $safe->parse_trace_flag(1); };
like($@, qr{Calling method 'parse_trace_flag' is not allowed},
    qq{Method parse_trace_flag() does not work by default});
$safe->allow_command('parse_trace_flag');
eval { $info = scalar $safe->parse_trace_flag(1); };
is($@, q{},
   qq{Method parse_trace_flag() did not return an error});
my $expected = $dbh->parse_trace_flag(1);
is(defined $info ? $info : "UNDEF", defined $expected ? $expected : "UNDEF",
   qq{Method parse_trace_flag() returns the correct value});
$safe->unallow_command('can');

eval { $safe->parse_trace_flags(3); };
like($@, qr{Calling method 'parse_trace_flags' is not allowed},
    qq{Method parse_trace_flags() does not work by default});
$safe->allow_command('parse_trace_flags');
eval { $info = $safe->parse_trace_flags(3); };
is($@, q{},
   qq{Method parse_trace_flags() did not return an error});
is_deeply($info, $dbh->parse_trace_flags(3),
   qq{Method parse_trace_flags() returns the correct value});
$safe->unallow_command('parse_trace_flags');

eval { $safe->data_sources(); };
like($@, qr{no},
   qq{Method data_sources() does not run by default});
$safe->allow_command('data_sources');
eval { $info = $safe->data_sources(); };
is($@, q{},
   qq{Method data_sources() works once allowed});
$expected = $dbh->data_sources;
is_deeply($info, $expected,
   qq{Method data_sources() returns the correct value});
$safe->unallow_command('data_sources');

eval { $safe->last_insert_id(1,2,3,4); };
like($@, qr{Calling method 'last_insert_id' is not allowed},
   qq{Method last_insert_id() does not run by default});
$safe->allow_command('last_insert_id');
eval { $safe->last_insert_id(1,2,3,4); };
unlike($@, qr{Calling method 'last_insert_id' is not allowed},
   qq{Method last_insert_id() works once allowed});
$safe->unallow_command('last_insert_id');

eval { $safe->table_info(1,2,3,4); };
like($@, qr{Calling method 'table_info' is not allowed},
   qq{Method table_info() does not run by default});
$safe->allow_command('table_info');
eval { $safe->table_info(1,2,3,4); };
unlike($@, qr{Calling method 'table_info' is not allowed},
   qq{Method table_info() works once allowed});
$safe->unallow_command('table_info');

eval { $safe->column_info(1,2,3,4); };
like($@, qr{Calling method 'column_info' is not allowed},
   qq{Method column_info() does not run by default});
$safe->allow_command('column_info');
eval { $safe->column_info(1,2,3,4); };
unlike($@, qr{Calling method 'column_info' is not allowed},
   qq{Method column_info() works once allowed});
$safe->unallow_command('column_info');

eval { $safe->primary_key_info(1,2,3,4); };
like($@, qr{Calling method 'primary_key_info' is not allowed},
   qq{Method primary_key_info() does not run by default});
$safe->allow_command('primary_key_info');
eval { $safe->primary_key_info(1,2,3,4); };
unlike($@, qr{Calling method 'primary_key_info' is not allowed},
   qq{Method primary_key_info() works once allowed});
$safe->unallow_command('primary_key_info');

eval { $safe->ping; };
like($@, qr{Calling method 'ping' is not allowed},
   qq{Method ping() does not run by default});
$safe->allow_command('ping');
eval { $info = $safe->ping; };
is($@, q{},
   qq{Method ping() works once allowed});
is_deeply($info, $dbh->ping,
    qq{Method 'ping' returns the correct value});
$safe->unallow_command('ping');


eval { $safe->get_info(17); };
like($@, qr{Calling method 'get_info' is not allowed},
   qq{Method get_info() does not run by default});
$safe->allow_command('get_info');
eval { $info = $safe->get_info(17); };
is($@, q{},
   qq{Method get_info() works once allowed});
is_deeply($info, $dbh->get_info(17),
    qq{Method 'get_info' returns the correct value});
$safe->unallow_command('get_info');


#
# Tests for read/write database handle methods
#

eval { $info = $safe->trace; };
is($@, q{},
   qq{Method trace() did not return an error});
is_deeply($info, $dbh->trace,
   qq{Method trace() returns the correct value});

eval { $safe->trace(0); };
like($@, qr{Calling method 'trace' with arguments is not allowed},
   qq{Method trace() not allowed by default});

$safe->allow_command('trace');
eval { $safe->trace(0); };
is($@, q{},
   qq{Method trace() allowed after passed to allow_command});

eval { $info = $safe->trace; };
is($@, q{},
   qq{Method trace() did not return an error});
is_deeply($info, $dbh->trace,
   qq{Method trace() returns the correct value});
$safe->unallow_command('trace');


#
# Tests for write-only database handle methods
#

eval { $safe->trace_msg('DBIx::Safe testing'); };
like($@, qr{Calling method 'trace_msg' is not allowed},
   qq{Method trace_msg() is not allowed by default});

$safe->allow_command('trace_msg');
eval { $safe->trace_msg('DBIx::Safe testing'); };
is($@, q{},
   qq{Method trace_msg() allowed after passed to allow_command});
$safe->unallow_command('trace_msg');

eval { $safe->func('DBIx::Safe func testing'); };
like($@, qr{Calling method 'func' is not allowed},
   qq{Method func() is not allowed by default});

$safe->allow_command('func');
eval { $safe->func('DBIx::Safe testing'); };
unlike($@, qr{Calling method 'func' is not allowed},
   qq{Method func() allowed after passed to allow_command});
$safe->unallow_command('func');
$dbh->rollback();


#
# Test of Postgres pg_ table restrictions
#

SKIP: {
    skip 'Postgres specific tests', 9 if $dbtype ne 'Pg';

    ## Recipe for disallowing changes to the system tables:
    $safe->deny_regex(qr{/\*}); ## No SQL comments
    $safe->deny_regex(qr{^update\s+["\s]*pg_}i);
    $safe->deny_regex(qr{^insert\s+into\s+["\s]*pg_}i);
    $safe->deny_regex(qr{^delete\s+from\s+["\s]*pg_}i);
    $safe->allow_command("insert update delete");

    eval { $safe->do("UPDATE pg_class SET nefarious=1"); };
    like($@, $FORBID,
        qq{Method do() fails when updating system tables});
    eval { $safe->do("INSERT INTO pg_class(foobar) VALUES (1)"); };
    like($@, $FORBID,
        qq{Method do() fails when inserting into system tables});
    eval { $safe->do("DELETE FROM pg_class WHERE wontwork=1"); };
    like($@, $FORBID,
        qq{Method do() fails when deleting from system tables});

    eval { $safe->do(qq{UPDATE "pg_class" SET nefarious=1}); };
    like($@, $FORBID,
        qq{Method do() fails when updating system tables using quotes});
    eval { $safe->do(qq{UPDATE pg_catalog.pg_class SET nefarious=1}); };
    like($@, $FORBID,
        qq{Method do() fails when updating system tables using schema});
    eval { $safe->do(qq{UPDATE "pg_catalog.pg_class" SET nefarious=1}); };
    like($@, $FORBID,
        qq{Method do() fails when updating system tables using schema and quotes});
    eval { $safe->do(qq{UPDATE "pg_catalog"."pg_class" SET nefarious=1}); };
    like($@, $FORBID,
        qq{Method do() fails when updating system tables using schema and quotes});
    eval { $safe->do(qq{  DELETE   FROM\t"pg_class" WHERE wontwork=1}); };
    like($@, $FORBID,
        qq{Method do() fails when updating system tables using funky whitespace});
    eval { $safe->do(qq{UPDATE /* comment */ "pg_catalog"."pg_class" SET nefarious=1}); };
    like($@, $FORBID,
        qq{Method do() fails when updating system tables using comments});

} ## end Postgres specific tests
