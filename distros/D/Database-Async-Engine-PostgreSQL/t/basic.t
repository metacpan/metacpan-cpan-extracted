use Full::Script qw(:v1);
use feature qw(state);

use Test::More;
use Test::Fatal;
use Test::Deep qw(bag ignore re cmp_deeply);
use IO::Async::Loop;
use Database::Async;
use Database::Async::Engine::PostgreSQL;
use Log::Any::Adapter qw(TAP);

plan skip_all => 'set DATABASE_ASYNC_PG_TEST env var to test, but be prepared for it to *delete any and all data* in that database' unless exists $ENV{DATABASE_ASYNC_PG_TEST};

my $loop = IO::Async::Loop->new;

my $db;
is(exception {
    $loop->add(
        $db = Database::Async->new(
            type => 'postgresql',
        )
    );
}, undef, 'can safely add to the loop');

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

try {
    # Throw exception
    await $db->query('select 1/0')->void;
} catch($e isa Protocol::Database::PostgreSQL::Error) {
    $log->infof('Exception received: %s', $e);
    like($e->message, qr/zero/, 'message says something about divide-by-zero');
    is($e->code, '22012', 'error code matches expectations');
} catch($e) {
    fail('invalid exception type');
}

try {
    # Hopefully no exception here
    my ($row) = await $db->query('select 3 as "id"')->row_hashrefs->as_list;
    is($row->{id}, 3, 'have valid query after exception');
} catch($e) {
    note explain $e;
    fail('exception on valid query');
}

try {
    # Throw different
    await $db->query('complete garbage')->void;
} catch($e isa Protocol::Database::PostgreSQL::Error) {
    $log->infof('Exception received: %s', $e);
    like($e->message, qr/syntax/, 'message says something about syntax');
    is($e->code, '42601', 'error code matches expectations');
} catch($e) {
    fail('invalid exception type');
}

try {
    # Throw exception
    my ($row) = await $db->query('select 5 as "id"')->row_hashrefs->as_list;
    is($row->{id}, 5, 'still have valid query after exception');
} catch($e) {
    note explain $e;
    fail('exception on valid query');
}

done_testing;

