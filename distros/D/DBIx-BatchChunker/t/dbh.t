#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use List::Util   qw( max );
use POSIX        qw( ceil );
use Scalar::Util qw( looks_like_number );
use Time::HiRes  qw( time sleep );
use Env          qw( BATCHCHUNK_TEST_DEBUG CDTEST_DSN CDTEST_DBUSER CDTEST_DBPASS );

use DBIx::BatchChunker;
use DBIx::Connector::Retry;
use CDTest;

use Path::Class 'file';

my $FILE = file(__FILE__);
my $root = $FILE->dir->parent;
my $db_file = $root->file('t', $FILE->basename.'.db');

############################################################

my $CHUNK_SIZE = 3;

# Enforce a real file SQLite DB if default
unless ($CDTEST_DSN) {
    $CDTEST_DSN    = "dbi:SQLite:dbname=$db_file";
    $CDTEST_DBUSER = '';
    $CDTEST_DBPASS = '';
}

my $schema       = CDTest->init_schema;
my $track_rs     = $schema->resultset('Track')->search({ position => 1 });
my $track1_count = $track_rs->count;

my $dbh = $schema->storage->dbh;
my @connect_info = @{ $schema->storage->connect_info };
my $conn = DBIx::Connector::Retry->new( connect_info => \@connect_info );

$Data::Dumper::Maxdepth = 1;

subtest 'Active DBI Processing (+ sleep)' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        dbi_connector => $conn,
        min_stmt => 'SELECT MIN(trackid) FROM track WHERE position = 1',
        max_stmt => 'SELECT MAX(trackid) FROM track WHERE position = 1',
        stmt     => 'SELECT ?, ?',

        target_time => 0,
        sleep       => 0.1,
        verbose     => 0,
    );

    # Can't exactly make 'stmt' an "active" statement, but we can add a callback
    $conn->dbh->{Callbacks} = {
        ChildCallbacks => {
            execute => sub {
                my ($sth, $start, $end) = @_;
                $max_end = max($max_end, $end);
                $calls++;
                return;    # DBI callback cannot return anything
            },
        },
    };

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Process
    my $start_time = time;
    $batch_chunker->execute;
    my $total_time = time - $start_time;
    cmp_ok($calls,      '==', $multiplier_range,       'Right number of calls');
    cmp_ok($max_end,    '==', $batch_chunker->max_id,  'Final chunk ends at max_id');
    cmp_ok($total_time, '>=', $multiplier_range * 0.1, 'Slept ok');
    cmp_ok($total_time, '<',  $multiplier_range * 0.5, 'Did not oversleep');

    # Remove the callback completely
    my $dbh = $conn->dbh;
    delete $dbh->{Callbacks}{ChildCallbacks}{execute};
    delete $dbh->{Callbacks}{ChildCallbacks};
    delete $dbh->{Callbacks};
};

