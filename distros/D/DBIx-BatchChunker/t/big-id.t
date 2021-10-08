#!/usr/bin/perl

use lib qw(t/lib);
use strict;
use warnings;

use Test2::Bundle::More;
use Test2::Tools::Explain;

use List::Util   qw( max );
use POSIX        qw( ceil );
use Math::BigInt;
use Scalar::Util qw( looks_like_number );
use Time::HiRes  qw( time sleep );
use Env          qw( BATCHCHUNK_TEST_DEBUG );

use DBIx::BatchChunker;
use CDTest;

############################################################

my $schema      = CDTest->init_schema( no_populate => 1 );
my $producer_rs = $schema->resultset('Producer');

# Pretend the name field contains very large numeric IDs
for my $i ( 1 .. 20 ) {
    my $zeropad = sprintf '%.2u', $i;
    # side-stepping varchar->int casting issues with the DB
    my $big_id = '9'.($zeropad x 20);

    $producer_rs->create({
        producerid => $i,
        name       => $big_id,
    });
}

my $min_id = Math::BigInt->new('9'.('01' x 20));
my $mid_id = Math::BigInt->new('9'.('15' x 20));
my $max_id = Math::BigInt->new('9'.('20' x 20));
my $step   = Math::BigInt->new('01' x 20);

# Stolen from DBIx::BatchChunker
my @BIGNUM_LS_ATTRS = (qw< start end prev_end multiplier_range multiplier_step chunk_size chunk_count >);

my $CHUNK_SIZE = $step;

$Data::Dumper::Maxdepth = 1;

subtest 'DBIC Processing + process_past_max' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,
        rs         => $producer_rs,
        id_name    => 'name',

        coderef     => sub {
            my ($bc, $rs) = @_;
            $calls++;
            subtest "Row $calls" => sub {
                isa_ok($rs, ['DBIx::Class::ResultSet'], '$rs');

                my $ls = $bc->loop_state;
                $max_end = max($max_end, $ls->end);

                foreach my $attr (@BIGNUM_LS_ATTRS) {
                    my $val = $ls->$attr();
                    next unless defined $val;
                    my $class = $attr =~ /multiplier/ ? 'Math::BigFloat' : 'Math::BigInt';
                    isa_ok($val, [$class], "$attr isa $class");
                }

                note explain $ls if $BATCHCHUNK_TEST_DEBUG;
            };
        },

        process_past_max  => 1,
        min_chunk_percent => 0,
        target_time       => 1,
    );

    isa_ok($batch_chunker->rsc, ['DBIx::Class::ResultSetColumn'], '$rsc');

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    cmp_ok($batch_chunker->min_id, '==', $min_id, 'min_id accurate');
    cmp_ok($batch_chunker->max_id, '==', $max_id, 'max_id accurate');

    isa_ok($batch_chunker->chunk_size, ['Math::BigInt'], 'chunk_size isa BigInt');
    isa_ok($batch_chunker->min_id,     ['Math::BigInt'], 'min_id isa BigInt');
    isa_ok($batch_chunker->max_id,     ['Math::BigInt'], 'max_id isa BigInt');

    # Force process_past_max to re-look it up
    $batch_chunker->max_id($mid_id);

    my $range = $max_id - $min_id + 1;

    # Process
    $batch_chunker->execute;
    cmp_ok($calls,   '==', 21,      'Right number of calls');
    cmp_ok($max_end, '==', $max_id, 'Final chunk ends at max_id');
};

subtest 'DBIC Processing + single_rows' => sub {
    my ($calls, $max_end) = (0, 0);

    # Constructor
    my $checked_ls_isas = 0;
    my $batch_chunker = DBIx::BatchChunker->new(
        chunk_size => $CHUNK_SIZE,
        rs         => $producer_rs,
        id_name    => 'name',

        coderef     => sub {
            my ($bc, $result) = @_;
            isa_ok($result, ['DBIx::Class::Row'], '$result');
            $calls++;

            my $ls = $bc->loop_state;
            $max_end = max($max_end, $ls->end);

            unless ($checked_ls_isas) {
                foreach my $attr (@BIGNUM_LS_ATTRS) {
                    my $val = $ls->$attr();
                    next unless defined $val;
                    my $class = $attr =~ /multiplier/ ? 'Math::BigFloat' : 'Math::BigInt';
                    isa_ok($val, [$class], "$attr isa $class");
                }
                $checked_ls_isas = 1;
            }

            note explain $ls if $BATCHCHUNK_TEST_DEBUG;
        },

        single_rows       => 1,
        min_chunk_percent => 0,
        target_time       => 0,
    );

    # Calculate
    ok($batch_chunker->calculate_ranges, 'calculate_ranges ok');
    cmp_ok($batch_chunker->min_id, '==', $min_id, 'min_id accurate');
    cmp_ok($batch_chunker->max_id, '==', $max_id, 'max_id accurate');

    isa_ok($batch_chunker->chunk_size, ['Math::BigInt'], 'chunk_size isa BigInt');
    isa_ok($batch_chunker->min_id,     ['Math::BigInt'], 'min_id isa BigInt');
    isa_ok($batch_chunker->max_id,     ['Math::BigInt'], 'max_id isa BigInt');

    # Process
    $batch_chunker->execute;

    my $max_id = $batch_chunker->max_id;
    cmp_ok($calls,   '==', 20,      'Right number of calls');
    cmp_ok($max_end, '==', $max_id, 'Final chunk ends at max_id');
};

############################################################

done_testing;
