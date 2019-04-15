use strict;
use warnings;

use feature qw(state);
no indirect;

use Test::More;
use Test::Fatal;
use Test::Deep;
use Future::AsyncAwait;
use IO::Async::Loop;
use Database::Async;
use Database::Async::Engine::PostgreSQL;
use Log::Any::Adapter qw(TAP);
use Log::Any qw($log);

my $pg = eval {
    require Test::PostgreSQL;
    Test::PostgreSQL->new;
} or plan skip_all => $@;

my $uri = URI->new($pg->uri);

my $loop = IO::Async::Loop->new;

my $db;
is(exception {
    $uri->query_param(sslmode => 'prefer');
    $loop->add(
        $db = Database::Async->new(
            uri => $uri,
        )
    );
}, undef, 'can safely add to the loop');

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
            my ($row) = @_;
            cmp_deeply($row, {
                id => ignore(),
                name => ignore(),
                created => re(qr/^\d{4}-\d{2}-\d{2}/),
            }, 'have something that looks roughly correct in the hashref output');
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
        ->row_arrayrefs
        ->map(sub {
            $log->infof(
                'ID %s has name %s with creation date %s',
                @$_
            )
        })
        ->completed;
    $log->infof('Copy data in');
    my $src = Ryu::Source->new;
    my $f = $db->query('copy roundtrip_one(name) from stdin')
        ->from($src)
        ->completed;
    $src->emit([$_]) for qw(first second third);
    $src->finish;
    await $f;

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
done_testing;

