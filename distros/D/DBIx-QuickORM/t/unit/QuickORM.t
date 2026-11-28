# Test origin: AI
use Test2::V0;
use lib 't/lib';

use Config qw/%Config/;
use DBI;
use DateTime;
use File::Temp qw/tempdir/;
use POSIX();
use Scalar::Util qw/weaken/;
use DBIx::QuickORM;
use DBIx::QuickORM::Value qw/inflated/;

sub dbh { DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1, @_}) }

subtest forms_and_defaults => sub {
    my $orm = DBIx::QuickORM->new(dbh => dbh());
    isa_ok($orm->connection, ['DBIx::QuickORM::Connection'], "A Connection is made at construction");
    is($orm->row_class,             'DBIx::QuickORM::Row', "row_class default");
    is($orm->retain_cache,          0,                     "retain_cache default");
    is($orm->enforce_canon,         1,                     "enforce_canon default");
    is($orm->time_zone,             'UTC',                 "time_zone default");
    is($orm->isolation,             undef,                 "isolation default");
    is($orm->connection->time_zone, 'UTC',                 "The Connection holds the settings");
    ok(!exists $orm->{$_}, "and the ORM does not keep '$_'") for qw/time_zone retain_cache enforce_canon isolation db_map/;

    $orm = DBIx::QuickORM->new({connect => sub { dbh() }, row_class => undef, time_zone => 'Europe/Paris', retain_cache => 1, enforce_canon => 0, isolation => 'SERVER'});
    ok(exists $orm->{row_class} && !defined $orm->row_class, "row_class => undef is kept (hashrefs)");
    is([$orm->retain_cache, $orm->enforce_canon, $orm->time_zone, $orm->isolation], [1, 0, 'Europe/Paris', 'server'], "One hashref of arguments works");

    is(DBIx::QuickORM->new(dbh => dbh(), tz => 'Europe/Paris')->time_zone, 'Europe/Paris', "tz is an alias for time_zone");
    is($orm->datetime_parsers,                                             [],             "datetime_parsers default");
    my @parsers = ('DateTime::Format::Pg', sub { undef });
    is(DBIx::QuickORM->new(dbh => dbh(), datetime_parsers => \@parsers)->connection->datetime_parsers, \@parsers, "datetime_parsers takes loaded classes and code references, held by the Connection");

    # A parser class that is not loaded yet, served from memory.
    unshift @INC => sub {
        return unless $_[1] eq 'My/Late/Parser.pm';
        my $src = "package My::Late::Parser; sub parse_datetime { undef } 1;";
        open(my $fh, '<', \$src) or die "Cannot read a string: $!";
        return $fh;
    };
    ok(!My::Late::Parser->can('parse_datetime'), "The parser class is not loaded yet");
    DBIx::QuickORM->new(dbh => dbh(), datetime_parsers => ['My::Late::Parser']);
    ok(My::Late::Parser->can('parse_datetime'), "datetime_parsers loads a class it names");
    like(dies { DBIx::QuickORM->new(dbh => dbh(), tz => 'UTC', time_zone => 'UTC') }, qr/^Give 'time_zone' or its alias 'tz', not both/, "giving both croaks");
    like(dies { DBIx::QuickORM->new(dbh => dbh(), tz => '') }, qr/^'time_zone' must be a time zone name/, "and tz follows the same rules");

    $orm = DBIx::QuickORM->new(credentials => {dsn => 'dbi:SQLite::memory:', attrs => {RaiseError => 0}});
    ok($orm->connection->dbh->{RaiseError}, "credentials force RaiseError on");
    ok($orm->connection->dbh->{AutoCommit}, "and AutoCommit on");
    like(dies { DBIx::QuickORM->new(credentials => {dsn => 'dbi:SQLite::memory:', attrs => {AutoCommit => 0}}) }, qr/^Do not turn AutoCommit off in 'credentials' attrs; the ORM manages transactions/, "credentials with AutoCommit off croak");

    like(dies { DBIx::QuickORM->new(dbh => dbh(AutoCommit => 0)) }, qr/^The database handle must have AutoCommit on and no transaction open; the ORM manages transactions/, "A dbh with AutoCommit off croaks");

    my $file = __FILE__;
    my $new_line = __LINE__ + 1;
    like(dies { DBIx::QuickORM->new(dbh => dbh(RaiseError => 0)) }, qr/^The database handle must have RaiseError on at \S*DBIx\/QuickORM\.pm line \d+\.\n    \(from DBIx::QuickORM->new\(\) at \Q$file\E line $new_line\)\n\z/, "An error inside new() keeps its location and adds the caller's line");
    $new_line = __LINE__ + 1;
    like(dies { DBIx::QuickORM->new(dbh => dbh(), bogus => 1) }, qr/^Unknown argument\(s\) to new\(\): bogus at \Q$file\E line $new_line\.\n\z/, "An error already at the caller's line is not added to");

    like(dies { DBIx::QuickORM->new(dbh => dbh(RaiseError => 0), caller => ['main', 'Sub.pm', 7]) }, qr/\n    \(from DBIx::QuickORM->new\(\) at Sub\.pm line 7\)\n\z/, "caller => [frame] names the frame to report");
    ok(!exists DBIx::QuickORM->new(dbh => dbh(), caller => [caller])->{caller}, "caller is not kept on the object");

    my $obj = bless {}, 'My::Error';
    is(dies { DBIx::QuickORM->new(connect => sub { die $obj }) }, exact_ref($obj), "An exception object from new() is rethrown unchanged");
    my $line = __LINE__ + 1;
    like(dies { $orm->handle('nope') }, qr/^The table 'nope' is not in the database map at \Q$file\E line $line\./, "An unknown table croaks at the caller's line");

    my %stored = (types => {}, fks => {});
    $orm = DBIx::QuickORM->new(dbh => dbh(), %stored);
    is($orm->$_, $stored{$_}, "$_ is stored as given") for sort keys %stored;

    $orm = DBIx::QuickORM->new(dbh => dbh(), autotype => undef);
    ok(exists $orm->{autotype} && !defined $orm->autotype, "autotype => undef is kept (autotyping off)");
};

