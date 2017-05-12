#!/usr/bin/perl -w
use strict;
use warnings;
use Test::More tests => 8;
use Net::MySQL;

BEGIN {
    use DBD::mysqlPP;
    {
        no warnings 'redefine';
        *DBD::mysqlPP::db::DESTROY = sub {};
    }
}

my $dbh = bless {}, 'DBD::mysqlPP::db';#create dummy dbh

sub bind_sql_ok {
    my ($sql, $params_aref, $expected_statement) = @_;

    local $Test::Builder::Level = $Test::Builder::Level + 1;

    my $sth = bless { Database => $dbh, Statement => $sql }, 'DBD::mysqlPP::st';# create dummy sth
    my $statement = DBD::mysqlPP::st::_mysqlpp_bind_statement($sth, $params_aref);
    is( $statement, $expected_statement);
}

# normal bind
bind_sql_ok('select * from test_table where param1 = ?',
            ['1'], 
            "select * from test_table where param1 = '1'");


# RT16763 Incorrect quoting of parameter values in LIMIT clause
bind_sql_ok('select * from test_table limit ?',
            [1],
            'select * from test_table limit 1');

bind_sql_ok('select * from test_table limit ?, ?',
            [1, 2],
            'select * from test_table limit 1, 2');
bind_sql_ok('select * from test_table limit ? offset ?',
            [1, 2],
            'select * from test_table limit 1 offset 2');


# JVN#51216285 SQL Injection
bind_sql_ok('select * from test_table where param1 = ? and param2 = ?',
            ['?', ' or 1=1--'],
            "select * from test_table where param1 = '?' and param2 = ' or 1=1--'");


# RT2595 Placeholders don't work if value contains '?'
bind_sql_ok('INSERT INTO t1 VALUES (?, ?, ?, ?)',
            [undef, 'this is a test?', '???', 'it is?'],
            "INSERT INTO t1 VALUES (NULL, 'this is a test?', '???', 'it is?')");

# RT1979 Broken functionality when using '?'-characters in data
# without placeholder
bind_sql_ok('INSERT INTO test_blobs SET data = ' . $dbh->quote('mydata?hoho?or'),
            [],
            "INSERT INTO test_blobs SET data = 'mydata?hoho?or'");
# with placeholder
bind_sql_ok('INSERT INTO test_blobs SET data = ?',
            ['mydata?hoho?or'],
            "INSERT INTO test_blobs SET data = 'mydata?hoho?or'");





