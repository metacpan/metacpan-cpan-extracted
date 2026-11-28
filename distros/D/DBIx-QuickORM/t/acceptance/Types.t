# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DateTime;
use DBIx::QuickORM;
use DBIx::QuickORM::Test;

my $JSON = 'DBIx::QuickORM::Type::JSON';
my $UUID = 'DBIx::QuickORM::Type::UUID';
my $DT   = 'DBIx::QuickORM::Type::DateTime';

my $U1 = '0190a6e8-1d2c-7c3b-9f00-123456789abc';
my $U2 = '0190a6e8-1d2c-7c3b-9f00-cba987654321';

# Per family: a JSON column, a native UUID column (CHAR(36) where there is none), and 16 bytes.
my %DDL = (
    PostgreSQL => {json => 'JSONB', uuid => 'UUID',     bin => 'BYTEA'},
    SQLite     => {json => 'JSON',  uuid => 'UUID',     bin => 'BINARY(16)'},
    DuckDB     => {json => 'JSON',  uuid => 'UUID',     bin => 'BLOB'},
    MariaDB    => {json => 'JSON',  uuid => 'UUID',     bin => 'BINARY(16)'},
    MySQL      => {json => 'JSON',  uuid => 'CHAR(36)', bin => 'BINARY(16)'},
);

# Timestamps per family. The MySQL family's TIMESTAMP is its timestamp with time zone, an instant read and written in the session zone.
my %TS = (
    PostgreSQL => {ts => 'TIMESTAMP',   tz => 'TIMESTAMP WITH TIME ZONE'},
    SQLite     => {ts => 'DATETIME',    tz => 'TIMESTAMPTZ'},
    DuckDB     => {ts => 'TIMESTAMP',   tz => 'TIMESTAMPTZ'},
    MariaDB    => {ts => 'DATETIME(6)', tz => 'TIMESTAMP'},
    MySQL      => {ts => 'DATETIME(6)', tz => 'TIMESTAMP'},
);

