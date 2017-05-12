#!/usr/bin/env perl

use strict;
use warnings;
use Test::Most;
use Test::Requires {'DBD::SQLite' => 1.0};

# Copied/portet from sqlite.t from DBIx::Simple

use_ok 'DBIx::Simplish';
my $db = new_ok 'DBIx::Simplish' => [dsn => 'dbi:SQLite:dbname=:memory:', options => {PrintError => 0}];
my $query = 'SELECT * FROM xyzzy ORDER BY foo';

throws_ok {$db->query('SYNTAX ERR0R !¤#!¤#')} qr/prepare_cached failed/;

ok $db->query('CREATE TABLE xyzzy (FOO, bar, baz)');
ok $db->query('INSERT INTO xyzzy (FOO, bar, baz) VALUES (?, ?, ?)', qw/a b c/);
is_deeply [$db->query($query)->flat], [qw/a b c/];
ok $db->query('INSERT INTO xyzzy VALUES (??)', qw/d e f/);
is_deeply [$db->query($query)->flat], [qw/a b c d e f/];
ok $db->query(q/INSERT INTO xyzzy VALUES (?, '(??)', ?)/, qw/g h/);
is_deeply [$db->query($query)->flat], [qw/a b c d e f g (??) h/];
is_deeply scalar $db->query($query)->list, 'c';
is_deeply [$db->query($query)->list], [qw/a b c/];
is_deeply $db->query($query)->array, [qw/a b c/];
is_deeply scalar $db->query($query)->arrays, [[qw/a b c/], [qw/d e f/], [qw/g (??) h/]];
is_deeply $db->query($query)->hash, {qw/foo a bar b baz c/};
is_deeply scalar $db->query($query)->hashes, [{qw/foo a bar b baz c/}, {qw/foo d bar e baz f/}, {qw/foo g bar (??) baz h/}];

is_deeply [$db->query($query)->kv_list], [qw/foo a bar b baz c/];
is_deeply scalar
          $db->query($query)->kv_list,   [qw/foo a bar b baz c/];
is_deeply $db->query($query)->kv_array , [qw/foo a bar b baz c/];

is_deeply scalar $db->query($query)->kv_arrays, [[qw/foo a bar b baz c/], [qw/foo d bar e baz f/], [qw/foo g bar (??) baz h/]];
is_deeply scalar $db->query($query)->kv_flat,    [qw/foo a bar b baz c        foo d bar e baz f        foo g bar (??) baz h/];

is_deeply scalar $db->query($query)->columns, [qw/foo bar baz/];

is_deeply [$db->query($query)->arrays], scalar $db->query($query)->arrays;
is_deeply [$db->query($query)->hashes], scalar $db->query($query)->hashes;
is_deeply [$db->query($query)->kv_flat], scalar $db->query($query)->kv_flat;
is_deeply [$db->query($query)->kv_arrays], scalar $db->query($query)->kv_arrays;
is_deeply [$db->query($query)->columns], scalar $db->query($query)->columns;

is_deeply scalar $db->query($query)->map_arrays(2), {c => [qw/a b/], f => [qw/d e/], h => [qw/g (??)/]};
is_deeply scalar $db->query($query)->map_hashes('baz'), {c => {qw/foo a bar b/}, f => {qw/foo d bar e/}, h => {qw/foo g bar (??)/}};
is_deeply scalar $db->query('SELECT foo, bar FROM xyzzy ORDER BY foo')->map, {qw/a b d e g (??)/};

$db->lc_columns(0);

is_deeply $db->query($query)->hash, {qw/FOO a bar b baz c/};
is_deeply scalar $db->query($query)->hashes, [{qw/FOO a bar b baz c/}, {qw/FOO d bar e baz f/}, {qw/FOO g bar (??) baz h/}];
is_deeply scalar $db->query($query)->columns, [qw/FOO bar baz/];
is_deeply scalar $db->query($query)->map_hashes('baz'), {c => {qw/FOO a bar b/}, f => {qw/FOO d bar e/}, h => {qw/FOO g bar (??)/}};

$db->lc_columns(1);

my $c = 'c';
is_deeply scalar $db->iquery('SELECT * FROM xyzzy WHERE baz =', \$c)->array, [qw/a b c/];

## no critic (ProhibitMagicNumbers)

sub Mock::new_from_dbix_simplish {
    my ($class, $result, @foo) = @_;
    isa_ok $result, 'DBIx::Simplish::Result';
    is_deeply \@foo, [42, 21];
    return wantarray;
}

ok !$db->query($query)->object('Mock', 42, 21);
is_deeply       [$db->query($query)->objects('Mock', 42, 21)], [1];
is_deeply scalar $db->query($query)->objects('Mock', 42, 21),  [1];

## use critic

ok $db->disconnect;

done_testing;
