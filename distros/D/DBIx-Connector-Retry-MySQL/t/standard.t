#!/usr/bin/perl

use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use DBIx::Connector::Retry::MySQL;

use Env         qw< DBITEST_DSN >;
use Time::HiRes qw< time sleep >;

############################################################

# The SQL and the lack of a real database doesn't really matter, since the sole purpose
# of this engine is to handle certain exceptions and react to them.  However,
# running this with a proper MySQL DBITEST_DSN would grant some additional $dbh checks.
#
# To specify a MySQL DB, you'll need a call like:
#
# DBITEST_DSN='dbi:mysql:database=ddl_test;host=...' DBITEST_DBUSER=... DBITEST_DBPASS=... prove -lrv t
#
# It will then use that database, instead of a default SQLite one.  Make sure the
# database doesn't have any useful data in it.  The database must exist prior to running
# the test.

our $EXEC_COUNTER    = 0;
our $EXEC_SUCCESS_AT = 4;
our $EXEC_SLEEP_TIME = 0.5;
our @EXEC_ERRORS     = (
    'Deadlock found when trying to get lock; try restarting transaction',
    'Lock wait timeout exceeded; try restarting transaction',
    'MySQL server has gone away',
    'Lost connection to MySQL server during query',
    'WSREP has not yet prepared node for application use',
    'Server shutdown in progress',
);
our $EXEC_UPDATE_SQL = 'SELECT 1';
our $EXEC_ACTUALLY_EXECUTE = 0;

our $UPDATE_FAILED = 0;

our $IS_MYSQL = $DBITEST_DSN && $DBITEST_DSN =~ /^dbi:mysql:/;

### Method redefines
no warnings 'redefine';

my $orig__exec = \&DBIx::Connector::_exec;
*DBIx::Connector::_exec = sub {
    my $dbh       = shift;
    my $code      = shift;  # never used
    my $wantarray = shift;

    $code = sub { $_->do($EXEC_UPDATE_SQL) };

    # Zero-based error, then one-based counter MOD check
    my $error = $EXEC_ERRORS[ $EXEC_COUNTER % @EXEC_ERRORS ];

    my $rv = '0E0';
    if ($EXEC_ACTUALLY_EXECUTE) {
        $rv = eval { $orig__exec->($dbh, $code, $wantarray) };
        $error = $@ if $@;
    }

    sleep $EXEC_SLEEP_TIME if $EXEC_SLEEP_TIME;

    $EXEC_COUNTER++;
    if ($EXEC_COUNTER % $EXEC_SUCCESS_AT) {  # only success at exact divisors
        $UPDATE_FAILED = 1;
        die "DBI Exception: DBD::mysql::st execute failed: $error";
    }
    else {
        $UPDATE_FAILED = 0;
    }

    return $wantarray ? ($rv) : $rv;
};

my $orig_do = \&DBI::db::do;
*DBI::db::do = sub {
    my $sql = $_[1];

    # Ignore override for MySQL
    return $orig_do->(@_) if $IS_MYSQL;

    # If it's a sleep function, emulate it
    if ($sql =~ /SELECT SLEEP\((\d+)\)/) {
        sleep $1;
        return "0E0";
    }

    # Pretend it worked if it's a SET statement
    return "0E0" if $sql =~ /^SET /;

    # Otherwise, continue with the original 'do' method
    return $orig_do->(@_) ;
};

use warnings 'redefine';

my $orig__connect = \&DBIx::Connector::_connect;
sub __connect_test {
    my ($self) = @_;
    return $orig__connect->($self) unless $UPDATE_FAILED;
    $UPDATE_FAILED = 0;

    # Zero-based error, then one-based counter MOD check
    my $error = $EXEC_ERRORS[ $EXEC_COUNTER % @EXEC_ERRORS ];

    sleep $EXEC_SLEEP_TIME if $EXEC_SLEEP_TIME;

    $EXEC_COUNTER++;
    die "DBI Connection failed: DBI connect(...) failed: $error"
        if $EXEC_COUNTER % $EXEC_SUCCESS_AT;  # only success at exact divisors

    return $orig__connect->($self);
}

sub _connector {
    my @extra_args = @_;

    my %args = ( AutoCommit => 1, RaiseError => 1, PrintError => 0 );
    my @conn = $DBITEST_DSN ?
        ( (map { $ENV{"DBITEST_${_}"} || '' } qw/DSN DBUSER DBPASS/), \%args ) :
        ( "dbi:SQLite::memory:", '', '', \%args )
    ;

    my $conn = DBIx::Connector::Retry::MySQL->new( connect_info => \@conn, @extra_args );

    # Create a very basic table, if we're actually using MySQL
    if ($DBITEST_DSN) {
        my $dbh = $conn->dbh;
        $dbh->do("DROP TABLE IF EXISTS dbi_test");
        $dbh->do("CREATE TABLE dbi_test ( a VARCHAR(100) )");
    }

    return $conn;
}