subtest lookup_table => sub {
    my $dbh = dbh();
    $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)");
    my $orm    = DBIx::QuickORM->new(dbh => $dbh, retain_cache => 1);
    my $lookup = $orm->connection->lookup;
    ok($lookup->retain, "retain_cache reaches the Connection's lookup table");

    my $bob = $lookup->ingest(users => {id => 1, name => 'bob'});
    my $al  = $lookup->ingest(users => {id => 2, name => 'al'});
    ok($orm->is_canon(users  => $bob),    "is_canon is true for the held hash");
    ok(!$orm->is_canon(users => {%$bob}), "and false for a copy");
    like(dies { $orm->is_canon(users => {name => 'x'}) }, qr/^The primary key field 'id' of the table 'users' is missing or undefined/, "and croaks without a primary key");

    $orm->clear_cache(users => 1);
    ok(!$orm->is_canon(users => $bob), "clear_cache(\$table => \$pk) clears one row");
    ok($orm->is_canon(users  => $al),  "and only that row");
    $lookup->ingest(users => $bob);
    $orm->clear_cache(users => {id => 1, name => 'ignored'});
    ok(!$orm->is_canon(users => $bob), "clear_cache takes a hashref of the key fields, other fields allowed");
    $lookup->ingest(users => $bob);
    $orm->clear_cache(users => [1]);
    ok(!$orm->is_canon(users => $bob), "and an arrayref of the key values");
    like(dies { $orm->clear_cache(users => [1, 2]) }, qr/^The table 'users' has 1 primary key field\(s\) \(id\), but the arrayref holds 2/, "an arrayref of the wrong length croaks");

    like(dies { $orm->clear_cache(users => \1) },                              qr/^Primary key must be a value, an arrayref, a hashref, or a row; got SCALAR/, "an unblessed reference croaks");
    like(dies { $orm->clear_cache(users => bless({id => 1}, 'Some::Thing')) }, qr/^The field 'id' of 'users' has no type to deflate a reference with/,         "any other object is a value, deflated like find's");
    $lookup->ingest(users => $bob);
    $orm->clear_cache(users => inflated(1));
    ok(!$orm->is_canon(users => $bob), "a value marker is deflated, then clears its row");
    my $ed = $orm->insert(users => {id => 5, name => 'ed'});
    ok($orm->is_canon(users => $ed), "A new row is canon");
    $orm->clear_cache(users => $ed);
    ok(!$orm->is_canon(users => $ed), "clear_cache takes a row object");
    ok($orm->is_canon(users  => $al), "and clears only that row");
    $orm->clear_cache('users');
    ok(!$orm->is_canon(users => $al), "clear_cache(\$table) clears a table");
    $lookup->ingest(users => $al);
    $orm->clear_cache;
    ok(!$orm->is_canon(users => $al), "clear_cache clears everything");

    $bob = $lookup->ingest(users => {id => 1, name => 'bob'});
    $al  = $lookup->ingest(users => {id => 2, name => 'al'});
    $orm->txn(sub { $orm->clear_cache(users => 1) });
    ok(!$orm->is_canon(users => $bob), "clear_cache inside a root transaction stays cleared after commit");
    is($lookup->lookup(users => {id => 1}), undef, "and the row is not cached");
    ok($orm->is_canon(users => $al), "Other rows from before the transaction are still canon");

    $orm->txn(sub { $orm->clear_cache });
    ok(!$orm->is_canon(users => $al), "clear_cache of everything inside a root transaction stays cleared after commit");

    $orm->txn(sub {
        my $inner = $lookup->ingest(users => {id => 3, name => 'cy'});
        eval {
            $orm->txn(sub { $orm->clear_cache(users => 3); die "rollback\n" });
            1;
        };
        ok($orm->is_canon(users => $inner), "A savepoint rollback restores what clear_cache cleared in it");
    });
};

