# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::MySQL;

my $D = 'DBIx::QuickORM::Dialect::MySQL';

# A handle that records the SQL it is given and answers queries from %answers.
sub fake_dbh {
    my (%answers) = @_;
    my @sql;
    my $dbh = mock {} => (
        add => [
            do              => sub { push @sql => $_[1]; 1 },
            quote           => sub { "'$_[1]'" },
            selectrow_array => sub { push @sql => $_[1]; $answers{$_[1]} },
        ],
    );
    return ($dbh, \@sql);
}

subtest facts => sub {
    is($D->quote_char,                                                                                     '`',                                                                      "Backtick quoting");
    is($D->quote_identifier('a`b'),                                                                        '`a``b`',                                                                 "Doubles a backtick inside the name");
    is([map { $D->$_ } qw/supports_returning_insert supports_returning_update supports_returning_delete/], [0, 0, 0],                                                                "No RETURNING");
    is($D->supports_savepoints,                                                                            1,                                                                        "Savepoints");
    is($D->bind_limit,                                                                                     65535,                                                                    "Prepared statement placeholder limit");
    is([$D->datetime_format],                                                                              ['DateTime::Format::MySQL', 'DateTime::Format::MySQL', {timestamp => 1}], "DateTime::Format::MySQL parses and formats dates; TIMESTAMP stores an instant");
};

subtest begin_sql => sub {
    is([$D->begin_sql],                   ['BEGIN'],                                                   "BEGIN without a level");
    is([$D->begin_sql('READ COMMITTED')], ['SET TRANSACTION ISOLATION LEVEL READ COMMITTED', 'BEGIN'], "The next transaction's level, then BEGIN");
    is($D->supports_isolation,            1,                                                           "Levels can be set");
};

subtest dialect_choice => sub {
    my ($dbh, $sql) = fake_dbh('SELECT version()' => '8.4.0');
    is($D->dialect_for_dbh($dbh), $D,                   "A MySQL server gets the MySQL dialect");
    is($sql,                      ['SELECT version()'], "decided by the server version");

    ($dbh) = fake_dbh('SELECT version()' => '8.4.11-11');
    is($D->dialect_for_dbh($dbh), $D, "Percona is MySQL");

    ($dbh) = fake_dbh('SELECT version()' => '11.8.2-MariaDB-log');
    is($D->dialect_for_dbh($dbh), 'DBIx::QuickORM::Dialect::MariaDB', "A MariaDB server gets the MariaDB dialect");
};

subtest namespace => sub {
    my ($dbh, $sql) = fake_dbh('SELECT DATABASE()' => 'quickdb');
    is($D->namespace($dbh), 'quickdb', "The current database");
    ($dbh) = fake_dbh();
    is($D->namespace($dbh), undef, "undef when none is selected");
};

subtest init_session => sub {
    my ($dbh, $sql) = fake_dbh();
    $D->init_session($dbh, 'UTC');
    is($sql,                              ['SET NAMES utf8mb4', "SET time_zone = '+00:00'"], "utf8mb4, then UTC as an offset");
    is($dbh->{private_DBIx_QuickORM_pid}, $$,                                                "Records the owning pid");

    ($dbh, $sql) = fake_dbh();
    $D->init_session($dbh, 'Europe/Paris');
    is($sql->[-1], "SET time_zone = 'Europe/Paris'", "Other names are passed through");
};

subtest error_kind => sub {
    my %kinds = (
        1205 => 'lock_timeout',
        1213 => 'deadlock',
        1062 => 'unique_violation',
        1452 => 'foreign_key_violation',
        1451 => 'foreign_key_violation',
        1048 => 'not_null_violation',
        1364 => 'not_null_violation',
        3819 => 'check_violation',
    );
    is($D->error_kind($_,   'HY000', 'text'), $kinds{$_}, "native $_ is $kinds{$_}") for sort keys %kinds;
    is($D->error_kind(1213, '40001', 'text'), 'deadlock', "The native code beats the SQLSTATE");
    is($D->error_kind(1146, '42S02', 'text'), undef,      "An unknown code has no kind");
};

subtest release_inherited => sub {
    my $disconnects = 0;
    my $dbh         = mock {Active => 0} => (add => [disconnect => sub { $disconnects++ }]);
    $D->release_inherited($dbh);
    is($disconnects, 0, "An inactive handle is left alone");

    $dbh = mock {Active => 1, Warn => 1} => (add => [disconnect => sub { $disconnects++ }]);
    $D->release_inherited($dbh);
    is($disconnects, 1, "An active handle is disconnected");
    is($dbh->{Warn}, 0, "without warnings about the parent's statements");
};

subtest field_facts => sub {
    is($D->field_facts('int(11) unsigned'), {db_type => 'int(11) unsigned', type => 'int',     affinity => 'numeric'}, "An integer's display width is not a size");
    is($D->field_facts('tinyint(1)'),       {db_type => 'tinyint(1)',       type => 'tinyint', affinity => 'numeric'}, "Nor tinyint's");
    is($D->field_facts('varchar(20)'),      {db_type => 'varchar(20)', type => 'varchar', affinity => 'string', size => 20}, "Other sizes stay");
};

done_testing;