sub run_update_test {
    my %args = @_;

    # Defaults
    $args{duration} //= 0;   # assume complete success
    $args{attempts} //= 1;
    $args{timeout}  //= 25;  # half of 50s timeout

    $args{extra_args} //= {};

    ### DEBUG
    #$args{extra_args}{retry_debug} //= 1;

    # force jitter off to remove randomness from tests
    my $timer_args = $args{extra_args}{timer_options} //= {};
    $timer_args->{jitter_factor}         = 0;
    $timer_args->{timeout_jitter_factor} = 0;

    SKIP: {
        # Set up a new connector each time
        my $conn = _connector(
            $args{extra_args} ? %{ $args{extra_args} } : ()
        );

        # Aggressive timeout skip checks
        my $agg_skip_reason;
        if ($conn->aggressive_timeouts) {
            unless ($IS_MYSQL)                    { $agg_skip_reason = 'with a non-MySQL DSN'; }
            elsif  ($DBD::mysql::VERSION < 4.023) { $agg_skip_reason = 'on this version of DBD::mysql'; }
        }
        skip "Can't use aggressive timeouts $agg_skip_reason", 12 if $agg_skip_reason;

        my $start_time = time;

        if ($args{exception}) {
            my $err = '';
            like(
                $err = dies {
                    $conn->run(ping => sub { 1 });  # coderef replaced later
                },
                $args{exception},
                'SQL dies with proper exception',
            );
            note "Exception: $err";
        }
        else {
            try_ok {
                $conn->run(fixup => sub { 1 });  # coderef replaced later
            }
            'SQL successful';
        }

        # Always add two seconds for lag and code runtimes
        my $duration = time - $start_time;
        note sprintf "Duration: %.2f seconds (range: %u-%u)", $duration, $args{duration}, $args{duration} + 2;
        cmp_ok $duration, '>=', $args{duration},     'expected duration (>=)';
        cmp_ok $duration, '<=', $args{duration} + 2, 'expected duration (<=)';

        is $EXEC_COUNTER,      $args{attempts}, 'expected attempts counter';

        SKIP: {
            skip "DBITEST_DSN not set to a MySQL DB", 8 unless $IS_MYSQL;
            skip "Timeouts are not on in this test",  8 unless $conn->_current_timeout;
            skip "Retry handler is disabled",         8 unless $conn->enable_retry_handler;

            my $dbh           = $conn->dbh;
            my $connect_attrs = $conn->connect_info->[3];
            is $connect_attrs->{$_}, $args{timeout}, "$_ (attr) was reset" for map { "mysql_${_}_timeout" } qw< connect write >;

            my $timeout_vars = $dbh->selectall_hashref("SHOW VARIABLES LIKE '%_timeout'", 'Variable_name');
            is $timeout_vars->{$_}{Value}, $args{timeout}, "$_ (session var) was reset" for map { "${_}_timeout" } qw<
                lock_wait innodb_lock_wait net_read net_write
            >;

            skip "Aggressive timeouts are not on in this test", 2 unless $conn->aggressive_timeouts;

            is $connect_attrs->{$_}, $args{timeout}, "$_ (attr) was reset" for ('mysql_read_timeout');
            is $timeout_vars->{$_}{Value}, $args{timeout}, "$_ (session var) was reset" for ('wait_timeout');
        };
    };
}

############################################################

subtest 'clean_test' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 1;

    run_update_test;
};

subtest 'clean_test_without_timeouts' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 1;

    run_update_test(
        extra_args => {
            timer_options => { max_actual_duration => 0 },
        }
    );
};

subtest 'clean_test_with_disabled_retry_handler' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 1;

    run_update_test(
        extra_args => {
            enable_retry_handler => 0,
        }
    );
};

subtest 'recoverable_failures' => sub {
    local $EXEC_COUNTER    = 0;

    run_update_test(
        duration => 1.41 + 2 + 2.83,  # hitting minimum exponential timeouts each time
        attempts => $EXEC_SUCCESS_AT,
    );
};

subtest 'recoverable_failures_with_longer_pauses' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SLEEP_TIME = 3;

    run_update_test(
        duration => $EXEC_SUCCESS_AT * $EXEC_SLEEP_TIME,
        attempts => $EXEC_SUCCESS_AT,
    );
};