subtest settable_settings => sub {
    my $dbh = dbh();
    $dbh->do("CREATE TABLE events (id INTEGER PRIMARY KEY, at DATETIME)");
    my $orm = DBIx::QuickORM->new(dbh => $dbh);

    my $file = __FILE__;
    my $copy = sub { +{%{$orm->find(events => 1)->row_data}} };
    $orm->insert(events => {id => 1, at => 'soon'});
    like(dies { $orm->update_row(events => $copy->(), {at => 'later'}) }, qr/is not canon/, "Non-canonical data croaks by default");

    $orm->set_enforce_canon(0);
    is($orm->enforce_canon, 0, "set_enforce_canon(0) turns it off");
    ok(lives { $orm->update_row(events => $copy->(), {at => 'later'}) }, "and update_row takes non-canonical data");
    ok(lives { $orm->delete_row(events => $copy->()) },                  "and so does delete_row");
    $orm->insert(events => {id => 1, at => 'soon'});

    $orm->set_enforce_canon(1);
    like(dies { $orm->update_row(events => $copy->(), {at => 'later'}) }, qr/is not canon/, "set_enforce_canon(1) turns it back on for update_row");
    like(dies { $orm->delete_row(events => $copy->()) },                  qr/is not canon/, "and delete_row");

    my $first  = sub { DateTime->new(year => 2001) };
    my $second = sub { DateTime->new(year => 2002) };
    $orm->set_datetime_parsers([$first, $second]);
    my $before = $orm->find(events => 1)->field('at');
    my @list   = ($second, $first);
    $orm->set_datetime_parsers(\@list);
    push @list => 'x';
    is(@{$orm->datetime_parsers}, 2, "set_datetime_parsers stores a copy");
    $orm->clear_cache;
    is($orm->find(events => 1)->field('at')->datetime_ref->year, 2002, "A reordered list takes effect for values read after the call");
    is($before->datetime_ref->year,                              2001, "and a field read before it keeps the parsers it was read with");

    my $line = __LINE__ + 1;
    like(dies { $orm->set_datetime_parsers(['No::Such::Parser']) },    qr/^'datetime_parsers' names the class 'No::Such::Parser', which could not be loaded.*\(from set_datetime_parsers\(\) at \Q$file\E line $line\)/s, "A class that cannot be loaded croaks, naming the caller's line");
    like(dies { $orm->set_datetime_parsers(['DBIx::QuickORM::Row']) }, qr/^'datetime_parsers' names the class 'DBIx::QuickORM::Row', which has no parse_datetime/,                                                        "A class without parse_datetime croaks");
    like(dies { $orm->set_datetime_parsers({}) }, qr/^'datetime_parsers' must be an arrayref of parsers/, "A non-arrayref croaks");
    is(@{$orm->datetime_parsers}, 2, "and a rejected list leaves the parsers as they were");

    ok(!My::Settable::Parser->can('parse_datetime'), "The parser class is not loaded yet");
    unshift @INC => sub {
        return unless $_[1] eq 'My/Settable/Parser.pm';
        my $src = "package My::Settable::Parser; sub parse_datetime { undef } 1;";
        open(my $fh, '<', \$src) or die "Cannot read a string: $!";
        return $fh;
    };
    $orm->connection->set_datetime_parsers(['My::Settable::Parser']);
    ok(My::Settable::Parser->can('parse_datetime'), "The Connection's set_datetime_parsers loads a class it names");

    ok(!$orm->can("set_$_"), "There is no set_$_") for qw/db_map retain_cache isolation time_zone/;
};

