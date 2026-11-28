# Test origin: AI
use Test2::V0;

use DBI;
use DateTime;
use DateTime::Format::Strptime;
use DBIx::QuickORM;
use DBIx::QuickORM::Type::DateTime;

my $T = 'DBIx::QuickORM::Type::DateTime';

my %DATE = (affinity => 'string', type => 'date');
my %TS   = (affinity => 'string', type => 'timestamp');
my %TZ   = (affinity => 'string', type => 'timestamptz');

sub conn {
    my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
    $dbh->do("CREATE TABLE events (id INTEGER PRIMARY KEY, day DATE, at DATETIME, at_tz TIMESTAMP WITH TIME ZONE, t TIME, n INTERVAL)");
    return DBIx::QuickORM->new(dbh => $dbh, row_class => undef, time_zone => 'Asia/Kolkata', @_);
}

subtest claims => sub {
    my $map = conn()->db_map;
    is($map->field(events  => $_)->{orm_type}, $T, "'$_' is autotyped") for qw/day at at_tz/;
    ok(!$map->field(events => $_)->{orm_type}, "'$_' is not")           for qw/t n/;
    is($T->_kind($_->[0]), $_->[1], "kind of $_->[0]->{type}")
        for [\%DATE, 'date'], [\%TS, 'timestamp'], [{type => 'datetime'}, 'timestamp'], [\%TZ, 'timestamptz'], [{type => 'timestamp with time zone'}, 'timestamptz'], [{type => 'timestamp without time zone'}, 'timestamp'];
    is($T->_kind(\%TS, {timestamp => 1}),                                                                     'timestamptz', "A base type the dialect lists as an instant is a timestamp with time zone");
    is(warnings { is($T->_kind({}, {timestamp => 1}), 'timestamp', "A record with no type is a timestamp") }, [],             "and gives no warnings");
};

subtest formats => sub {
    my $dt0 = DateTime->new(year => 2024, month => 2, day => 3, hour => 4, nanosecond => 5_000_000, time_zone => '+05:30');
    is($T->_format(undef, 'timestamptz', $dt0, 'UTC'), '2024-02-03 04:00:00.005+05:30', "An undef formatter means the type's own form, keeping the colon");

    my $dt = $T->_parse('DateTime::Format::Pg', [], 'timestamp', '2024-02-03T04:05:06.0123', 'UTC');
    is([$dt->ymd, $dt->hms, $dt->nanosecond, $dt->time_zone->name], ['2024-02-03', '04:05:06', 12300000, 'UTC'], "A value without a zone is put in the given zone");
    ok($T->_parse('DateTime::Format::Pg', [], 'timestamp',   '2024-02-03 04:05:06',       undef)->time_zone->is_floating, "and stays floating without one");
    is($T->_parse('DateTime::Format::Pg', [], 'timestamptz', '2024-02-03 04:05:06+05:30', 'UTC')->offset, 19800, "An offset is kept");

    my $my = $T->_parse('DateTime::Format::MySQL', [], 'timestamptz', '2024-02-03 04:05:06.25', '+05:30');
    is([$my->nanosecond, $my->offset], [250_000_000, 19800], "A parser without the kind's method uses parse_datetime");
    is($T->_format('DateTime::Format::MySQL', 'timestamp', $my, '+05:30'), '2024-02-03 04:05:06.250000', "and a formatter format_datetime");
    is($T->_format('DateTime::Format::MySQL', 'date',      $my, '+05:30'), '2024-02-03',                 "but a date stays a date");

    my $utc = DateTime->new(year => 2024, month => 2, day => 3, hour => 22, time_zone => 'UTC');
    is($T->_format('DateTime::Format::MySQL', 'timestamptz', $utc, '+05:30'), '2024-02-04 03:30:00', "A formatter that writes no offset gets a timestamp with time zone in the session zone");
};

