#!/usr/bin/perl -w
use strict;
use warnings;

use Test::More;
use DBIx::ResultSet::Connector;

my $connector = DBIx::ResultSet->connect( 'dbi:SQLite:dbname=t/test.db', '', '' );

$connector->run(sub{
    my ($dbh) = @_;

    $dbh->do('DROP TABLE IF EXISTS users');
    $dbh->do('CREATE TABLE users (user_id NUMBER, user_name TEXT, status NUMBER)');
});

my $users = $connector->resultset('users');
$users->insert( {user_id=>1, user_name=>'one',   status=>1} );
$users->insert( {user_id=>2, user_name=>'two',   status=>0} );
$users->insert( {user_id=>3, user_name=>'three', status=>1} );

my $on_users = $users->search({ status => 1 });
is( $on_users->table(), 'users', 'table' );
is_deeply( $on_users->where(), { status=>1 }, 'where' );

is( $on_users->search(undef, {order_by=>'user_name'})->clauses->{order_by}, 'user_name', 'order_by' );
is( $on_users->search(undef, {page=>3})->clauses->{page}, 3, 'page' );
is( $on_users->search(undef, {rows=>20})->clauses->{rows}, 20, 'rows' );

my $paged_rs = $users->search(undef, { page=>1, rows=>2, order_by=>'user_id' });
is( $paged_rs->last_page(), 2, 'last_page' );
is( $paged_rs->total_entries(), 3, 'total_entries' );

is_deeply( $paged_rs->column('user_id'), [1, 2], 'page 1' );
$paged_rs = $paged_rs->search(undef, { page=>2 });
is_deeply( $paged_rs->column('user_id'), [3], 'page 2' );

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->array_row(['user_id', 'user_name']),
    ['1', 'one'],
    'array_row',
);

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->hash_row(['user_id', 'user_name']),
    { user_id => '1', user_name => 'one' },
    'hash_row',
);

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->array_of_array_rows('user_id'),
    [[1],[2],[3]],
    'array_of_array_rows',
);

is_deeply(
    $users->search(undef,{order_by=>'user_id'})->array_of_hash_rows('user_name'),
    [{user_name=>'one'},{user_name=>'two'},{user_name=>'three'}],
    'array_of_hash_rows',
);

is_deeply(
    $users->hash_of_hash_rows('user_id', 'user_id'),
    {1=>{user_id=>1},2=>{user_id=>2},3=>{user_id=>3}},
    'hash_of_hash_rows',
);

is( $on_users->count(), 2, 'count' );

done_testing;
