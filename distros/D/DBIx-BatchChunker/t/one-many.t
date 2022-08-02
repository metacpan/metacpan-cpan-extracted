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

# Starting at Genre all the way down to Track, which is a really improper level to process
# chunks from.  Each related_resultset call transfers the main table.  The Row:ID ratio
# should be rather high here.

my $schema      = CDTest->init_schema;
my $track_rs    = $schema->resultset('Track')->related_resultset('cd')->related_resultset('genreid');
my $track_count = $track_rs->count;
my $genre_count = $schema->resultset('Genre')->count;

$Data::Dumper::Maxdepth = 1;

subtest 'One->Many Processing' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,

        rs          => $track_rs,
        coderef     => sub {
            my ($bc, $rs) = @_;
            isa_ok($rs, ['DBIx::Class::ResultSet'], '$rs');
            $calls++;

            my $ls = $bc->loop_state;
            $max_end = max($max_end, $ls->end);

            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },
        target_time => 0,
        verbose     => 0,
    );

    is($batch_chunker->id_name, 'genreid.genreid', 'Right id_name guessed');
    isa_ok($batch_chunker->rsc, ['DBIx::Class::ResultSetColumn'], '$rsc');

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    ok($batch_chunker->min_id,           'min_id ok');
    ok($batch_chunker->max_id,           'max_id ok');

    # Process

    ### XXX: At a large enough $CHUNK_SIZE, this might not be accurate
    my $right_calls = $genre_count;

    $batch_chunker->execute;
    cmp_ok($calls,   '==', $right_calls,           'Right number of calls');
    cmp_ok($max_end, '==', $batch_chunker->max_id, 'Final chunk ends at max_id');
};

############################################################

done_testing;
