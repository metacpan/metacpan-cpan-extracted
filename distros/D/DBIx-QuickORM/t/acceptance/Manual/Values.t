# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Values.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DateTime;

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    my $dbh = $db->connect;
    $dbh->do(<<'    SQL');
    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT UNIQUE,
        prefs       JSON,
        referred_by INTEGER REFERENCES users (id),
        created     TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE posts (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        title   TEXT NOT NULL,
        views   INTEGER NOT NULL DEFAULT 0
    );

    CREATE TABLE files (id SERIAL PRIMARY KEY, name TEXT, data BYTEA);
    CREATE TABLE tags  (id SERIAL PRIMARY KEY, names TEXT[]);
    SQL
    $dbh->disconnect;

    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });

    # DEFLATION
    my $ann = $orm->insert(
        users => {
            name    => 'Ann',
            prefs   => {theme => 'dark'},
            created => DateTime->new(
                year  => 2024,
                month => 1,
                day   => 2,
            ),
        }
    );
    my $json = $ann->raw_field('prefs');      # '{"theme":"dark"}': what the database holds
    my $text = $ann->raw_field('created');    # '2024-01-02 00:00:00'

    my $bob = $orm->insert(
        users => {
            name  => 'Bob',
            prefs => '{"theme":"light"}',    # a plain value is sent as given: already JSON text
        }
    );

    is($json,                '{"theme":"dark"}',    "a hashref on a JSON field is deflated to JSON text");
    is($text,                '2024-01-02 00:00:00', "a DateTime to the database's text");
    is($ann->field('prefs'), {theme => 'dark'},     "and inflates back");
    is($bob->field('prefs'), {theme => 'light'},    "a plain value went as given, and inflates");
    like(dies { $orm->insert(users => {name => ['ref']}) }, qr/has no type to deflate a reference with/, "a reference on an untyped field croaks");
    is($orm->insert(users => {name => 'Str', prefs => '"text"'})->field('prefs'),             'text', "a JSON string is passed encoded");
    is($orm->handle('users')->where({created => '2024-01-02 00:00:00'})->only->field('name'), 'Ann',  "a where takes database form as given");

    # INFLATION
    my $prefs = $ann->field('prefs');                         # {theme => 'dark'}: inflated by the JSON type
    my $day   = $ann->field('created')->datetime_ref->day;    # 2

    is($prefs, {theme => 'dark'}, "field() inflates a JSON field");
    is($day,   2,                 "and a timestamp");

    # SQL
    use DBIx::QuickORM::Value qw/raw inflated binary sql/;

    my $cy = $orm->insert(
        users => {
            name    => 'Cy',
            created => sql('now() - ?::interval', '1 day'),    # literal SQL, with binds
        }
    );
    # the value the database computed, read back through RETURNING
    my $when = $cy->field('created');

    $cy->update({name => sql('upper(name)')});

    my $post = $orm->insert(
        posts => {
            user_id => $cy->field('id'),
            title   => 'Hi',
        }
    );
    my $bumped = $orm->handle('posts')->where({user_id => $cy->field('id')})->update({views => sql('views + 1')});    # 1: one row changed
    my @recent = $orm->handle('users')->where({created => {'>=' => sql('now() - ?::interval', '1 hour')}})->all;

    isa_ok($when, ['DBIx::QuickORM::Type::DateTime::Lazy'], "the computed value comes back and inflates");
    ok($when < DateTime->now, "as the database computed it");
    is($cy->field('name'),                       'CY',           "sql() in an update");
    is($bumped,                                  1,              "sql() in a bulk update changed the one post");
    is($post->refresh->field('views'),           1,              "which the database incremented");
    is([sort map { $_->field('name') } @recent], ['Bob', 'Str'], "sql() in a where, with binds");                     # Bob and Str were inserted now, Ann in 2024, Cy a day ago
    like(dies { $orm->find(users => sql('1')) }, qr/sql\(\) cannot be used in a primary key/, "sql() croaks in a primary key");
    is($bob->update({id => sql('id + 100')})->field('id'), $bob->field('id'), "sql() may set a new primary key, read back through RETURNING");
    ok($bob->field('id') > 100, "with the database's value");

    # RAW
    my $eve = $orm->insert(
        users => {
            name    => 'Eve',
            prefs   => '{}',
            created => '2024-01-02 03:04:05',
        },
        raw => 1,    # values are already in database form
    );

    # a PostgreSQL array: a reference on a field without a type, sent as is
    my $tag = $orm->insert(tags => {names => raw(['perl', 'sql'])});

    is($eve->raw_field('created'), '2024-01-02 03:04:05', "raw => 1 sends every value as given");
    is($tag->field('names'),       ['perl', 'sql'],       "raw() sends an arrayref to an array column");
    like(dies { $orm->insert(tags => {names => ['perl']}) }, qr/has no type to deflate a reference with/, "which croaks without it");

    $eve->update({created => raw('2024-02-03 04:05:06')});

    is($eve->raw_field('created'), '2024-02-03 04:05:06', "a row's update takes raw() per value");

    # INFLATED
    my $fay = $orm->insert(
        users => {
            name    => 'Fay',
            created => '2024-01-02 03:04:05',
            prefs   => inflated({theme => 'dark'}),    # deflate this one anyway
        },
        raw => 1,
    );

    my $cutoff = DateTime->new(
        year  => 2024,
        month => 6,
        day   => 1,
    );
    my @before = $orm->handle('users')
        # a where sends values as given: mark one to deflate
        ->where({created => {'<' => inflated($cutoff)}})->order_by('id')->all;

    is($fay->raw_field('prefs'),            '{"theme":"dark"}',    "inflated() is deflated under raw => 1");
    is([map { $_->field('name') } @before], ['Ann', 'Eve', 'Fay'], "inflated() in a where is deflated through the field's type");

    # BINARY
    my $bytes = pack('C*', 0, 255, 10, 13);
    my $file  = $orm->insert(
        files => {
            name => 'blob',
            data => $bytes,    # a BYTEA field is bound as binary automatically
        }
    );
    # so is a where on the table
    my $same = $orm->handle('files')->where({data => $bytes})->only;
    # raw SQL has no column information, so mark the bytes
    my $found = $orm->handle(\'SELECT * FROM files')->where({data => binary($bytes)})->only;

    is($file->raw_field('data'),                                            $bytes, "bytes to a BYTEA field round-trip");
    is($same->field('name'),                                                'blob', "a where on the table binds them as binary");
    is($found->field('name'),                                               'blob', "binary() does the same in a query");
    is($orm->handle(\'SELECT * FROM files')->where({data => $bytes})->only, undef,  "without it the bytes go as text, and match nothing");
};

done_testing;
