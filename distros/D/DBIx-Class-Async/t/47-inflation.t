#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use File::Temp qw( tempfile );

use lib 't/lib';
use IO::Async::Loop;
use DBIx::Class::Async;

my (undef, $filename) = tempfile(UNLINK => 1);
my $loop = IO::Async::Loop->new;

# 1. Setup Async DB (No Cache)
my $db = DBIx::Class::Async->new(
    schema_class => 'TestSchema',
    connect_info => ["dbi:SQLite:dbname=$filename", '', ''],
    loop         => $loop,
);

# 2. Define a custom inflator for a column
$db->inflate_column('User', 'email', {
    inflate => sub { my $v = shift; return "mailto:$v" },
    deflate => sub { my $v = shift; $v =~ s/^mailto://; return $v },
});

my $test = $db->deploy->then(sub {
    # 3. Test Creation (Deflation Check)
    # We pass the "inflated" version, expecting it to be deflated before hitting DB
    return $db->create('User', {
        name  => 'Unit Tester',
        email => 'mailto:test@example.com'
    });
})->then(sub {
    my $row = shift;

    # 4. Check Inflation
    is($row->get_column('email'), 'mailto:test@example.com', "get_column returns inflated value");
    is($row->email, 'mailto:test@example.com', "Accessor returns inflated value");

    # 5. Check Internal Data (Should be raw)
    # This verifies that deflation happened before the data was stored/synced
    is($row->{_data}{email}, 'test@example.com', "Internal _data stores deflated/raw value");

    # 6. Test Manual set_column
    $row->email('mailto:new@example.com');
    ok($row->is_column_dirty('email'), "Setting column via accessor marks it dirty");

    return $row->update;
})->then(sub {
    my $row = shift;

    # 7. Final Verification via Round-trip
    return $db->find('User', $row->id);
})->then(sub {
    my $fresh_row = shift;
    is($fresh_row->email, 'mailto:new@example.com', "Round-trip inflation successful");
    is($fresh_row->{_data}{email}, 'new@example.com', "Round-trip raw data remains clean");

    $loop->stop;
    return Future->done;
})->on_fail(sub {
    diag "Unit Test Fail: @_";
    $loop->stop;
});

$loop->run;
done_testing;
