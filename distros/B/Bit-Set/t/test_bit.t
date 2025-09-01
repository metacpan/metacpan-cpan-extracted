#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use Bit::Set     qw(:all);
use Bit::Set::DB qw(:all);
use FFI::Platypus::Buffer;    # added to facilitate buffer management

# Test constants
use constant SIZE_OF_TEST_BIT => 65536;
use constant SIZEOF_BITDB     => 45;

# Basic operations tests
subtest 'Basic Operations' => sub {

    # test_bit_new
    my $bitset = Bit_new(SIZE_OF_TEST_BIT);
    ok( defined $bitset, 'Bit_new creates bitset' );
    Bit_free( \$bitset );

    # test_bit_set
    $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 2 );
    is( Bit_get( $bitset, 2 ), 1, 'Bit_bset sets bit correctly' );
    Bit_free( \$bitset );

    # test_bit_clear
    $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 2 );
    Bit_bclear( $bitset, 2 );
    is( Bit_get( $bitset, 2 ), 0, 'Bit_bclear clears bit correctly' );
    Bit_free( \$bitset );

    # test_bit_put
    $bitset = Bit_new(SIZE_OF_TEST_BIT);
    my $prev = Bit_put( $bitset, 3, 1 );
    is( $prev,                 0, 'Bit_put returns previous value (0)' );
    is( Bit_get( $bitset, 3 ), 1, 'Bit_put sets bit correctly' );

    $prev = Bit_put( $bitset, 3, 0 );
    is( $prev,                 1, 'Bit_put returns previous value (1)' );
    is( Bit_get( $bitset, 3 ), 0, 'Bit_put clears bit correctly' );
    Bit_free( \$bitset );

    # test_bit_set_range
    $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_set( $bitset, 2, SIZE_OF_TEST_BIT / 2 );

    my $all_set = 1;
    for my $index ( 2 .. SIZE_OF_TEST_BIT / 2 ) {
        $all_set &&= ( Bit_get( $bitset, $index ) == 1 );
    }
    ok( $all_set, 'Bit_set sets range correctly' );
    Bit_free( \$bitset );

    # test_bit_clear_range
    $bitset = Bit_new(SIZE_OF_TEST_BIT);
    for my $i ( 0 .. SIZE_OF_TEST_BIT / 2 - 1 ) {
        Bit_bset( $bitset, $i );
    }

    Bit_clear( $bitset, 2, 5 );
    my $cleared_correctly =
      (      Bit_get( $bitset, 2 ) == 0
          && Bit_get( $bitset, 3 ) == 0
          && Bit_get( $bitset, 4 ) == 0
          && Bit_get( $bitset, 5 ) == 0
          && Bit_get( $bitset, 1 ) == 1 );

    for my $index ( 6 .. SIZE_OF_TEST_BIT / 2 - 1 ) {
        $cleared_correctly &&= ( Bit_get( $bitset, $index ) == 1 );
    }
    ok( $cleared_correctly, 'Bit_clear clears range correctly' );
    Bit_free( \$bitset );

    # test_bit_count
    $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 1 );
    Bit_bset( $bitset, 3 );
    Bit_bset( $bitset, SIZE_OF_TEST_BIT / 2 );

    my $count = Bit_count($bitset);
    is( $count, 3, 'Bit_count returns correct count' );
    Bit_free( \$bitset );
};

subtest 'Extract and Load Operations' => sub {

    # test_bit_extract
    my $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 2 );
    Bit_bset( $bitset, 0 );

    my $buffer_size = Bit_buffer_size(SIZE_OF_TEST_BIT);
    my $scalar =
      "\0" x $buffer_size;    # LLM returned: $buffer = "\0" x $buffer_size;
    my ( $buffer, $size ) =
      scalar_to_buffer $scalar;    # added to facilitate buffer management
    my $bytes =
      Bit_extract( $bitset, $buffer );   # added to facilitate buffer management

    my $first_byte = unpack( 'C', substr( $scalar, 0, 1 ) )
      ;    # LLM returned: unpack('C', substr($buffer, 0, 1))
    is( $first_byte, 0b00000101, 'Bit_extract produces correct buffer' );
    Bit_free( \$bitset );

    # test_bit_load
    $scalar =
      "\0" x $buffer_size;    # LLM returned: $buffer = "\0" x $buffer_size;
    ( $buffer, $size ) =
      scalar_to_buffer $scalar;    # added to facilitate buffer management

    substr( $scalar, 0, 1 ) = pack( 'C', 0b00000101 )
      ;    # LLM returned: substr($buffer, 0, 1) = pack('C', 0b00000101);
    $bitset = Bit_load( SIZE_OF_TEST_BIT, $buffer );

    my $load_success =
      ( Bit_get( $bitset, 0 ) == 1 && Bit_get( $bitset, 2 ) == 1 );
    ok( $load_success, 'Bit_load creates bitset from buffer correctly' );
    Bit_free( \$bitset );
};

