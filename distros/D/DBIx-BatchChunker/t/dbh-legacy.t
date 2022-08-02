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
use Env          qw( BATCHCHUNK_TEST_DEBUG );

use DBIx::BatchChunker;
use CDTest;

############################################################

my $CHUNK_SIZE = 3;

my $schema       = CDTest->init_schema;
my $track_rs     = $schema->resultset('Track')->search({ position => 1 });
my $track1_count = $track_rs->count;

my $dbh = $schema->storage->dbh;

$Data::Dumper::Maxdepth = 1;

subtest 'Active DBI Processing (+ sleep)' => sub {
    my ($calls, $max_end) = (0, 0);

    # Can't exactly make it an "active" statement
    my $sth = $dbh->prepare('SELECT ?, ?');

    # Constructor
    my $legacy_warning;
    local $SIG{__WARN__} = sub { $legacy_warning = shift };
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        min_sth => $dbh->prepare('SELECT MIN(trackid) FROM track WHERE position = 1'),
        max_sth => $dbh->prepare('SELECT MAX(trackid) FROM track WHERE position = 1'),
        sth     => $sth,

        target_time => 0,
        sleep       => 0.1,
        verbose     => 0,
    );
    $SIG{__WARN__} = '';
    like $legacy_warning, qr/considered legacy usage/, 'warned about legacy usage';

    # We need to add a callback.  Unfortunately, we can't add the callback into the $sth in legacy
    # mode, but we can tweak the $dbh.
    $batch_chunker->dbi_connector->{_dbh}{Callbacks} = {
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
    my $dbh = $batch_chunker->dbi_connector->{_dbh};
    delete $dbh->{Callbacks}{ChildCallbacks}{execute};
    delete $dbh->{Callbacks}{ChildCallbacks};
    delete $dbh->{Callbacks};
};

subtest 'Query DBI Processing (+ min_chunk_percent)' => sub {
    my ($calls, $max_end, $max_range) = (0, 0, 0);

    # Constructor
    my $legacy_warning;
    local $SIG{__WARN__} = sub { $legacy_warning = shift };
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        min_sth   => $dbh->prepare('SELECT MIN(trackid)   FROM track WHERE position = 1'),
        max_sth   => $dbh->prepare('SELECT MAX(trackid)   FROM track WHERE position = 1'),
        sth       => $dbh->prepare('SELECT trackid        FROM track WHERE position = 1 AND trackid BETWEEN ? AND ?'),
        count_sth => $dbh->prepare('SELECT COUNT(trackid) FROM track WHERE position = 1 AND trackid BETWEEN ? AND ?'),
        coderef   => sub {
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
    $SIG{__WARN__} = '';
    like $legacy_warning, qr/considered legacy usage/, 'warned about legacy usage';

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
    my $legacy_warning;
    local $SIG{__WARN__} = sub { $legacy_warning = shift };
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        ### NOTE: This mixing of DBI/C is unconventional, but still acceptable
        rsc       => $track_rs->get_column('trackid'),
        sth       => $dbh->prepare('SELECT *              FROM track WHERE position = 1 AND trackid BETWEEN ? AND ?'),
        count_sth => $dbh->prepare('SELECT COUNT(trackid) FROM track WHERE position = 1 AND trackid BETWEEN ? AND ?'),

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
    $SIG{__WARN__} = '';
    like $legacy_warning, qr/considered legacy usage/, 'warned about legacy usage';

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
    my $legacy_warning;
    local $SIG{__WARN__} = sub { $legacy_warning = shift };
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        min_sth   => $dbh->prepare('SELECT MIN(trackid)   FROM track WHERE position = 1'),
        max_sth   => $dbh->prepare('SELECT MAX(trackid)   FROM track WHERE position = 1'),
        count_sth => $dbh->prepare('SELECT COUNT(trackid) FROM track WHERE position = 1 AND trackid BETWEEN ? AND ?'),
        coderef   => sub {
            my ($bc, $start, $end) = @_;
            ok(looks_like_number $start,  '$start is a number');
            ok(looks_like_number $end,    '$end   is a number');
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
    $SIG{__WARN__} = '';
    like $legacy_warning, qr/considered legacy usage/, 'warned about legacy usage';

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

############################################################

done_testing;