subtest find => sub {
    my $dbh = dbh();
    $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT)");
    $dbh->do("CREATE TABLE pairs (a INTEGER, b INTEGER, name TEXT, PRIMARY KEY (a, b))");
    my $orm = DBIx::QuickORM->new(dbh => $dbh);
    my $bob = $orm->insert(users => {id => 1, name => 'bob'});
    $orm->insert(pairs => {a => 1, b => 2, name => 'p'});

    my $found = $orm->find(users => 1);
    isa_ok($found, ['DBIx::QuickORM::Row'], "find returns a row");
    ref_is($found->row_data, $bob->row_data, "the one the ORM holds");
    is($orm->find(users => {id => 1}, data => 1),         {id => 1, name => 'bob'}, "data => 1 returns the row data, and a hashref key works");
    is($orm->find(pairs => [1, 2])->field('name'),        'p',                      "an arrayref key in key order");
    is($orm->find(users => 2),                            undef,                    "undef when there is no such row");
    is($orm->find(users => 1, cache => 0)->field('name'), 'bob',                    "refresh_row's options pass through");
    like(dies { $orm->find(pairs => 1) }, qr/^The table 'pairs' has a compound primary key/, "a bad key croaks as the handle's find does");

    my $copy = DBIx::QuickORM::Row->new(orm => $orm, table => 'users', row_data => {id => 1, name => 'old'});
    my $by   = $orm->find(users => $copy);
    ref_is_not($by, $copy, "A row object as the key finds a new row");
    is($copy->row_data,                                   {id => 1, name => 'old'}, "and the given row is left alone");
    is($orm->handle('users')->find($copy)->field('name'), 'bob',                    "the handle's find too");

    my $mock = mock 'DBIx::QuickORM::Map' => (around => [normalize_pk => sub { my $orig = shift; $main::NORMALIZED++; $orig->(@_) }]);
    local $main::NORMALIZED = 0;
    $orm->find(users => 1);
    $orm->handle('users')->find(1);
    is($main::NORMALIZED,                        2,                        "The key is normalized once per find");
    is($orm->refresh_row(users => 1, data => 1), {id => 1, name => 'bob'}, "refresh_row takes a key in any form too");
};

