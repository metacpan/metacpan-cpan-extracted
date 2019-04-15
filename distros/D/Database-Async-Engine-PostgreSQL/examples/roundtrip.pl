#!/usr/bin/env perl 
use strict;
use warnings;

no indirect;

use Test::More;
use Test::Fatal;
use Future::AsyncAwait;
use Syntax::Keyword::Try;

use IO::Async::Loop;
use Database::Async;
use Database::Async::Engine::PostgreSQL;

use Log::Any::Adapter;
use Log::Any qw($log);

use Getopt::Long;

GetOptions(
    'u|uri=s' => \my $uri,
    'd|dsn=s' => \my $dsn,
    'l|log=s' => \my $log_level,
) or die;

$log_level //= 'info';

Log::Any::Adapter->import(
    qw(Stdout), log_level => $log_level
);

$uri //= Database::Async::Engine::PostgreSQL->uri_for_dsn($dsn) if $dsn;
$uri //= URI->new('postgresql://postgres@127.0.0.1?sslmode=prefer');

my $loop = IO::Async::Loop->new;

$loop->add(
    my $db = Database::Async->new(
        uri => $uri,
    )
);

(async sub {
    $log->debugf('Execute single query');
    $log->infof('Have result: %s', await $db->query('select 1')->single);
    $log->debugf('Start a transaction');
    await $db->query('begin')->void;
    $log->debugf('Execute another single query within transaction');
    $log->infof('Have result: %s', await $db->query('select 1')->single);
    $log->debugf('Create a temporary table');
    await $db->query(q{create temporary table roundtrip_one ( id bigserial not null primary key, name text, created timestamptz default 'now')})->void;
    $log->debugf('Populate some rows in that table');
    await $db->query('insert into roundtrip_one (name) select generate_series(1,100)')->void;
    $log->infof('First 5 rows:');
    await $db->query('select * from roundtrip_one order by id limit 5')
        ->row_hashrefs
        ->map(sub {
            $log->infof(
                'ID %s has name %s with creation date %s (original %s)',
                $_->{id}, $_->{name}, $_->{created},
                $_
            )
        })
        ->completed;
    $log->infof('First 5 rows as arrayrefs:');
    await $db->query('select id, name, created from roundtrip_one order by id limit 5')
        ->row_arrayrefs
        ->map(sub {
            $log->infof(
                'ID %s has name %s with creation date %s',
                @$_
            )
        })
        ->completed;
    $log->infof('First 5 rows via COPY:');
    await $db->query('copy (select id, name, created from roundtrip_one order by id limit 5) to stdout')
        # There's no RowDescription event for these, so the only available
        # options here are those which stream arrayrefs (or ignore the output)
        ->row_arrayrefs
        ->map(sub {
            $log->infof(
                'ID %s has name %s with creation date %s',
                @$_
            )
        })
        ->completed;
    $log->infof('Copy data in');
    # Normally you'd have a proper source that's streaming from some other system,
    # this construct looks a bit unwieldy on its own but the ->from method
    # would also accept the arrayref-of-rows directly.
    await $db->query('copy roundtrip_one(name) from stdin')
        ->from([ map [ $_ ], qw(first second third) ])
        ->completed;

    $log->infof('Find those rows again:');
    await $db->query(q{select * from roundtrip_one where name in ('first', 'second', 'third') order by id})
        ->row_hashrefs
        ->map(sub {
            $log->infof(
                'ID %s has name %s with creation date %s',
                $_->{id}, $_->{name}, $_->{created}
            )
        })
        ->completed;
    $log->infof('Roll back');
    await $db->query('rollback')->void;
})->()->get;

