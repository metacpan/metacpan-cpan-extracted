#!/usr/bin/perl

# Create this table before running the test:
#
# CREATE TABLE debug_connections (
# hostid text not null,
# clientpid integer not null,
# backendpid integer not null,
# msg text,
# secs double precision,
# datestamp timestamptz not null default now(),
# lastseen timestamptz not null,
# PRIMARY KEY (hostid, clientpid, backendpid)
# );


use strict;
use warnings;
use utf8;
use Test::More;
use Data::Dumper;
use File::Temp qw(tempfile);
use Time::HiRes qw(sleep);

$| = 1;

my ($dbname,$dbhost,$dbport,$dbuser,$dbpass);

BEGIN {

    $dbname = $ENV{TEST_DBNAME} || 'dbixquerybynametestdb';
    $dbhost = $ENV{TEST_DBHOST} || 'localhost';
    $dbport = $ENV{TEST_DBPORT} || 5432;
    $dbuser = $ENV{TEST_DBUSER} || '';
    $dbpass = $ENV{TEST_DBPASS} || '';

    # skip test if missing dependency
    foreach my $m ('XML::Parser','XML::SimpleObject','DBI','DBD::Pg','Test::Exception','Log::Log4perl','File::Slurp') {
        eval "use $m";
        plan skip_all => "test require missing module $m" if $@;
    }

    # see if we have a postgres db to play with
    plan skip_all => "test require a osx host" if ($^O !~ /(darwin|linux)/);

    my $psql     = `which psql`;     chomp $psql;
    my $createdb = `which createdb`; chomp $createdb;
    my $dropdb   = `which dropdb`;   chomp $dropdb;

    plan skip_all => "test require a postgres database" if ($psql !~ /psql/);
    plan skip_all => "cannot find createdb" if ($createdb !~ /createdb/);
    plan skip_all => "cannot find dropdb" if ($dropdb !~ /dropdb/);

    if (`$psql -l` =~ /$dbname/) {
        system("$dropdb $dbname");
    }

    system("$createdb $dbname");

    plan skip_all => "test require a database called $dbname" if (`$psql -l` !~ /$dbname/);

    # we can test :)
    plan tests => 109;

    use_ok("DBIx::QueryByName");
    use_ok("Log::Log4perl", qw(:easy));
}

my $dbconn = "dbi:Pg:dbname=$dbname;host=$dbhost;port=$dbport";

# before testing anything, we need to setup a simple test database
my @sqls = (
    'CREATE TABLE debug_connections (
    hostid text not null,
    clientpid integer not null,
    backendpid integer not null,
    msg text,
    secs double precision,
    datestamp timestamptz not null default now(),
    lastseen timestamptz not null,
    PRIMARY KEY (hostid, clientpid, backendpid)
    );
    ',

	'CREATE LANGUAGE plpgsql;
	CREATE OR REPLACE FUNCTION pg_sleep_echo_backend_pid(
	_secs double precision,
	_msg text,
	_hostid text,
	_clientpid integer
	) RETURNS INTEGER AS $BODY$
	DECLARE
	_backendpid integer;
	BEGIN
	    _backendpid := pg_backend_pid();
	    PERFORM pg_sleep(_secs);
	    PERFORM 1 FROM debug_connections WHERE backendpid = _backendpid AND hostid = _hostid AND clientpid = _clientpid;
	    IF FOUND THEN
	        UPDATE debug_connections SET lastseen = now(), msg = _msg WHERE backendpid = _backendpid AND hostid = _hostid AND clientpid = _clientpid;
	    ELSE
	        INSERT INTO debug_connections (hostid,clientpid,backendpid,msg,secs,lastseen) VALUES (_hostid,_clientpid,_backendpid,_msg,_secs,now());
	    END IF;
	    RETURN _backendpid;
	END;
	$BODY$ LANGUAGE plpgsql;
    '
    );

my $dbhpg = DBI->connect($dbconn, $dbuser, $dbpass, { RaiseError => 1 });
$dbhpg->{Warn} = 0;
foreach my $sql (@sqls) {
    my $rs = $dbhpg->prepare($sql);

    die "ERROR: 'prepare' failed for [$sql]: ".$dbhpg->errstr
	if (!$rs || $rs->err);

    die "ERROR: 'execute' failed for [$sql]: ".$rs->errstr
	if (!$rs->execute());
}
$dbhpg->disconnect;

lives_ok { Log::Log4perl->easy_init('DEBUG'); } "Log::Log4perl init";

# now we can start testing!
my $dbh = DBIx::QueryByName->new();
is(ref $dbh, 'DBIx::QueryByName', "new: bless properly");

my (undef,$tmpq) = tempfile();

my $queries = <<__ENDQ1__;
<queries>
    <query name="null" params="" result="scalar">SELECT NULL</query>
    <query name="pg_sleep_echo_backend_pid" params="secs,msg,hostid,clientpid" result="scalar" retry="always">SELECT pg_sleep_echo_backend_pid(?,?,?,?)</query>
</queries>
__ENDQ1__

write_file($tmpq,$queries);
lives_ok { $dbh->load(session => 'db', from_xml_file => $tmpq) } "load queries for session db (using from_xml_file)";

# connection settings
throws_ok { $dbh->null( {} ) } qr/don't know how to open connection/, "can't query until connect() called";
$dbh->connect('db', $dbconn, $dbuser, $dbpass);

# can?
is($dbh->can("null"), 1, "can(null)");
is($dbh->can("pg_sleep_echo_backend_pid"), 1, "can(pg_sleep_echo_backend_pid)");
is($dbh->can("invalid_query_name"), 0, "can(invalid_query_name)");

# 100 calls, sleeping 0.1 seconds in the database
my $secs = 0.1;
for (my $i=0; $i<100; $i++) {
    ok($dbh->pg_sleep_echo_backend_pid({secs => $secs, msg => 'stress.t', hostid => `/bin/hostname`, clientpid => $$}) >= 1, "pg_sleep_echo_backend_pid $secs, iteration $i");
}

__END__

# 10 slow calls, sleeping 10 seconds in the database
my $secs = 10;
for (my $i=0; $i<10; $i++) {
    ok($dbh->pg_sleep_echo_backend_pid({secs => $secs, msg => 'stress.t', hostid => `/bin/hostname`, clientpid => $$}) >= 1, "pg_sleep_echo_backend_pid $secs, iteration $i");
}

# Increase sleep with 30 between each call to detect eventual TCP timeout setting
$secs = 0;
for (my $i=0; $i<1000; $i++) {
    $secs += 30;
    diag "sleep($secs)";
    next if $i < 60;
    sleep($secs);
    eval {
        ok($dbh->pg_sleep_echo_backend_pid({secs => 0.1, msg => 'stress.t', hostid => `/bin/hostname`, clientpid => $$}) >= 1, "pg_sleep_echo_backend_pid $secs, iteration $i");
    };
    if ($@) {
        # DB connection error
        last;
    }
}