subtest fresh_lookup_after_fork => sub {
    skip_all "fork is emulated with threads on Windows" if $Config{d_pseudofork};
    my $file   = tempdir(CLEANUP => 1) . '/db.sqlite';
    my $orm    = DBIx::QuickORM->new(connect => sub { DBI->connect("dbi:SQLite:dbname=$file", '', '', {RaiseError => 1}) }, time_zone => 'Europe/Paris', retain_cache => 1, enforce_canon => 0, isolation => 'server', datetime_parsers => [sub { undef }]);
    my $conn   = $orm->connection;
    my $lookup = $conn->lookup;
    my $map    = $orm->db_map;
    my $pid    = fork // die "Could not fork: $!";
    unless ($pid) {
        my $new = $orm->connection;
        my $ok  = $new != $conn && $new->lookup != $lookup && $new->db_map == $map;
        $ok &&= $new->time_zone eq 'Europe/Paris' && $new->retain_cache && !$new->enforce_canon && $new->isolation eq 'server' && @{$new->datetime_parsers} == 1;
        POSIX::_exit($ok ? 0 : 1);
    }
    waitpid($pid, 0);
    is($?, 0, "A forked child's new Connection has a fresh lookup table, the same map, and the old settings");
};

subtest in_memory_fork => sub {
    skip_all "fork is emulated with threads on Windows" if $Config{d_pseudofork};
    my $orm = DBIx::QuickORM->new(connect => sub { dbh() });
    my $pid = fork // die "Could not fork: $!";
    unless ($pid) {
        my $err = (dies { $orm->connection }) // '';
        POSIX::_exit($err =~ m/^This ORM's database cannot be opened by a second connection/ ? 0 : 1);
    }
    waitpid($pid, 0);
    is($?, 0, "A forked child cannot reconnect to an in-memory database, and croaks instead of opening an empty one");
};

subtest no_cycle => sub {
    my $dbh = dbh();
    $dbh->do("CREATE TABLE users (id INTEGER PRIMARY KEY)");
    my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef);
    $orm->insert(users => {id => 1});
    weaken(my $weak = $orm);
    weaken(my $conn = $orm->connection);
    undef $orm;
    is($weak, undef, "The ORM is freed once its holder lets go");
    is($conn, undef, "and so is its Connection, lookup table built and all");
};

subtest dbh_form_connector => sub {
    my $dbh = dbh();
    my $orm = DBIx::QuickORM->new(dbh => $dbh);
    ref_is($orm->connection->dbh, $dbh, "The given handle is used");
    like(dies { $orm->connector->() }, qr/^This ORM was given a 'dbh', so it cannot open another database connection/, "The dbh connector returns the handle once");
};

subtest connection_forms => sub {
    like(dies { DBIx::QuickORM->new() }, qr/^new\(\) needs exactly one of 'dbh', 'connect', or 'credentials' at /, "A connection form is required");
    like(
        dies {
            DBIx::QuickORM->new(dbh => dbh(), connect => sub { dbh() })
        },
        qr/^new\(\) needs exactly one of .*, got: dbh, connect/,
        "Mixing forms croaks"
    );
    like(dies { DBIx::QuickORM->new(dbh         => undef) },                         qr/^'dbh' must be a DBI database handle/,          "dbh must be a handle");
    like(dies { DBIx::QuickORM->new(connect     => 'nope') },                        qr/^'connect' must be a code reference/,           "connect must be code");
    like(dies { DBIx::QuickORM->new(credentials => 'dbi:SQLite::memory:') },         qr/^'credentials' must be a hashref with a 'dsn'/, "credentials must be a hashref");
    like(dies { DBIx::QuickORM->new(credentials => {user => 'x'}) },                 qr/^'credentials' must be a hashref with a 'dsn'/, "credentials needs a dsn");
    like(dies { DBIx::QuickORM->new(credentials => {dsn => 'x', password => 'y'}) }, qr/^Unknown key\(s\) in 'credentials': password/,  "Unknown credential keys croak");
    like(dies { DBIx::QuickORM->new(credentials => {dsn => 'x', attrs => []}) },     qr/^'attrs' in 'credentials' must be a hashref/,   "attrs must be a hashref");
    like(
        dies {
            DBIx::QuickORM->new(connect => sub { 'not a handle' })
        },
        qr/^The connection did not produce a DBI database handle/,
        "A connect sub must return a handle"
    );
};

