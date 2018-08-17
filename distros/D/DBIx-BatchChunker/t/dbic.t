#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

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

subtest 'DBIC Processing (+ process_past_max)' => sub {
    my $calls = 0;

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $rs) = @_;
            isa_ok($rs, ['DBIx::Class::ResultSet'], '$rs');
            $calls++;
            note explain $bc->_loop_state if $BATCHCHUNK_TEST_DEBUG;
        },

        process_past_max  => 1,
        min_chunk_percent => 0,
        target_time       => 0,
    );

    is($batch_chunker->id_name, 'me.trackid', 'Right id_name guessed');
    isa_ok($batch_chunker->rsc, ['DBIx::Class::ResultSetColumn'], '$rsc');

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;

    # Process

    # NOTE: If the last remaining chunk is exactly the size of chunk_size, the
    # process_past_max code will process one more chunk.  If that chunk is short,
    # it'll use that chunk immediately to the PPM point.  Thus, the +1 here is
    # before the division.
    my $right_calls = ceil( ($range + 1) / $CHUNK_SIZE);
    $batch_chunker->execute;
    cmp_ok($calls, '==', $right_calls, 'Right number of calls');
};

subtest 'DBIC Processing + single_rows (+ rsc)' => sub {
    my $calls = 0;

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        rsc         => $track_rs->get_column('trackid'),
        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $result) = @_;
            isa_ok($result, ['DBIx::Class::Row'], '$result');
            $calls++;
            note explain $bc->_loop_state if $BATCHCHUNK_TEST_DEBUG;
        },

        single_rows       => 1,
        min_chunk_percent => 0,
        target_time       => 0,
    );

    is($batch_chunker->id_name, 'me.trackid', 'Right id_name guessed and aliased');

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    # Process
    $batch_chunker->execute;
    cmp_ok($calls, '==', $track1_count, 'Right number of calls');
};

subtest 'DIY Processing (+ process_past_max)' => sub {
    my $calls = 0;
    my $max_range = 0;

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        rsc     => $track_rs->get_column('trackid'),
        coderef => sub {
            my ($bc, $start, $end) = @_;
            ok(looks_like_number $start,  '$start is a number');
            ok(looks_like_number $end,    '$end   is a number');
            $calls++;

            note explain { start => $start, end => $end } if $BATCHCHUNK_TEST_DEBUG;
        },

        process_past_max => 1,
        target_time      => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;

    # Process
    my $right_calls = ceil( ($range + 1) / $CHUNK_SIZE);  # see PPM note on the first subtest
    $batch_chunker->execute;
    cmp_ok($calls, '==', $right_calls, 'Right number of calls');
};

subtest 'process_past_max + min_chunk_percent' => sub {
    my $calls     = 0;
    my $max_count = 0;
    my $max_id    = 0;

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $rs) = @_;
            isa_ok($rs, ['DBIx::Class::ResultSet'], '$rs');
            $calls++;

            my $ls     = $bc->_loop_state;
            $max_count = $ls->{chunk_count} if $ls->{chunk_count} > $max_count;
            $max_id    = $ls->{end}         if $ls->{end}         > $max_id;

            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },

        process_past_max  => 1,
        target_time       => 0,
        # any missing row in a standard sized chunk will trigger an expansion
        min_chunk_percent => sprintf("%.2f",
            ($CHUNK_SIZE - 1) / $CHUNK_SIZE
        ) + 0.01,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range       = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $real_max_id = $batch_chunker->max_id;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Now, sabotage the max_id, so that process_past_max has to work through multiple chunks
    $batch_chunker->max_id(
        int($range / 2) + $batch_chunker->min_id
    );

    # Process
    my $max_chunk_count = $CHUNK_SIZE * 2 - 1;
    my $max_chunk_calls = ceil($track1_count / $max_chunk_count);

    $batch_chunker->execute;
    cmp_ok($calls,      '<',  $multiplier_range, 'Fewer coderef calls than normal');
    cmp_ok($calls,      '>=', $max_chunk_calls,  'More coderef calls than minimum threshold');
    cmp_ok($max_count,  '<=', $max_chunk_count,  'Did not exceed max chunk percentage');
    cmp_ok($max_id,     '>=', $real_max_id,      'Looked at all of the IDs');
};

subtest 'Automatic execution (DBIC Processing + single_rows + rsc)' => sub {
    my $calls = 0;

    my $batch_chunker = DBIx::BatchChunker->construct_and_execute(
        chunk_size => $CHUNK_SIZE,

        rsc         => $track_rs->get_column('trackid'),
        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $result) = @_;
            isa_ok($result, ['DBIx::Class::Row'], '$result');
            $calls++;
            note explain $bc->_loop_state if $BATCHCHUNK_TEST_DEBUG;
        },

        single_rows       => 1,
        min_chunk_percent => 0,
    );

    isa_ok($batch_chunker, ['DBIx::BatchChunker'], '$bc');
    cmp_ok($calls, '==', $track1_count, 'Right number of calls');
};