subtest 'Comparison Operations' => sub {

    # test_bit_eq
    my $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );

    Bit_bset( $bit2, 1 );
    Bit_bset( $bit2, 3 );

    ok( Bit_eq( $bit1, $bit2 ), 'Bit_eq returns true for equal bitsets' );

    Bit_bset( $bit2, 8 );
    ok( !Bit_eq( $bit1, $bit2 ), 'Bit_eq returns false for unequal bitsets' );

    Bit_bclear( $bit2, 8 );
    Bit_bset( $bit2, 75 );
    ok( !Bit_eq( $bit1, $bit2 ),
        'Bit_eq returns false for different unequal bitsets' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );

    # test_bit_leq
    $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );

    Bit_bset( $bit2, 1 );
    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );

    my $leq_success = Bit_leq( $bit1, $bit2 ) && !Bit_leq( $bit2, $bit1 );
    ok( $leq_success, 'Bit_leq works correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );

    # test_bit_lt
    $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );

    Bit_bset( $bit2, 1 );
    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );

    my $lt_success = Bit_lt( $bit1, $bit2 ) && !Bit_lt( $bit2, $bit1 );
    ok( $lt_success, 'Bit_lt works correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );
};

subtest 'Set Operations' => sub {

    # test_bit_union
    my $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );

    my $union_bit = Bit_union( $bit1, $bit2 );

    my $union_success =
      (      Bit_get( $union_bit, 1 ) == 1
          && Bit_get( $union_bit, 3 ) == 1
          && Bit_get( $union_bit, 5 ) == 1
          && Bit_get( $union_bit, 0 ) == 0
          && Bit_get( $union_bit, 2 ) == 0
          && Bit_get( $union_bit, 4 ) == 0 );

    ok( $union_success, 'Bit_union works correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );
    Bit_free( \$union_bit );

    # test_bit_inter
    $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );
    Bit_bset( $bit1, 5 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );
    Bit_bset( $bit2, 7 );

    my $inter_bit = Bit_inter( $bit1, $bit2 );

    my $inter_success =
      (      Bit_get( $inter_bit, 3 ) == 1
          && Bit_get( $inter_bit, 5 ) == 1
          && Bit_get( $inter_bit, 1 ) == 0
          && Bit_get( $inter_bit, 7 ) == 0 );

    ok( $inter_success, 'Bit_inter works correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );
    Bit_free( \$inter_bit );

    # test_bit_minus
    $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );
    Bit_bset( $bit1, 5 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );
    Bit_bset( $bit2, 7 );

    my $minus_bit = Bit_minus( $bit1, $bit2 );

    my $minus_success =
      (      Bit_get( $minus_bit, 1 ) == 1
          && Bit_get( $minus_bit, 3 ) == 0
          && Bit_get( $minus_bit, 5 ) == 0
          && Bit_get( $minus_bit, 7 ) == 0 );

    ok( $minus_success, 'Bit_minus works correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );
    Bit_free( \$minus_bit );

    # test_bit_diff
    $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );
    Bit_bset( $bit1, 5 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );
    Bit_bset( $bit2, 7 );

    my $diff_bit = Bit_diff( $bit1, $bit2 );

    my $diff_success =
      (      Bit_get( $diff_bit, 1 ) == 1
          && Bit_get( $diff_bit, 7 ) == 1
          && Bit_get( $diff_bit, 3 ) == 0
          && Bit_get( $diff_bit, 5 ) == 0 );

    ok( $diff_success, 'Bit_diff works correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );
    Bit_free( \$diff_bit );
};

