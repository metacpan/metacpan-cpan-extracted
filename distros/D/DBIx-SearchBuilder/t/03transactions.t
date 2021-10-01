#!/usr/bin/perl -w


use strict;
use warnings;
use Test::More;
BEGIN { require "./t/utils.pl" }
our (@AvailableDrivers);

use constant TESTS_PER_DRIVER => 52;

my $total = scalar(@AvailableDrivers) * TESTS_PER_DRIVER;
plan tests => $total;

foreach my $d ( @AvailableDrivers ) {
SKIP: {
	unless( has_schema( 'TestApp::Address', $d ) ) {
		skip "No schema for '$d' driver", TESTS_PER_DRIVER;
	}
	unless( should_test( $d ) ) {
		skip "ENV is not defined for driver '$d'", TESTS_PER_DRIVER;
	}

	my $handle = get_handle( $d );
    isa_ok($handle, 'DBIx::SearchBuilder::Handle');
    { # clear PrevHandle
        no warnings 'once';
        $DBIx::SearchBuilder::Handle::PrevHandle = undef;
    }

diag("disconnected handle") if $ENV{'TEST_VERBOSE'};
    is($handle->TransactionDepth, undef, "undefined transaction depth");
    is($handle->BeginTransaction, undef, "couldn't begin transaction");
    is($handle->TransactionDepth, undef, "still undefined transaction depth");
    ok($handle->EndTransaction(Action => 'commit', Force => 1), "force commit success silently");
    ok($handle->Commit('force'), "force commit success silently");
    ok($handle->EndTransaction(Action => 'rollback', Force => 1), "force rollback success silently");
    ok($handle->Rollback('force'), "force rollback success silently");
    # XXX: ForceRollback function should deprecated
    ok($handle->ForceRollback, "force rollback success silently");
    {
        my $warn = 0;
        local $SIG{__WARN__} = sub{ $_[0] =~ /transaction with none in progress/? $warn++: warn @_ };
        ok(!$handle->Rollback, "not forced rollback returns false");
        is($warn, 1, "not forced rollback fires warning");
        ok(!$handle->Commit, "not forced commit returns false");
        is($warn, 2, "not forced commit fires warning");
    }

	connect_handle( $handle );
	isa_ok($handle->dbh, 'DBI::db');

diag("connected handle without transaction") if $ENV{'TEST_VERBOSE'};
    is($handle->TransactionDepth, 0, "transaction depth is 0");
    ok($handle->Commit('force'), "force commit success silently");
    ok($handle->Rollback('force'), "force rollback success silently");
    {
        my $warn = 0;
        local $SIG{__WARN__} = sub{ $_[0] =~ /transaction with none in progress/? $warn++: warn @_ };
        ok(!$handle->Rollback, "not forced rollback returns false");
        is($warn, 1, "not forced rollback fires warning");
        ok(!$handle->Commit, "not forced commit returns false");
        is($warn, 2, "not forced commit fires warning");
    }

diag("begin and commit empty transaction") if $ENV{'TEST_VERBOSE'};
    ok($handle->BeginTransaction, "begin transaction");
    is($handle->TransactionDepth, 1, "transaction depth is 1");
    ok($handle->Commit, "commit successed");
    is($handle->TransactionDepth, 0, "transaction depth is 0");

diag("begin and rollback empty transaction") if $ENV{'TEST_VERBOSE'};
    ok($handle->BeginTransaction, "begin transaction");
    is($handle->TransactionDepth, 1, "transaction depth is 1");
    ok($handle->Rollback, "rollback successed");
    is($handle->TransactionDepth, 0, "transaction depth is 0");

diag("nested empty transactions") if $ENV{'TEST_VERBOSE'};
    ok($handle->BeginTransaction, "begin transaction");
    is($handle->TransactionDepth, 1, "transaction depth is 1");
    ok($handle->BeginTransaction, "begin nested transaction");
    is($handle->TransactionDepth, 2, "transaction depth is 2");
    ok($handle->Commit, "commit successed");
    is($handle->TransactionDepth, 1, "transaction depth is 1");
    ok($handle->Commit, "commit successed");
    is($handle->TransactionDepth, 0, "transaction depth is 0");

diag("init schema in transaction and commit") if $ENV{'TEST_VERBOSE'};
    # MySQL doesn't support transactions for CREATE TABLE
    # so it's fake transactions test
    ok($handle->BeginTransaction, "begin transaction");
    is($handle->TransactionDepth, 1, "transaction depth is 1");
	my $ret = init_schema( 'TestApp::Address', $handle );
	isa_ok($ret, 'DBI::st', "Inserted the schema. got a statement handle back");
    ok($handle->Commit, "commit successed");
    is($handle->TransactionDepth, 0, "transaction depth is 0");

diag("nested txns with mixed escaping actions") if $ENV{'TEST_VERBOSE'};
    ok($handle->BeginTransaction, "begin transaction");
    ok($handle->BeginTransaction, "begin nested transaction");
    ok($handle->Rollback, "rollback successed");
    {
        my $warn = 0;
        local $SIG{__WARN__} = sub{ $_[0] =~ /Rollback and commit are mixed/? $warn++: warn @_ };
        ok($handle->Commit, "commit successed");
        is($warn, 1, "not forced rollback fires warning");
    }

    ok($handle->BeginTransaction, "begin transaction");
    ok($handle->BeginTransaction, "begin nested transaction");
    ok($handle->Commit, "rollback successed");
    {
        my $warn = 0;
        local $SIG{__WARN__} = sub{ $_[0] =~ /Rollback and commit are mixed/? $warn++: warn @_ };
        ok($handle->Rollback, "commit successed");
        is($warn, 1, "not forced rollback fires warning");
    }

	cleanup_schema( 'TestApp::Address', $handle );
}} # SKIP, foreach blocks