subtest convert => sub {
    my $conn = conn()->connection;
    my $dt   = DateTime->new(year => 2024, month => 2, day => 3, hour => 22, minute => 5, second => 6, nanosecond => 500_000_000, time_zone => 'UTC');

    is($T->deflate($dt, \%TS,   $conn), '2024-02-03 22:05:06.5',       "A timestamp is written as its own wall clock, whatever its zone");
    is($T->deflate($dt, \%DATE, $conn), '2024-02-03',                  "A date keeps its own date");
    is($T->deflate($dt, \%TZ,   $conn), '2024-02-03 22:05:06.5+00:00', "A timestamp with time zone keeps its offset, with a colon");

    my $floating = DateTime->new(year => 2024, month => 2, day => 3, hour => 4);
    is($T->deflate($floating, \%TZ, $conn), '2024-02-03 04:00:00+05:30', "A floating DateTime is taken to be in the ORM's zone");

    my $lazy = $T->inflate('2024-02-04 03:35:06.5', \%TS, $conn);
    isa_ok($lazy, ['DBIx::QuickORM::Type::DateTime::Lazy'], "inflate gives a lazy DateTime");
    is("$lazy", '2024-02-04T03:35:06.5', "which stringifies to ISO 8601");
    my $ref = $lazy->datetime_ref;
    is([$ref->ymd, $ref->hms], ['2024-02-04', '03:35:06'], "and holds the stored wall clock");
    ok($ref->time_zone->is_floating, "floating, in no zone");
    is($T->deflate($lazy, \%DATE, $conn), '2024-02-04', "A lazy value deflates like a DateTime");
    ok($T->inflate('2024-02-04', \%DATE, $conn)->datetime_ref->time_zone->is_floating, "A date is floating too");

    my $tz = $T->inflate('2024-02-03 04:05:06-0700', \%TZ, $conn);
    is($tz->datetime_ref->offset, -25200, "A value with an offset keeps it");

    ok($T->is_inflated($dt),                "A DateTime is inflated");
    ok($T->is_inflated($lazy),              "and so is a lazy one");
    ok(!$T->is_inflated('2024-02-03'),      "a string is not");
    ok($T->inflated_is_immutable_for_cache, "Lazy values change only by copy, so rows hand out the cached value");
    like(dies { $T->deflate('2024-02-03', \%DATE, $conn) }, qr/^Expected a DateTime object, got '2024-02-03'/, "Deflating anything else croaks");
};

subtest canonical_key_value => sub {
    my $conn = conn()->connection;                                     # SQLite, in Asia/Kolkata
    my $key  = sub { $T->canonical_key_value($_[0], $_[1], $conn) };

    my $utc = DateTime->new(year => 2024, month => 2, day => 3, hour => 22, minute => 5, second => 6, nanosecond => 120_000_000, time_zone => 'UTC');
    is($key->($utc,                                                                                                               \%TZ), '2024-02-03T22:05:06.120000000Z', "A timestamp with time zone is its UTC instant, nine fraction digits");
    is($key->('2024-02-04 03:35:06.12+05:30',                                                                                     \%TZ), '2024-02-03T22:05:06.120000000Z', "from text in another offset too");
    is($key->('2024-02-03 22:05:06.120000000+0000',                                                                               \%TZ), '2024-02-03T22:05:06.120000000Z', "and from what deflate gives");
    is($key->(DateTime->new(year => 2024, month => 2, day => 4, hour => 3, minute => 35, second => 6, nanosecond => 120_000_000), \%TZ), '2024-02-03T22:05:06.120000000Z', "A floating DateTime is in the ORM's zone");

    is($key->($utc,                                               \%TS), '2024-02-03T22:05:06.120000000', "A timestamp is its own wall clock, whatever its zone, as deflate writes it");
    is($key->('2024-02-03 22:05:06.12',                           \%TS), '2024-02-03T22:05:06.120000000', "as text");
    is($key->($T->inflate('2024-02-03 22:05:06.12', \%TS, $conn), \%TS), '2024-02-03T22:05:06.120000000', "and as a lazy value");
    is($key->($utc->clone->set_time_zone('-0700'),                \%TS), '2024-02-03T15:05:06.120000000', "Another offset is another wall clock, so another key");

    is($key->($utc,         \%DATE), '2024-02-03', "A date is its own date");
    is($key->('2024-02-03', \%DATE), '2024-02-03', "as text too");

    # Local times the zone skips keep their wall clock rather than croak.
    my $ny = conn(time_zone => 'America/New_York')->connection;
    is($T->canonical_key_value('2024-03-10 02:30:00',                                                       \%TS, $ny), '2024-03-10T02:30:00.000000000', "A timestamp in a daylight saving gap keeps its wall clock");    # banned-words-ok
    is($T->canonical_key_value(DateTime->new(year => 2024, month => 3, day => 10, hour => 2, minute => 30), \%TS, $ny), '2024-03-10T02:30:00.000000000', "as a floating DateTime too");
    my $sp = conn(time_zone => 'America/Sao_Paulo')->connection;
    is($T->canonical_key_value('2018-11-04', \%DATE, $sp), '2018-11-04', "A date whose midnight the zone skips keeps its date");
};