do_for_all_dbs {
    my ($db, $set) = @_;
    my $family = $set->{family};
    my %ddl    = %{$DDL{$family}};

    my $dbh = $db->connect;
    $ddl{json} = 'JSON'     if $family eq 'PostgreSQL' && $dbh->{pg_server_version} < 90400;         # JSONB arrived in 9.4
    $ddl{uuid} = 'CHAR(36)' if $family eq 'MariaDB'    && $dbh->{mariadb_serverversion} < 100700;    # UUID arrived in 10.7 (lab: 10.6 on MidnightBSD, DragonFly)

    $dbh->do(<<"    EOT");
        CREATE TABLE things (
            id         INTEGER NOT NULL PRIMARY KEY,
            data       $ddl{json},
            extra_json TEXT,
            ident      $ddl{uuid},
            owner_uuid CHAR(36),
            bin_uuid   $ddl{bin},
            uuid_count INTEGER,
            note       VARCHAR(40)
        )
    EOT
    $dbh->do("CREATE TABLE bin_ids (id $ddl{bin} NOT NULL PRIMARY KEY, name VARCHAR(20))");
    $dbh->do("CREATE TABLE events (id INTEGER NOT NULL PRIMARY KEY, day DATE, happened $TS{$family}->{ts}, happened_tz $TS{$family}->{tz}, t TIME)");

    # MariaDB reports JSON columns as longtext, so data is given its type here.
    my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {bin_ids => {id => 'UUID'}, things => {data => 'JSON'}});
    my $map = $orm->db_map;

    subtest autotype => sub {
        my $auto  = DBIx::QuickORM->new(dbh => $dbh, row_class => undef)->db_map;
        my %types = map { $_ => $auto->field(things => $_)->{orm_type} } keys %{$auto->table('things')->{fields}};
        is(
            \%types,
            {
                id         => undef,
                data       => $family eq 'MariaDB' ? undef : $JSON,    # MariaDB reports JSON columns as longtext
                extra_json => $JSON,
                ident      => $ddl{uuid} eq 'UUID' ? $UUID : undef,    # MySQL, and MariaDB before 10.7, have no UUID type
                owner_uuid => $UUID,
                bin_uuid   => $UUID,
                uuid_count => undef,
                note       => undef,
            },
            "Base types and name patterns claim fields; uuid_count is not a UUID",
        );

        my %dt = map { $_ => $auto->field(events => $_)->{orm_type} } qw/id day happened happened_tz t/;
        is(\%dt, {id => undef, day => $DT, happened => $DT, happened_tz => $DT, t => undef}, "Dates and timestamps are DateTime; time fields stay raw");

        my $over = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {things => {note => 'JSON', owner_uuid => undef}})->db_map;
        is($over->field(things  => 'note')->{orm_type}, $JSON, "types adds a type");
        ok(!$over->field(things => 'owner_uuid')->{orm_type}, "and removes one");
    };

    subtest arrays => sub {
        my %array = (
            PostgreSQL => "ids UUID[], docs $ddl{json}\[], seen TIMESTAMP[], tag_uuid VARCHAR(36)[]",
            DuckDB     => "ids UUID[], docs JSON[], seen TIMESTAMP[], tag_uuid VARCHAR[]",
        );
        return pass("$family has no array columns") unless $array{$family};

        $dbh->do("CREATE TABLE arrays (id INTEGER NOT NULL PRIMARY KEY, $array{$family})");
        my $auto = DBIx::QuickORM->new(dbh => $dbh, row_class => undef)->db_map;
        is($auto->field(arrays => $_)->{db_type},                                       match(qr/\[\]\z/),            "$_ is reported as an array") for qw/ids docs seen tag_uuid/;
        is([map { $auto->field(arrays => $_)->{orm_type} } qw/ids docs seen tag_uuid/], [undef, undef, undef, undef], "Array columns are never autotyped, by base type or by name");
        $dbh->do("DROP TABLE arrays");

        return unless $family eq 'DuckDB';
        $dbh->do("CREATE TABLE fixed_arrays (id INTEGER NOT NULL PRIMARY KEY, ids UUID[3])");
        my $fixed = DBIx::QuickORM->new(dbh => $dbh, row_class => undef)->db_map->field(fixed_arrays => 'ids');
        like($fixed->{db_type}, qr/^UUID\[3\]\z/i, "A fixed-size array is reported with its size");
        is($fixed->{orm_type}, undef, "and is never autotyped either");
        $dbh->do("DROP TABLE fixed_arrays");
    };

    subtest json => sub {
        my $data = {name => "caf\x{e9}", list => [1, 2, {deep => undef}]};
        $orm->insert(things => {id => 1, data => $data, extra_json => '{"plain":true}', note => 'n'});
        my $row = $orm->refresh_row('things', {id => 1}, cache => 0);

        is($JSON->inflate($row->{data},       $map->field(things => 'data')),       $data,          "A reference round-trips") if $family ne 'MariaDB';
        is($JSON->inflate($row->{extra_json}, $map->field(things => 'extra_json')), {plain => T()}, "A plain value is stored as the JSON it is");

        ok($orm->update_row('things', $row, {extra_json => [3, "\x{263a}"]}), "An update deflates a reference");
        $row = $orm->refresh_row('things', {id => 1}, cache => 0);
        is($JSON->inflate($row->{extra_json}, $map->field(things => 'extra_json')), [3, "\x{263a}"], "and it round-trips");
    };

    subtest uuid => sub {
        $orm->insert(things => {id => 2, ident => $U1, owner_uuid => $U1, bin_uuid => $U2});
        my $row = $orm->refresh_row('things', {id => 2}, cache => 0);

        is($row->{owner_uuid},                                                  $U1, "A text field stores the string");
        is($row->{ident},                                                       $U1, "and so does a native UUID field") if $ddl{uuid} eq 'UUID';
        is(length($row->{bin_uuid}),                                            16,  "A binary field stores 16 bytes");
        is($UUID->inflate($row->{bin_uuid}, $map->field(things => 'bin_uuid')), $U2, "which inflate to the string");

        my $new = $orm->insert(bin_ids => {id => $U1, name => 'a'});
        $orm->clear_cache;
        my $found = $orm->refresh_row('bin_ids', {id => $U1});
        is($found->{name}, 'a', "A binary UUID primary key is found by its string");
        ok($orm->update_row('bin_ids', $found, {id => $U2}), "and can be changed to another string");
        is($orm->refresh_row('bin_ids', {id => $U2}, cache => 0)->{name}, 'a', "which is stored as bytes");
        is($orm->delete_row('bin_ids', {id => $U2}, enforce_canon => 0),  1,   "and deleted by it");
    };

    subtest datetime => sub {
        my $mysql = $family =~ m/^(?:MySQL|MariaDB)$/;
        my $zone  = $mysql ? '+05:30' : 'Asia/Kolkata';                                                                      # the MySQL test servers have no zone tables
        my $orm   = DBIx::QuickORM->new(connect => sub { $db->connect }, time_zone => $zone);
        my $raw   = sub { $orm->connection->dbh->selectrow_array("SELECT $_[0] FROM events WHERE id = ?", undef, $_[1]) };

        my $utc = DateTime->new(year => 2024, month => 2, day => 3, hour => 22, minute => 5, second => 6, nanosecond => 123_456_000, time_zone => 'UTC');
        my $row = $orm->insert(events => {id => 1, happened => $utc, day => $utc, t => '10:11:12'});
        like($raw->('happened', 1), qr/^2024-02-03 22:05:06\.123456/, "A DateTime is stored as its own wall clock, whatever the ORM's zone");
        is($raw->('day', 1), '2024-02-03', "A date keeps its own date");
        like($raw->('t', 1), qr/^10:11:12/, "A time field is sent as given");

        $row->refresh;
        my $at = $row->field('happened');
        isa_ok($at, ['DBIx::QuickORM::Type::DateTime::Lazy'], "Rows read a lazy DateTime");
        ref_is($row->field('happened'), $at, "cached");
        is("$at", '2024-02-03T22:05:06.123456', "It stringifies to ISO 8601");
        my $dt = $at->datetime_ref;
        is([$dt->ymd, $dt->hms], ['2024-02-03', '22:05:06'], "holds the stored wall clock");
        ok($dt->time_zone->is_floating, "floating");
        is($dt->nanosecond,                                                   123_456_000,                   "with the fraction");
        is([map { $row->field('day')->datetime_ref->$_ } qw/ymd hms offset/], ['2024-02-03', '00:00:00', 0], "A date is a floating midnight");

        my $later = $at->datetime->add(days => 1);
        is([$dt->epoch, $later->epoch - $dt->epoch], [$utc->epoch, 86400], "Changing a copy leaves the read value as it was");
        ref_is($row->field('happened'), $at, "and the row's cached value with it");
        $row->update({happened => $later});
        like($raw->('happened', 1), qr/^2024-02-04 22:05:06\.123456/, "The changed copy deflates and is written back");

        $orm->insert(events => {id => 2, happened => '2024-01-01 00:00:00'});
        like($raw->('happened', 2), qr/^2024-01-01 00:00:00/, "A plain string is sent as given");

        # Whole seconds: DBD::DuckDB drops the leading zeros of a fraction.
        my $west = DateTime->new(year => 2024, month => 7, day => 1, hour => 4, minute => 5, second => 6, time_zone => '-0700');
        $orm->insert(events => {id => 3, happened_tz => $west});
        my $tz = $orm->refresh_row('events', {id => 3}, cache => 0)->field('happened_tz')->datetime_ref;
        is($tz->epoch, $west->epoch, "A timestamp with time zone keeps its instant");

        if ($mysql) {
            my $noon = DateTime->new(year => 2024, month => 2, day => 3, hour => 12, time_zone => 'UTC');
            $orm->insert(events => {id => 4, happened_tz => $noon});
            is($raw->('UNIX_TIMESTAMP(happened_tz)', 4), $noon->epoch, "A UTC DateTime written in another session zone keeps its epoch in a TIMESTAMP");
            is($tz->offset,                              19800,        "and is read back in the session zone");
            return;
        }
        return unless $family eq 'SQLite';
        is($tz->offset,                        -25200,                "and SQLite, which stores the text, its offset");
        is($raw->('datetime(happened_tz)', 3), '2024-07-01 11:05:06', "in a form SQLite's date functions read");
    };

    subtest uuid_keys => sub {
        $dbh->do("CREATE TABLE text_ids (id $ddl{uuid} NOT NULL PRIMARY KEY, name VARCHAR(20))");
        my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {bin_ids => {id => 'UUID'}, text_ids => {id => 'UUID'}});

        for my $table (qw/text_ids bin_ids/) {
            my $row = $orm->insert($table => {id => $U1, name => $table});
            ref_is($orm->refresh_row($table, {id => uc $U1}, db => 0), $row, "$table: an upper case key finds the cached row");
            ref_is($orm->refresh_row($table, $row,           db => 0), $row, "$table: and so does the stored key");

            $orm->clear_cache($table => uc $U1);
            ok(!$orm->is_canon($table => $row), "$table: clear_cache with it clears the row");
        }

        my $bytes = pack('H*', $U1 =~ s/-//gr);
        my $found = $orm->handle('bin_ids')->find($bytes);
        is($found->{name}, 'bin_ids', "A binary key is found by its 16 bytes");
        ref_is($orm->refresh_row('bin_ids', {id => $U1}, db => 0), $found, "and cached under the same key as its string");
        $orm->clear_cache(bin_ids => $bytes);
        ok(!$orm->is_canon(bin_ids => $found), "clear_cache with the bytes clears it");
    };

    subtest datetime_keys => sub {
        my $mysql = $family =~ m/^(?:MySQL|MariaDB)$/;
        my %ddl   = (day => 'DATE', ts => $TS{$family}->{ts}, tz => $mysql ? 'TIMESTAMP(6)' : $TS{$family}->{tz});
        $dbh->do("CREATE TABLE key_$_ (stamp $ddl{$_} NOT NULL PRIMARY KEY, name VARCHAR(20))") for keys %ddl;

        my $orm  = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, time_zone => $mysql ? '+05:30' : 'Asia/Kolkata');
        my $conn = $orm->connection;
        # A fraction with no leading zero: DBD::DuckDB prints 500 microseconds as .500, another instant.
        my $utc = DateTime->new(year => 2024, month => 2, day => 3, hour => 22, minute => 5, second => 6, nanosecond => 120_000_000, time_zone => 'UTC');

        for my $kind (sort keys %ddl) {
            my $table = "key_$kind";
            my $row   = $orm->insert($table => {stamp => $utc, name => $kind});
            my $field = $orm->db_map->field($table => 'stamp');
            my $raw   = $row->{stamp};

            # Only a timestamp with time zone (a MySQL-family TIMESTAMP) is an instant. The others are their wall clock as given.
            my $instant = $kind eq 'tz';
            my %forms   = (
                'the DateTime'    => $utc,
                'the lazy value'  => $DT->inflate($raw, $field, $conn),
                'the stored text' => $raw,
            );
            $forms{'another offset'} = $utc->clone->set_time_zone('-0700') if $instant;
            # DateTime::Format::MySQL ignores what follows a fraction, so it misreads this text.
            $forms{'text in another offset'} = '2024-02-03 15:05:06.12-07:00' if $instant && !$mysql;
            ref_is($orm->refresh_row($table, {stamp => $forms{$_}}, db => 0), $row, "$kind: $_ finds the cached row") for sort keys %forms;

            $orm->clear_cache($table => $utc);
            ok(!$orm->is_canon($table => $row), "$kind: clear_cache with the DateTime clears it");

            my $found = $orm->handle($table)->find($utc);
            is($found->{name}, $kind, "$kind: find reads it again");
            ref_is($orm->handle($table)->find($forms{$instant ? 'another offset' : 'the stored text'}), $found, "$kind: and finds it in the cache by another form");
        }
    };

    subtest wall_clock_keys => sub {
        # Last: the ORMs here set the session zone of $dbh.
        # Local times a daylight saving zone skips: Sao Paulo went from 2018-11-04 00:00 to 01:00, New York from 2024-03-10 02:00 to 03:00.
        if ($family =~ m/^(?:MySQL|MariaDB)$/ && !$dbh->selectrow_array('SELECT COUNT(*) FROM mysql.time_zone_name')) {
            skip_all "The server has no time zone tables";
            return;
        }

        my @cases = (
            [day => 'DATE', 'America/Sao_Paulo', '2018-11-04', DateTime->new(year => 2018, month => 11, day => 4)],
            [ts  => $TS{$family}->{ts}, 'America/New_York', '2024-03-10 02:30:00', DateTime->new(year => 2024, month => 3, day => 10, hour => 2, minute => 30)],
        );

        for my $case (@cases) {
            my ($kind, $type, $zone, $text, $floating) = @$case;
            my $table = "gap_$kind";
            $dbh->do("CREATE TABLE $table (stamp $type NOT NULL PRIMARY KEY, name VARCHAR(20))");
            $dbh->do("INSERT INTO $table (stamp, name) VALUES (?, ?)", undef, $text, $kind);

            my $orm = DBIx::QuickORM->new(dbh => $dbh, time_zone => $zone);
            my $row = $orm->handle($table)->find($text);
            is($row->field('name'), $kind, "$kind: a key $zone skips is read in that zone");
            ref_is($orm->refresh_row($table, {stamp => $text}, db => 0, data => 1), $row->row_data, "$kind: its text finds the cached row");

            my $stamp = $row->field('stamp')->datetime_ref;
            is([$stamp->ymd, $stamp->hms], [$floating->ymd, $floating->hms], "$kind: field() inflates its wall clock");
            ok($stamp->time_zone->is_floating, "$kind: as a floating DateTime");

            $orm->clear_cache($table => $text);
            ok(!$orm->is_canon($table => $row), "$kind: clear_cache with the text clears it");
            is($orm->handle($table)->find($floating)->field('name'), $kind, "$kind: find deflates a floating DateTime for it");
        }
    };
};

done_testing;