1;



package TestApp::Address;

use base qw/DBIx::SearchBuilder::Record/;

sub _Init {
    my $self = shift;
    my $handle = shift;
    $self->Table('Address');
    $self->_Handle($handle);
}

sub ValidateName
{
	my ($self, $value) = @_;
	return 0 if $value =~ /invalid/i;
	return 1;
}

sub _ClassAccessible {

    {   
        
        id =>
        {read => 1, type => 'int(11)', default => ''}, 
        Name => 
        {read => 1, write => 1, type => 'varchar(14)', default => ''},
        Phone => 
        {read => 1, write => 1, type => 'varchar(18)', length => 18, default => ''},
        EmployeeId => 
        {read => 1, write => 1, type => 'int(8)', default => ''},

}

}

sub schema_mysql {
<<EOF;
CREATE TEMPORARY TABLE Address (
        id integer AUTO_INCREMENT,
        Name varchar(36),
        Phone varchar(18),
        EmployeeId int(8),
  	PRIMARY KEY (id)) ENGINE='InnoDB'
EOF

}

sub schema_pg {
<<EOF;
CREATE TEMPORARY TABLE Address (
        id serial PRIMARY KEY,
        Name varchar,
        Phone varchar,
        EmployeeId integer
)
EOF

}

sub schema_sqlite {

<<EOF;
CREATE TABLE Address (
        id  integer primary key,
        Name varchar(36),
        Phone varchar(18),
        EmployeeId int(8))
EOF

}

sub schema_oracle { [
    "CREATE SEQUENCE Address_seq",
    "CREATE TABLE Address (
        id integer CONSTRAINT Address_Key PRIMARY KEY,
        Name varchar(36),
        Phone varchar(18),
        EmployeeId integer
    )",
] }

sub cleanup_schema_oracle { [
    "DROP SEQUENCE Address_seq",
    "DROP TABLE Address", 
] }

1;