subtest parsers => sub {
    my $orm = conn();
    my $dbh = $orm->connection->dbh;
    $dbh->do("CREATE TABLE stamps (stamp DATETIME PRIMARY KEY, name TEXT)");
    $dbh->do("INSERT INTO stamps (stamp, name) VALUES ('2024-02-03T04:05:06Z', 'iso')");
    $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, time_zone => 'Asia/Kolkata');

    my $row = $orm->handle('stamps')->find('2024-02-03T04:05:06Z');
    my $at  = $T->inflate($row->{stamp}, $orm->db_map->field(stamps => 'stamp'), $orm->connection)->datetime_ref;
    is([$at->ymd, $at->hms, $at->offset], ['2024-02-03', '04:05:06', 0], "ISO text the dialect's parser cannot read is read by DateTime::Format::ISO8601");
    my $utc = DateTime->new(year => 2024, month => 2, day => 3, hour => 4, minute => 5, second => 6, time_zone => 'UTC');
    ref_is($orm->refresh_row(stamps => {stamp => $utc}, db => 0), $row, "and keyed by it: a DateTime finds the cached row");

    my @seen;
    my $custom = conn(
        datetime_parsers => [
            sub { push @seen => 'die';   die "not mine\n" },
            sub { push @seen => 'undef'; undef },
            DateTime::Format::Strptime->new(pattern => '%d/%m/%Y %H:%M', on_error => 'undef'),
            sub { push @seen => 'late'; DateTime->now },
        ],
    )->connection;
    my $lazy = $T->inflate('03/02/2024 04:05', \%TS, $custom)->datetime_ref;
    is([$lazy->ymd, $lazy->hms], ['2024-02-03', '04:05:00'], "A Strptime object reads its pattern");
    is(\@seen,                   ['die',        'undef'],    "after parsers that die or return undef, and the first DateTime wins");
    is($T->canonical_key_value('03/02/2024 04:05', \%TS, $custom), '2024-02-03T04:05:00.000000000', "Keys use the same parsers");

    my $epoch = conn(datetime_parsers => [sub { $_[0] =~ m/^\d+\z/ ? DateTime->from_epoch(epoch => $_[0]) : undef }])->connection;
    is($T->inflate('86400', \%TS, $epoch)->datetime_ref->ymd, '1970-01-02', "A code reference parses too");

    my $bad = conn(datetime_parsers => [sub { 'not a date' }])->connection;
    like(dies { $T->inflate('soon', \%TS, $bad)->datetime_ref }, qr/^A datetime parser returned 'not a date' for 'soon', not a DateTime/, "A parser returning something else croaks");
    like(
        dies { $T->inflate('soon', \%TS, conn()->connection)->datetime_ref },
        qr/^Cannot parse 'soon' as a timestamp: add a parser that reads it to the ORM's datetime_parsers, or leave the field untyped with types => \{\$table => \{\$field => undef\}\}/,
        "Text no parser reads croaks naming the ways out, when the value is first used"
    );
    like(dies { $T->inflate('soon', {%TS, table => 'events', name => 'at'}, conn()->connection)->datetime_ref }, qr/^Cannot parse 'soon' as a timestamp for events\.at:/, "and the field, when its record names it");
    ok(lives { ok($T->is_inflated($T->inflate('soon', \%TS, conn()->connection)), "A lazy value over unparseable text is inflated") }, "and answering does not parse it");
    like(dies { $T->deflate('soon', {%TS, table => 'events', name => 'at'}, conn()->connection) }, qr/^Expected a DateTime object for events\.at, got 'soon'/, "Deflating names the field too");

    $@ = 'kept';
    $T->_parse('DateTime::Format::Pg', [], 'timestamp', '2024-02-03T04:05:06Z', undef);
    is($@, 'kept', "A parser that fails on the way to the one that reads the text leaves \$@ alone");
};

subtest postgresql_format => sub {
    my $dt = $T->_parse('DateTime::Format::Pg', [], 'timestamptz', '2024-02-03 04:05:06.25+05:30', 'UTC');
    is($T->_format('DateTime::Format::Pg', 'timestamptz', $dt, 'UTC'), '2024-02-03 04:05:06.250000000+0530', "DateTime::Format::Pg formats a timestamp with time zone with its offset");
    is($T->_format('DateTime::Format::Pg', 'timestamp',   $dt, undef), '2024-02-03 04:05:06.250000000',      "and a timestamp without one as its wall clock");
};

subtest through_the_orm => sub {
    my $orm = conn();
    my $dt  = DateTime->new(year => 2024, month => 2, day => 3, hour => 4, minute => 5, second => 6, time_zone => 'Asia/Kolkata');
    $orm->insert(events => {id => 1, at => $dt, day => '2024-01-01', t => '10:00:00'});
    is([$orm->connection->dbh->selectrow_array('SELECT at, day, t FROM events')], ['2024-02-03 04:05:06', '2024-01-01', '10:00:00'], "A DateTime is deflated; strings and time fields are sent as given");
};

done_testing;