# An in-memory SQLite DB is going to be far too fast for any sort of CRUD access, so
# we'd can freely control it with sleep.

subtest 'Runtime targeting (too fast)' => sub {
    my $calls    = 0;
    my $max_size = $CHUNK_SIZE;
    my $max_time = 0;
    my $chunk_size_changes = 0;

    my $batch_chunker = DBIx::BatchChunker->construct_and_execute(
        chunk_size  => $CHUNK_SIZE,
        target_time => 0.5,

        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $rs) = @_;
            isa_ok($rs, ['DBIx::Class::ResultSet'], '$rs');
            $calls++;
            sleep 0.05;

            my $ls = $bc->_loop_state;
            if ($ls->{chunk_size} > $max_size) {
                $max_size = $ls->{chunk_size};
                $chunk_size_changes++;
            }
            $max_time = $ls->{prev_runtime} if $ls->{prev_runtime} && $ls->{prev_runtime} > $max_time;

            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },

        min_chunk_percent => 0,
    );

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);
    my $right_changes    = ceil($calls / 5) - 1;

    cmp_ok($calls,              '<',  $multiplier_range, 'Fewer coderef calls than normal');
    cmp_ok($max_time,           '<',  0.5,               'Never exceeded target time');
    cmp_ok($max_size,           '>',  $CHUNK_SIZE,       'Larger chunk size');
    cmp_ok($chunk_size_changes, '==', $right_changes,    'Right number of chunk size changes');
};

subtest 'Runtime targeting (too slow)' => sub {
    my $calls    = 0;
    my $min_size = $CHUNK_SIZE;
    my $min_time = 999;
    my $chunk_size_changes = 0;

    my $batch_chunker = DBIx::BatchChunker->construct_and_execute(
        chunk_size  => $CHUNK_SIZE,
        target_time => 0.05,

        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $rs) = @_;
            isa_ok($rs, ['DBIx::Class::ResultSet'], '$rs');
            $calls++;
            sleep 0.25;

            my $ls = $bc->_loop_state;
            if ($ls->{chunk_size} < $min_size) {
                $min_size = $ls->{chunk_size};
                $chunk_size_changes++;
            }
            $min_time = $ls->{prev_runtime} if $ls->{prev_runtime} && $ls->{prev_runtime} < $min_time;

            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },

        min_chunk_percent => 0,
    );

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);
    my $right_calls      = $range - $CHUNK_SIZE + 1;

    cmp_ok($calls,    '>',  $multiplier_range, 'Greater coderef calls than normal');
    cmp_ok($calls,    '==', $right_calls,      'Right coderef calls');
    cmp_ok($min_time, '>',  0.05,              'Always exceeded target time');
    cmp_ok($min_size, '==', 1,                 'Right chunk size');
};

subtest 'Retry testing' => sub {
    my $calls = 0;

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $rs) = @_;
            isa_ok($rs, ['DBIx::Class::ResultSet'], '$rs');
            note explain $bc->_loop_state if $BATCHCHUNK_TEST_DEBUG;
            $calls++;
            die "Don't wanna process right now" if $calls % 3;  # fail 2/3rds of the calls
        },

        dbic_retry_opts   => {},  # non-DBIC "defaults"
        min_chunk_percent => 0,
        target_time       => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    my $range = $batch_chunker->max_id - $batch_chunker->min_id + 1;
    my $multiplier_range = ceil($range / $CHUNK_SIZE);

    # Process
    $batch_chunker->execute;
    cmp_ok($calls, '==', $multiplier_range * 3, 'Right number of calls');
};

subtest 'Retry testing + single_rows' => sub {
    my $calls = 0;

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $result) = @_;
            isa_ok($result, ['DBIx::Class::Row'], '$result');
            note explain $bc->_loop_state if $BATCHCHUNK_TEST_DEBUG;
            $calls++;
            # fail one of the rows, which will restart the whole chunk
            die "Don't wanna process right now" unless $calls % ($CHUNK_SIZE + 1);
        },

        dbic_retry_opts   => {},  # non-DBIC "defaults"
        single_rows       => 1,
        min_chunk_percent => 0,
        target_time       => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    # This isn't exact, but it's close enough for a >= compare
    my $rightish_calls = $track1_count + ceil($track1_count / $CHUNK_SIZE) - 1;

    # Process
    $batch_chunker->execute;
    cmp_ok($calls, '>=', $rightish_calls, 'Rightish number of calls');
};

############################################################

done_testing;
