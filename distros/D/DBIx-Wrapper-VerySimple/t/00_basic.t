# $Header: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/00_basic.t,v 1.3 2006/11/01 17:15:17 matisse Exp $
# $Revision: 1.3 $
# $Author: matisse $
# $Source: /usr/local/CVS/perl-modules/DBIx-Wrapper-VerySimple/t/00_basic.t,v $
# $Date: 2006/11/01 17:15:17 $
###############################################################################

use strict;
use warnings;
use English qw(-no_match_vars);
use FindBin qw($Bin);
use Test::More tests => 20;

# Ensure that DBIx::Wrapper::VerySimple loads our mock DBI.pm
use lib "$Bin/mock_lib";
use DBI;
use DBI::Mock::dbh;
use DBI::Mock::sth;

my $EMPTY_STRING   = q{};
my $MOCK_DBH_CLASS = 'DBI::Mock::dbh';
my $MOCK_STH_CLASS = 'DBI::Mock::sth';
my $TEST_DSN       = 'DBI:This:is:a:test';
my $TEST_USER      = 'test_user';
my $TEST_PASSWORD  = 'test_password';
my $FAILURE_STRING = 'TEST_FAILURE';

test_compile();
test_new();
test_dbh();
test_Do();
test_FetchAll();
test_FetchHash();
test_get_args();
test_aliases();

exit;
###############################################################################



sub test_compile {
    use_ok('DBIx::Wrapper::VerySimple');
    return 1;
}

sub test_new {
    my $object = set_up();
    isa_ok( $object, 'DBIx::Wrapper::VerySimple' );
    return 1;
}

sub test_dbh {
    my $object = set_up();
    isa_ok( $object->dbh(), $MOCK_DBH_CLASS, 'dbh() method' );
    return 1;
}

sub test_Do {
    my $object      = set_up();
    my $sql         = 'SELECT something FROM somewhere WHERE a=? AND b=?';
    my @bind_values = qw(test_value another_test_value);
    my $result      = $object->Do( $sql, @bind_values );
    isa_ok( $result, $MOCK_STH_CLASS, 'Do() - prepare_cached() called.' );
    is_deeply( $result->{bind_values},
        \@bind_values, 'Do() - bind_values passed to execute()' );

    eval { $object->Do($FAILURE_STRING) };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'Do() throws exception when prepare_cached fails.' );
    eval { $object->Do( $sql, $FAILURE_STRING ) };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'Do() throws exception when execute fails.' );
    return 1;
}

sub test_FetchAll {
    my $object      = set_up();
    my $sql         = 'mock SQL statement';
    my @bind_values = qw(test_value another_test_value);
    my $result      = $object->FetchAll( $sql, @bind_values );
    isa_ok( $result, 'ARRAY', 'FetchAll() returns ARRAY ref' );
    my $mock_sth = $result->[0]->{sth};
    is( $mock_sth->{sql}, $sql,
        'FetchAll() calls prepare_cached with provided SQL' );
    is_deeply( $mock_sth->{bind_values},
        \@bind_values, 'FetchAll() - bind_values passed to execute()' );

    eval { $object->FetchAll($FAILURE_STRING) };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'FetchAll() throws exception when prepare_cached fails.' );
    eval { $object->FetchAll( $sql, $FAILURE_STRING ) };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'FetchAll() throws exception when execute fails.' );
    return 1;
}

sub test_FetchHash {
    my $object      = set_up();
    my $sql         = 'mock SQL statement';
    my @bind_values = qw(test_value another_test_value);
    my $result      = $object->FetchHash( $sql, @bind_values );
    isa_ok( $result, 'HASH', 'FetchHash() returns HASH ref' );
    my $mock_sth = $result->{sth};
    is( $mock_sth->{sql}, $sql,
        'FetchHash() calls prepare_cached with provided SQL' );
    is_deeply( $mock_sth->{bind_values},
        \@bind_values, 'FetchHash() - bind_values passed to execute()' );

    eval { $object->FetchHash($FAILURE_STRING) };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'FetchHash() throws exception when prepare_cached fails.' );
    eval { $object->FetchHash( $sql, $FAILURE_STRING ) };
    isnt( $EVAL_ERROR, $EMPTY_STRING,
        'FetchHash() throws exception when execute fails.' );
    return 1;
}

sub test_get_args {
    my $object = set_up();
    is_deeply(
        $object->get_args(),
        [ $TEST_DSN, $TEST_USER, $TEST_PASSWORD ],
        'get_args() recovers original args to new()'
    );
    return 1;    
}

sub test_aliases {
    my $object = set_up();
    can_ok($object, 'fetch_all');
    can_ok($object, 'fetch_hash');
}

sub set_up {
    my $object
      = DBIx::Wrapper::VerySimple->new( $TEST_DSN, $TEST_USER, $TEST_PASSWORD );
    return $object;
}