subtest sql_builder => sub {
    my $default = DBIx::QuickORM->new(dbh => dbh())->sql_builder;
    isa_ok($default, ['DBIx::QuickORM::SQLBuilder::SQLAbstract'], "The default builder is constructed");
    isa_ok(DBIx::QuickORM->new(dbh => dbh(), sql_builder => 'DBIx::QuickORM::SQLBuilder::SQLAbstract')->sql_builder, ['DBIx::QuickORM::SQLBuilder::SQLAbstract'], "A class name is constructed");
    ref_is(DBIx::QuickORM->new(dbh => dbh(), sql_builder => $default)->sql_builder, $default, "An object is used as given");
};

subtest where_builders => sub {
    my @default = map { "DBIx::QuickORM::WhereBuilder::$_" } qw/RawSQL Simple SQLAbstract/;
    is(DBIx::QuickORM->new(dbh => dbh())->where_builders, \@default, "RawSQL, Simple, then SQLAbstract by default");

    my $one = DBIx::QuickORM->new(dbh => dbh(), where_builders => ['DBIx::QuickORM::WhereBuilder::SQLAbstract']);
    is($one->where_builders, ['DBIx::QuickORM::WhereBuilder::SQLAbstract'], "A list of classes replaces it");

    my $obj = bless {}, 'My::WhereObj';
    {
        no strict 'refs';
        *{'My::WhereObj::can_build_where'} = sub { 1 };
        *{'My::WhereObj::build_where'}     = sub { ('1 = 1', []) };
        *{'My::WhereObj::DOES'}            = sub { $_[1] eq 'DBIx::QuickORM::Role::WhereBuilder' || $_[0]->SUPER::DOES($_[1]) };
    }
    ref_is(DBIx::QuickORM->new(dbh => dbh(), where_builders => [$obj])->where_builders->[0], $obj, "An object is used as given");

    like(dies { DBIx::QuickORM->new(dbh => dbh(), where_builders => 'x') },                     qr/^'where_builders' must be a non-empty arrayref of where builders/,                                         "A list is required");
    like(dies { DBIx::QuickORM->new(dbh => dbh(), where_builders => []) },                      qr/^'where_builders' must be a non-empty arrayref of where builders/,                                         "with at least one builder");
    like(dies { DBIx::QuickORM->new(dbh => dbh(), where_builders => [[]]) },                    qr/^'where_builders' must be a non-empty arrayref of where builders/,                                         "each a class or object");
    like(dies { DBIx::QuickORM->new(dbh => dbh(), where_builders => ['No::Such::Where']) },     qr/^'where_builders' names the class 'No::Such::Where', which could not be loaded/,                           "A class that cannot be loaded croaks");
    like(dies { DBIx::QuickORM->new(dbh => dbh(), where_builders => ['DBIx::QuickORM::Row']) }, qr/^'where_builders' names 'DBIx::QuickORM::Row', which does not compose DBIx::QuickORM::Role::WhereBuilder/, "A class without the role croaks");
};