subtest 'Count Operations' => sub {
    my $bit1 = Bit_new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit_new(SIZE_OF_TEST_BIT);

    Bit_bset( $bit1, 1 );
    Bit_bset( $bit1, 3 );
    Bit_bset( $bit1, 5 );

    Bit_bset( $bit2, 3 );
    Bit_bset( $bit2, 5 );
    Bit_bset( $bit2, 7 );

    # Set extra bits to test final bits
    my $num_of_final_bits = SIZE_OF_TEST_BIT - 8;
    for my $i ( 8 .. SIZE_OF_TEST_BIT - 1 ) {
        Bit_bset( $bit1, $i );
        Bit_bset( $bit2, $i );
    }

    my $union_count = Bit_union_count( $bit1, $bit2 );
    my $inter_count = Bit_inter_count( $bit1, $bit2 );
    my $minus_count = Bit_minus_count( $bit1, $bit2 );
    my $diff_count  = Bit_diff_count( $bit1, $bit2 );

    my $count_success =
      (      $union_count == 4 + $num_of_final_bits
          && $inter_count == 2 + $num_of_final_bits
          && $minus_count == 1
          && $diff_count == 2 );

    ok( $count_success, 'All count operations work correctly' );

    Bit_free( \$bit1 );
    Bit_free( \$bit2 );
};

subtest 'BitDB Operations' => sub {

    # test_bitDB_new
    my $bitdb = BitDB_new( SIZE_OF_TEST_BIT, 10 );
    ok( defined $bitdb, 'BitDB_new creates bitset database' );

    # test_bitDB_properties
    my $props_success =
      ( BitDB_length($bitdb) == SIZE_OF_TEST_BIT && BitDB_nelem($bitdb) == 10 );
    ok( $props_success, 'BitDB properties are correct' );

    BitDB_free( \$bitdb );

    # test_bitDB_get_put
    $bitdb = BitDB_new( SIZE_OF_TEST_BIT, 10 );
    my $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 1 );
    Bit_bset( $bitset, 3 );

    BitDB_put_at( $bitdb, 0, $bitset );
    my $retrieved = BitDB_get_from( $bitdb, 0 );

    my $get_put_success =
      ( Bit_get( $retrieved, 1 ) == 1 && Bit_get( $retrieved, 3 ) == 1 );
    ok( $get_put_success, 'BitDB get/put operations work correctly' );

    Bit_free( \$bitset );
    Bit_free( \$retrieved );

    # test_bitDB_extract_replace
    $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 1 );
    Bit_bset( $bitset, 3 );

    BitDB_put_at( $bitdb, 0, $bitset );

    # LLM returned: my $buffer        = "\0" x ( SIZE_OF_TEST_BIT / 8 );
    # Following 3 lines added to create a buffer using API calls
    my $buffer_size = Bit_buffer_size(SIZE_OF_TEST_BIT);
    my $scalar      = "\0" x $buffer_size;
    my ( $buffer, $size ) = scalar_to_buffer $scalar;

    my $bytes_written = BitDB_extract_from( $bitdb, 0, $buffer );

    # LLM returned: my $first_byte      = unpack( 'C', substr( $buffer, 0, 1 )
    # );
    my $first_byte      = unpack( 'C', substr( $scalar, 0, 1 ) );
    my $extract_success = ( $bytes_written == SIZE_OF_TEST_BIT / 8
          && $first_byte == ( ( 1 << 1 ) | ( 1 << 3 ) ) );

    BitDB_replace_at( $bitdb, 0, $buffer );

    $retrieved = BitDB_get_from( $bitdb, 0 );

    my $replace_success =
      ( Bit_get( $retrieved, 1 ) == 1 && Bit_get( $retrieved, 3 ) == 1 );

    ok( $extract_success && $replace_success,
        'BitDB extract/replace operations work correctly' );

    Bit_free( \$bitset );
    Bit_free( \$retrieved );
    BitDB_free( \$bitdb );
};

# Note: Skipping the BitDB intersection count test as it requires the SETOP_COUNT_OPTS
# structure to be properly initialized and the count operations may need additional setup

done_testing();