subtest 'Query DBI Processing (+ min_chunk_percent)' => sub {
    my ($calls, $max_end, $max_range) = (0, 0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        dbi_connector => $conn,
        min_stmt   => 'SELECT MIN(trackid)   FROM track WHERE position = 1',
        max_stmt   => 'SELECT MAX(trackid)   FROM track WHERE position = 1',
        stmt       => 'SELECT trackid        FROM track WHERE position = 1 AND trackid BETWEEN ? AND ?',
        count_stmt => 'SELECT COUNT(trackid) FROM track WHERE position = 1 AND trackid BETWEEN ? AND ?',
        coderef    => sub {
            my ($bc, $sth) = @_;
            isa_ok($sth, ['DBI::st'], '$sth');
            $calls++;

            my $ls = $bc->loop_state;
            $max_end = max($max_end, $ls->end);

            my $range  = $ls->end - $ls->start + 1;
            $max_range = max($max_range, $range);
            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },

        target_time       => 0,
        # any missing row in a standard sized chunk will trigger an expansion
        min_chunk_percent => sprintf("%.2f",
            ($CHUNK_SIZE - 1) / $CHUNK_SIZE
        ) + 0.01,
        verbose           => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Process
    $batch_chunker->execute;
    cmp_ok($calls,      '<',  $multiplier_range,      'Fewer coderef calls than normal');
    cmp_ok($max_end,    '==', $batch_chunker->max_id, 'Final chunk ends at max_id');
    cmp_ok($max_range,  '>',  $CHUNK_SIZE,            'Expanded chunk at least once');
};

subtest 'Query DBI Processing + single_row (+ rsc)' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        ### NOTE: This mixing of DBI/C is unconventional, but still acceptable
        rsc       => $track_rs->get_column('trackid'),

        dbi_connector => $conn,
        stmt       => ['SELECT *              FROM track WHERE position = ? AND trackid BETWEEN ? AND ?', undef, 1],
        count_stmt => ['SELECT COUNT(trackid) FROM track WHERE position = ? AND trackid BETWEEN ? AND ?', undef, 1],

        coderef => sub {
            my ($bc, $row) = @_;
            like($row, {
                trackid  => qr/[0-9]+/,
                cd       => qr/[0-9]+/,
                position => 1,
                title    => qr/\w+/,
            }, '$row + keys');
            $calls++;

            my $ls = $bc->loop_state;
            $max_end = max($max_end, $ls->end);

            if ($BATCHCHUNK_TEST_DEBUG) {
                note explain $ls;
                note explain $row;
            }
        },

        single_rows => 1,
        target_time => 0,
        debug       => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    # Process
    $batch_chunker->execute;
    cmp_ok($calls,   '==', $track1_count,          'Right number of calls');
    cmp_ok($max_end, '==', $batch_chunker->max_id, 'Final chunk ends at max_id');
};

subtest 'DIY Processing (+ min_chunk_percent)' => sub {
    my ($calls, $max_end, $max_range) = (0, 0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        dbi_connector => $conn,
        min_stmt   => ['SELECT MIN(trackid)   FROM track WHERE position = ?', undef, 1],
        max_stmt   => ['SELECT MAX(trackid)   FROM track WHERE position = ?', undef, 1],
        count_stmt => ['SELECT COUNT(trackid) FROM track WHERE position = ? AND trackid BETWEEN ? AND ?', undef, 1],
        coderef    => sub {
            my ($bc, $start, $end) = @_;
            ok(looks_like_number $start,  '$start is a number');
            ok(looks_like_number $end,    '$end   is a number');
            $calls++;

            my $ls = $bc->loop_state;
            $max_end = max($max_end, $end);

            my $range  = $ls->end - $ls->start + 1;
            $max_range = max($max_range, $range);
            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },

        target_time       => 0,
        # any missing row in a standard sized chunk will trigger an expansion
        min_chunk_percent => sprintf("%.2f",
            ($CHUNK_SIZE - 1) / $CHUNK_SIZE
        ) + 0.01,
        debug             => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Process
    $batch_chunker->execute;
    cmp_ok($calls,      '<',  $multiplier_range,      'Fewer coderef calls than normal');
    cmp_ok($max_end,    '==', $batch_chunker->max_id, 'Final chunk ends at max_id');
    cmp_ok($max_range,  '>',  $CHUNK_SIZE,            'Expanded chunk at least once');
};

subtest 'DIY Processing (manual range calculations)' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        coderef    => sub {
            my ($bc, $start, $end) = @_;
            ok(looks_like_number $start,  '$start is a number');
            ok(looks_like_number $end,    '$end   is a number');
            $calls++;

            my $ls = $bc->loop_state;
            $max_end = max($max_end, $end);

            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },

        target_time => 0,
        verbose     => 0,
    );
    $batch_chunker->min_id(4);
    $batch_chunker->max_id(70);

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Process
    $batch_chunker->execute;
    cmp_ok($calls,   '==', $multiplier_range,      'Right number of calls');
    cmp_ok($max_end, '==', $batch_chunker->max_id, 'Final chunk ends at max_id');
};