subtest argument_checks => sub {
    like(dies { DBIx::QuickORM->new(dbh => dbh(), bogus => 1, other => 2) }, qr/^Unknown argument\(s\) to new\(\): bogus, other/, "Unknown arguments croak");
    like(
        dies {
            DBIx::QuickORM->new(dbh => dbh(), connector => sub { })
        },
        qr/^Unknown argument\(s\) to new\(\): connector/,
        "Internal slots are not arguments"
    );

    my @bad = (
        [row_class        => {},                      qr/'row_class' must be a class name or undef/],
        [row_class        => '',                      qr/'row_class' must be a class name or undef/],
        [retain_cache     => [],                      qr/'retain_cache' must be a boolean/],
        [enforce_canon    => {},                      qr/'enforce_canon' must be a boolean/],
        [time_zone        => '',                      qr/'time_zone' must be a time zone name/],
        [sql_builder      => [],                      qr/'sql_builder' must be a class name or object/],
        [sql_builder      => 'No::Such::Builder',     qr/'sql_builder' names the class 'No::Such::Builder', which could not be loaded/],
        [sql_builder      => 'DBIx::QuickORM::Row',   qr/'sql_builder' must compose DBIx::QuickORM::Role::SQLBuilder/],
        [datetime_parsers => sub { },                 qr/'datetime_parsers' must be an arrayref of parsers/],
        [datetime_parsers => ['No::Such::Parser'],    qr/'datetime_parsers' names the class 'No::Such::Parser', which could not be loaded/],
        [datetime_parsers => ['DBIx::QuickORM::Row'], qr/'datetime_parsers' names the class 'DBIx::QuickORM::Row', which has no parse_datetime/],
        [datetime_parsers => ['not a class'],         qr/'datetime_parsers' must be an arrayref of parsers/],
        [datetime_parsers => [{}],                    qr/'datetime_parsers' must be an arrayref of parsers/],
    );
    for my $case (@bad) {
        my ($arg, $val, $re) = @$case;
        like(dies { DBIx::QuickORM->new(dbh => dbh(), $arg => $val) }, $re, "Bad '$arg' croaks");
    }
};

subtest driver_rejection => sub {
    my $dbh = DBI->connect('dbi:NullP:', '', '', {RaiseError => 1});
    like(
        dies { DBIx::QuickORM->new(dbh => $dbh) },
        qr/^Unsupported database driver 'DBD::NullP', supported drivers are: DBD::DuckDB, DBD::MariaDB, DBD::Pg, DBD::SQLite/,
        "A driver missing from the table croaks, naming the supported ones",
    );
};

subtest loading => sub {
    my $orm = DBIx::QuickORM->new(dbh => dbh());

    is($orm->require_type('JSON'),                               'DBIx::QuickORM::Type::JSON',        "require_type gives a built-in type's class");
    is($orm->require_type('+DBIx::QuickORM::Test::Type::Upper'), 'DBIx::QuickORM::Test::Type::Upper', "and loads one named with +");
    ok(DBIx::QuickORM::Test::Type::Upper->can('deflate'), "loaded");
    like(dies { $orm->require_type('Nope') },          qr/^The type 'Nope' could not be loaded/,                      "A type that cannot load croaks");
    like(dies { $orm->require_type('Nope', 'types') }, qr/^'types' names the type 'Nope', which could not be loaded/, "naming the context when given");

    ok(lives { $orm->load_row_class('DBIx::QuickORM::Test::RowNS::Users') }, "load_row_class loads a row class");
    ok(DBIx::QuickORM::Test::RowNS::Users->can('new'),                       "loaded");
    like(dies { $orm->load_row_class('Not a class') },                              qr/^The row class 'Not a class' is not a valid package name/,                      "A bad name croaks");
    like(dies { $orm->load_row_class('DBIx::QuickORM::Test::RowNSBroken::Users') }, qr/^The row class 'DBIx::QuickORM::Test::RowNSBroken::Users' could not be loaded/, "A class that fails to load croaks");
};

done_testing;
