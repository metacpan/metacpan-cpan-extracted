# NAME

DBIx::QueryLog - Logging queries for DBI

# SYNOPSIS

    use DBIx::QueryLog;
    my $row = $dbh->selectrow_hashref('SELECT * FROM people WHERE user_id = ?', undef, qw/1986/);
    # => SELECT * FROM people WHERE user_id = '1986';

# DESCRIPTION

DBIx::QueryLog logs each execution time and the actual query.

Currently, it works with DBD::mysql, DBD::Pg and DBD::SQLite.

# CLASS METHODS

- threshold

    If set, only queries that take more time than this threshold will be logged (default is undef)

        DBIx::QueryLog->threshold(0.1); # sec

    You can also specify this with `DBIX_QUERYLOG_THRESHOLD` environment variable.

- probability

    If set, the logger logs only once per a defined value. (default is undef)

        DBIx::QueryLog->probability(100); # about 1/100

    You can also specify this with `DBIX_QUERYLOG_PROBABILITY` environment variable.

- logger

    Sets a logger class (e.g. [Log::Dispach](https://metacpan.org/pod/Log::Dispach))

    The logger class must have a \`log\` method, which should work like the one of [Log::Dispatch](https://metacpan.org/pod/Log::Dispatch) (but see also OUTPUT section below).

        DBIx::QueryLog->logger($logger);

- skip\_bind

    If set, DBIx::QueryLog runs faster, but placeholders are not processed.

        DBIx::QueryLog->skip_bind(1);
        my $row = $dbh->do(...);
        # => 'SELECT * FROM people WHERE user_id = ?' : [1986]

    You can also specify this with `DBIX_QUERYLOG_SKIP_BIND` environment variable.

- color

    If set, log messages will be colored with [Term::ANSIColor](https://metacpan.org/pod/Term::ANSIColor).

        DBIx::QueryLog->color('green');

    You can also specify this with `DBIX_QUERYLOG_COLOR` environment variable.

- useqq

    If set, DBIx::QueryLog uses `$Data::Dumper::Useqq`.

        DBIx::QueryLog->useqq(1);

    You can also specify this with `DBIX_QUERYLOG_USEQQ` environment variable.

- compact

    If set, log messages will be compact.

        DBIx::QueryLog->compact(1);
        #  FROM: SELECT          *  FROM      foo WHERE bar = 'baz'
        #  TO  : SELECT * FROM foo WHERE bar = 'baz'

    You can also specify this with `DBIX_QUERYLOG_COMPACT` environment variable.

- explain

    **EXPERIMENTAL**

    If set, DBIx::QueryLog logs the result of a `EXPLAIN` statement.

        DBIx::QueryLog->explain(1);
        my $row = $dbh->do(...);
        # => SELECT * FROM peaple WHERE user_id = '1986'
        #  .----------------------------------------------------------------------------------------------.
        #  | id | select_type | table  | type  | possible_keys | key     | key_len | ref   | rows | Extra |
        #  +----+-------------+--------+-------+---------------+---------+---------+-------+------+-------+
        #  |  1 | SIMPLE      | peaple | const | PRIMARY       | PRIMARY |       4 | const |    1 |       |
        #  '----+-------------+--------+-------+---------------+---------+---------+-------+------+-------'

    You can also specify this with `DBIX_QUERYLOG_EXPLAIN` environment variable.

- show\_data\_source

    if set, DBI data\_source will be added to the log messages.

        $dbh->do('SELECT * FROM sqlite_master');
        # [2012-03-09T00:58:23] [main] [0.000953] SELECT * FROM sqlite_master at foo.pl line 34

        DBIx::QueryLog->show_data_source(1);
        $dbh->do('SELECT * FROM sqlite_master');
        # [2012-03-09T00:58:23] [main] [0.000953] [SQLite:dbname=/tmp/TrSATdY3cc] SELECT * FROM sqlite_master at foo.pl line 56

    You can also specify this with `DBIX_QUERYLOG_SHOW_DATASOURCE` environment variable.

- guard

    Returns a guard object.

        use DBIx::QueryLog ();
        {
            my $guard = DBIx::QueryLog->guard;
            # ... do something
        }

    The following code does the same:

        use DBIx::QueryLog ();

        DBIx::QueryLog->enable;
        # ... do something
        DBIx::QueryLog->disable;

- ignore\_trace

    Returns a guard object and disables tracing while the object is alive.

        use DBIx::QueryLog;

        # enabled
        $dbh->do(...);

        {
            my $guard = DBIx::QueryLog->ignore_trace;
            # disable
            $dbh->do(...);
        }

        # enabled
        $dbh->do(...)

- is\_enabled

    Returns if DBIx::QueryLog is enabled or not.

        use DBIx::QueryLog ();

        say DBIx::QueryLog->is_enabled;

        DBIx::QueryLog->disable;

    See also [Localization](https://metacpan.org/pod/Localization) section.

# TIPS

## Localization

If you want to log only in a specific scope:

    use DBIx::QueryLog (); # or require DBIx::QueryLog;

    DBIx::QueryLog->begin; # or DBIx::QueryLog->enable
    my $row = $dbh->do(...);
    DBIx::QueryLog->end;   # or DBIx::QueryLog->disable

DBIx::QueryLog logs only between `begin` and `end`.

## LOG\_LEVEL

When you set a `logger`, you might also want to change a log level.

    $DBIx::QueryLog::LOG_LEVEL = 'info'; # default 'debug'

## OUTPUT

If you want to change where to output:

    open my $fh, '>', 'dbix_query.log';
    $DBIx::QueryLog::OUTPUT = $fh;

You can also specify a code reference:

    $DBIx::QueryLog::OUTPUT = sub {
        my %params = @_;

        my $format = << 'FORMAT';
    localtime  : %s       # ISO-8601 without timezone
    level      : %s       # log level ($DBIx::QueryLog::LOG_LEVEL)
    time       : %f       # elasped time
    data_source: $s       # data_source
    sql        : %s       # executed query
    bind_params: %s       # bind parameters
    pkg        : %s       # caller package
    file       : %s       # caller file
    line       : %d       # caller line
    FORMAT

        printf $format,
            @params{qw/localtime level pkg time data_source sql/},
            join(', ', @{$params{bind_params}}),
            @params{qw/file line/};

        printf "AutoCommit?: %d\n", $params->{dbh}->{AutoCommit} ? 1 : 0;
    };

You can also use this if you want to use a logger that doesn't have a `log` method like the one of [<Log::Dispatch](https://metacpan.org/pod/<Log::Dispatch)>.

    $DBIx::QueryLog::OUTPUT = sub {
        my %params = @_;
        my $logger = Log::Any->get_logger;
        $logger->debug("$params{message}");
    };

Note that this only works when `<logger`> is not set.

Default `$OUTPUT` is `STDERR`.

# AUTHOR

xaicron <xaicron {at} cpan.org>

# THANKS TO

tokuhirom

yibe

kamipo

tomi-ru

riywo

makamaka

# BUG REPORTING

Plese use github issues: [https://github.com/xaicron/p5-DBIx-QueryLog/issues](https://github.com/xaicron/p5-DBIx-QueryLog/issues).

# COPYRIGHT

Copyright 2010 - xaicron

# LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[DBI](https://metacpan.org/pod/DBI)
