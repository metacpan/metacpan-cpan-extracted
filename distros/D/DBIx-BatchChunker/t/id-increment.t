#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Compare;
use Test2::Tools::Exception;
use Test2::Tools::Explain;

use List::Util qw( any max sum );
use Env        qw( BATCHCHUNK_TEST_DEBUG );

use DBIx::BatchChunker;
use CDTest;

############################################################

# Mimic one Galera node: IDs start at an offset and step by the cluster's increment
use constant {
    CHUNK_SIZE   => 3,
    ID_INCREMENT => 10,
    ID_OFFSET    => 3,
    ROW_COUNT    => 20,
};
use constant ID_SPAN => CHUNK_SIZE * ID_INCREMENT;
use constant MAX_ID  => ID_OFFSET + (ROW_COUNT - 1) * ID_INCREMENT;

my $schema      = CDTest->init_schema( no_populate => 1 );
my $producer_rs = $schema->resultset('Producer');

$producer_rs->create({ producerid => $_, name => "Producer $_" }) for map { ID_OFFSET + $_ * ID_INCREMENT } 0 .. ROW_COUNT - 1;

my @expected_counts = ( (CHUNK_SIZE) x int(ROW_COUNT / CHUNK_SIZE), (ROW_COUNT % CHUNK_SIZE) || () );

# Runs DBIC processing over $producer_rs with any extra constructor arguments, and
# returns an arrayref with one hashref of loop state per processed chunk.
my $run_chunker = sub {
    my %args = @_;
    my @chunks;

    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size  => CHUNK_SIZE,
        rs          => $producer_rs,
        coderef     => sub {
            my ($bc, $rs) = @_;
            my $ls = $bc->loop_state;

            push @chunks, {
                start         => $ls->start,
                end           => $ls->end,
                chunk_count   => $ls->chunk_count,
                checked_count => $ls->checked_count,
            };

            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },
        target_time => 0,
        verbose     => 0,
        %args,
    );

    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    $batch_chunker->execute;

    return \@chunks;
};

subtest 'Chunks cover chunk_size * id_increment IDs' => sub {
    my $chunks = $run_chunker->( id_increment => ID_INCREMENT );

    is(
        [ map { $_->{chunk_count} } @$chunks ],
        \@expected_counts,
        'Every chunk holds chunk_size rows, except for the remainder',
    );
    is(
        [ grep { $_->{checked_count} != 1 } @$chunks ],
        [],
        'No chunk needed resizing',
    );
    is(
        [ map { $_->{end} - $_->{start} + 1 } @$chunks[0 .. $#$chunks - 1] ],
        [ (ID_SPAN) x $#$chunks ],
        'Every chunk but the last spans chunk_size * id_increment IDs',
    );
};

subtest 'Without id_increment, chunks need resizing' => sub {
    my $chunks = $run_chunker->();

    ok(
        (any { $_->{checked_count} > 1 } @$chunks),
        'At least one chunk was resized',
    );
    is(sum(map { $_->{chunk_count} } @$chunks), ROW_COUNT, 'All rows were processed');
};

subtest 'DIY Processing + process_past_max' => sub {
    my $max_end = 0;

    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size       => CHUNK_SIZE,
        id_increment     => ID_INCREMENT,
        coderef          => sub {
            my ($bc, $start, $end) = @_;
            $max_end = max($max_end, $end);
        },
        process_past_max => 1,
        target_time      => 0,
        verbose          => 0,
    );

    # DIY mode has no way to look up the range, so it must be set by hand
    $batch_chunker->min_id(ID_OFFSET);
    $batch_chunker->max_id(MAX_ID);
    $batch_chunker->execute;

    is($max_end, MAX_ID + ID_SPAN, 'Final chunk extends chunk_size * id_increment IDs past max_id');
};

subtest 'Errors' => sub {
    like(
        dies {
            DBIx::BatchChunker->new( id_increment => 0, coderef => sub {} );
        },
        qr/^Must be a positive integer \(in \$args->\{"id_increment"\}\)/,
        'constructor dies with a non-positive id_increment',
    );
};

done_testing;