subtest 'connection_failure_after_update_failure' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 3;
    local $EXEC_SLEEP_TIME = 3;

    $UPDATE_FAILED = 0;
    no warnings 'redefine';
    local *DBIx::Connector::_connect = \&__connect_test;
    use warnings 'redefine';

    run_update_test(
        duration => $EXEC_SUCCESS_AT * $EXEC_SLEEP_TIME,
        attempts => $EXEC_SUCCESS_AT,
    );
};

subtest 'connection_failure_before_update_failure' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 2;
    local $EXEC_SLEEP_TIME = 3;

    $UPDATE_FAILED = 1;
    no warnings 'redefine';
    local *DBIx::Connector::_connect = \&__connect_test;
    use warnings 'redefine';

    run_update_test(
        duration => $EXEC_SUCCESS_AT * $EXEC_SLEEP_TIME,
        attempts => $EXEC_SUCCESS_AT,
    );
};

subtest 'non_retryable_failure' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SLEEP_TIME = 3;
    local @EXEC_ERRORS     = (
        "Duplicate entry '1-1' for key 'PRIMARY'",
    );

    run_update_test(
        duration  => $EXEC_SLEEP_TIME,
        attempts  => 1,
        exception => qr{Failed run coderef: Exception not transient, attempts: 1 / 8, timer: [\d\.]+ / 50.0 sec, last exception:.+DBI Exception: DBD::mysql::st execute failed: Duplicate entry .+ for key},
        extra_args => {
            # Also test this setting
            retries_before_error_prefix => 0,
        },
    );
};

subtest 'ran_out_of_attempts' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 8;
    local $EXEC_SLEEP_TIME = 2;

    run_update_test(
        duration  => 4 * $EXEC_SLEEP_TIME,
        attempts  => 4,
        exception => qr{Out of retries, attempts: [\d\s./]+, timer: [\d\s./]+ sec, last exception:.+DBI Exception: DBD::mysql::st execute failed: Lost connection to MySQL server during query},
        extra_args => {
            timer_options => { max_attempts => 4 },
        }
    );
};

subtest 'recoverable_failures_with_timeouts' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SLEEP_TIME = 2;

    run_update_test(
        duration => $EXEC_SUCCESS_AT * $EXEC_SLEEP_TIME,
        attempts => $EXEC_SUCCESS_AT,
        timeout  => 10,  # half of 20s timeout
        extra_args => {
            timer_options => { max_actual_duration => 20 },
        }
    );
};

subtest 'ran_out_of_time' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 8;
    local $EXEC_SLEEP_TIME = 5;

    run_update_test(
        duration  => 25,  # should get a 5s timeout after the fourth attempt
        attempts  => 5,
        timeout   => 11,  # half of 22s timeout
        exception => qr/DBI Exception: DBD::mysql::st execute failed: WSREP has not yet prepared node for application use/,
        extra_args => {
            timer_options => { max_actual_duration => 22 },
        }
    );
};

subtest 'failure_with_disabled_retry_handler' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 8;
    local $EXEC_SLEEP_TIME = 5;

    run_update_test(
        duration  => 5,
        attempts  => 1,
        exception => qr/DBI Exception: DBD::mysql::st execute failed: Deadlock found when trying to get lock; try restarting transaction/,
        extra_args => {
            enable_retry_handler => 0,
        }
    );
};

subtest 'aggressive_timeouts_off' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 1;
    local $EXEC_SLEEP_TIME = 0;
    local $EXEC_UPDATE_SQL = 'SELECT SLEEP(17)';
    local $EXEC_ACTUALLY_EXECUTE = 1;

    run_update_test(
        duration  => 17,
        attempts  => 1,
        timeout   => 11,  # half of 22s timeout
        extra_args => {
            aggressive_timeouts => 0,
            timer_options => { max_actual_duration => 22 },
        }
    );
};

subtest 'aggressive_timeouts_on' => sub {
    local $EXEC_COUNTER    = 0;
    local $EXEC_SUCCESS_AT = 8;
    local $EXEC_SLEEP_TIME = 0;
    local $EXEC_UPDATE_SQL = 'SELECT SLEEP(17)';
    local $EXEC_ACTUALLY_EXECUTE = 1;

    run_update_test(
        duration  => 11 + 1.41 + 5 + 2 + 5,  # should get a 5s timeout after the fourth attempt
        attempts  => 4,
        timeout   => 11,  # half of 22s timeout
        exception => qr/DBI Exception: DBD::mysql::st execute failed: DBD::mysql::db do failed: Lost connection to MySQL server during query/,
        extra_args => {
            aggressive_timeouts => 1,
            timer_options => { max_actual_duration => 22 },
        }
    );
};

############################################################

done_testing;