subtest 'Retry testing' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        dbi_connector => $conn,
        min_stmt => 'SELECT MIN(trackid) FROM track WHERE position = 1',
        max_stmt => 'SELECT MAX(trackid) FROM track WHERE position = 1',
        stmt     => 'SELECT ?, ?',

        min_chunk_percent => 0,
        target_time       => 0,
        verbose           => 0,
    );

    # Add a callback that includes dying on execute to encourage retries
    $conn->dbh->{Callbacks} = {
        ChildCallbacks => {
            execute => sub {
                my ($sth, $start, $end) = @_;
                $max_end = max($max_end, $end);
                $calls++;
                die "Don't wanna execute right now" if $calls % 3;  # fail 2/3rds of the calls
                return;  # DBI callback cannot return anything
            },
        },
    };

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Process
    $batch_chunker->execute;
    cmp_ok($calls,   '==', $multiplier_range * 3,  'Right number of calls');
    cmp_ok($max_end, '==', $batch_chunker->max_id, 'Final chunk ends at max_id');
};

subtest 'Retry testing + single_rows' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        dbi_connector => $conn,
        min_stmt   => 'SELECT MIN(trackid) FROM track WHERE position = 1',
        max_stmt   => 'SELECT MAX(trackid) FROM track WHERE position = 1',
        stmt       => ['SELECT *              FROM track WHERE position = ? AND trackid BETWEEN ? AND ?', undef, 1],
        count_stmt => ['SELECT COUNT(trackid) FROM track WHERE position = ? AND trackid BETWEEN ? AND ?', undef, 1],
        coderef => sub {
            my ($bc, $row) = @_;
            like($row, {
                trackid  => qr/[0-9]+/,
                cd       => qr/[0-9]+/,
                position => 1,
                title    => qr/\w+/,
            }, '$row + keys');
            $calls++;

            my $ls = $bc->loop_state;
            $max_end = max($max_end, $ls->end);

            if ($BATCHCHUNK_TEST_DEBUG) {
                note explain $ls;
                note explain $row;
            }

            # fail one of the rows, which will restart the whole chunk
            die "Don't wanna process right now" unless $calls % ($CHUNK_SIZE + 1);
        },

        single_rows       => 1,
        min_chunk_percent => 0,
        target_time       => 0,
        verbose           => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    # This isn't exact, but it's close enough for a >= compare
    my $rightish_calls = $track1_count + ceil($track1_count / $CHUNK_SIZE) - 1;

    # Process
    $batch_chunker->execute;
    cmp_ok($calls,   '>=', $rightish_calls,        'Rightish number of calls');
    cmp_ok($max_end, '==', $batch_chunker->max_id, 'Final chunk ends at max_id');
};

subtest 'Chunk resizing with non-unique IDs' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        dbi_connector => $conn,
        id_name    => 'cd',
        min_stmt   => 'SELECT MIN(cd) FROM track',
        max_stmt   => 'SELECT MAX(cd) FROM track',
        count_stmt => 'SELECT COUNT(*) FROM track WHERE cd BETWEEN ? AND ?',
        stmt       => 'SELECT ?, ?',

        target_time => 0,
        sleep       => 0.1,
        verbose     => 0,
    );

    # Can't exactly make 'stmt' an "active" statement, but we can add a callback
    $conn->dbh->{Callbacks} = {
        ChildCallbacks => {
            execute => sub {
                my ($sth, $start, $end) = @_;
                $max_end = max($max_end, $end);
                $calls++;
                return
            },  # DBI callback cannot return anything
        },
    };

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Process
    my $start_time = time;
    $batch_chunker->execute;
    my $total_time = time - $start_time;

    cmp_ok($calls,      '>=', $multiplier_range,       'Rightish number of calls');
    cmp_ok($max_end,    '==', $batch_chunker->max_id,  'Final chunk ends at max_id');
    cmp_ok($total_time, '>=', $multiplier_range * 0.1, 'Slept ok');
    cmp_ok($total_time, '<',  $multiplier_range * 0.5, 'Did not oversleep');

    # Remove the callback completely
    my $dbh = $conn->dbh;
    delete $dbh->{Callbacks}{ChildCallbacks}{execute};
    delete $dbh->{Callbacks}{ChildCallbacks};
    delete $dbh->{Callbacks};
};

############################################################

unlink $db_file if -e $db_file;

done_testing;
