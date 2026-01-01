#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl

use strict;
use warnings;
use Test::More tests => 7;
use Bit::Set::OO;
use Bit::Set::DB::OO;
use FFI::Platypus::Buffer;    # added to facilitate buffer management

# Test constants
use constant SIZE_OF_TEST_BIT => 131072;
use constant SIZEOF_BITDB     => 45;

# Basic operations tests
subtest 'Basic Operations (OO)' => sub {

    # test_bit_new
    my $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    ok( defined $bitset, 'Bit_new creates bitset' );
    undef $bitset;

    # test_bit_set
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bitset->bset(2);
    is( $bitset->get(2), 1, 'Bit_bset sets bit correctly' );
    undef $bitset;

    # test_bit_clear
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bitset->bset(2);
    $bitset->bclear(2);
    is( $bitset->get(2), 0, 'Bit_bclear clears bit correctly' );
    undef $bitset;

    # test_bit_put
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    my $prev = $bitset->put( 3, 1 );
    is( $prev,           0, 'Bit_put returns previous value (0)' );
    is( $bitset->get(3), 1, 'Bit_put sets bit correctly' );

    $prev = $bitset->put( 3, 0 );
    is( $prev,           1, 'Bit_put returns previous value (1)' );
    is( $bitset->get(3), 0, 'Bit_put clears bit correctly' );
    undef $bitset;

    # test_bit_set_range
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bitset->set( 2, SIZE_OF_TEST_BIT / 2 );
    my $all_set = 1;
    for my $index ( 2 .. SIZE_OF_TEST_BIT / 2 ) {
        $all_set &&= ( $bitset->get($index) == 1 );
    }
    ok( $all_set, 'Bit_set sets range correctly' );
    undef $bitset;

    # test_bit_clear_range
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    for my $i ( 0 .. SIZE_OF_TEST_BIT / 2 - 1 ) {
        $bitset->bset($i);
    }

    $bitset->clear( 2, 5 );
    my $cleared_correctly =
      (      $bitset->get(2) == 0
          && $bitset->get(3) == 0
          && $bitset->get(4) == 0
          && $bitset->get(5) == 0
          && $bitset->get(1) == 1 );
    for my $index ( 6 .. SIZE_OF_TEST_BIT / 2 - 1 ) {
        $cleared_correctly &&= ( $bitset->get($index) == 1 );
    }
    ok( $cleared_correctly, 'Bit_clear clears range correctly' );
    undef $bitset;

    # test aset
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    my @indices = ( 1, 3, 5, 7, 9 );
    $bitset->aset( \@indices );
    my $aset_success = 1;
    for my $i ( 0 .. $#indices ) {
        $aset_success &&= ( $bitset->get( $indices[$i] ) == 1 );
        warn "Bit at index $indices[$i] is not set"
          unless ( $bitset->get( $indices[$i] ) == 1 );
    }
    ok( $aset_success, 'Bit_aset sets multiple bits correctly' );
    undef $bitset;
    undef @indices;

    # handle large bit arrays (tests the memory allocation logic)
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    @indices = 0..(3 * SIZE_OF_TEST_BIT / 4);  #65536 is the limit we switch to heap allocation
    $bitset->aset( \@indices );
    my $large_aset_success = 1;
    for my $i ( 0 .. $#indices ) {
        $large_aset_success &&= ( $bitset->get( $indices[$i] ) == 1 );
        warn "Bit at index $indices[$i] is not set"
          unless ( $bitset->get( $indices[$i] ) == 1 );
    }
    ok( $large_aset_success, 'Bit_aset sets large number of bits correctly' );
    undef $bitset;
    undef @indices;

    #test aclear
    $bitset  = Bit::Set->new(SIZE_OF_TEST_BIT);
    @indices = ( 2, 4, 6, 8, 10 );
    $bitset->aset( \@indices );      # First set the bits
    $bitset->aclear( \@indices );    # Now clear them
    my $aclear_success = 1;
    for my $i ( 0 .. $#indices ) {
        $aclear_success &&= ( $bitset->get( $indices[$i] ) == 0 );
        warn "Bit at index $indices[$i] is not cleared"
          unless ( $bitset->get( $indices[$i] ) == 0 );
    }
    ok( $aclear_success, 'Bit_aclear clears multiple bits correctly' );

    # test_bit_count
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bitset->bset(1);
    $bitset->bset(3);
    $bitset->bset( SIZE_OF_TEST_BIT / 2 );

    my $count = $bitset->count();
    is( $count, 3, 'Bit_count returns correct count' );
    undef $bitset;
};

subtest 'Extract and Load Operations (OO)' => sub {

    # test_bit_extract
    my $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bitset->bset(2);
    $bitset->bset(0);

    my $buffer_size = Bit::Set->buffer_size(SIZE_OF_TEST_BIT);
    my $scalar =
      "\0" x $buffer_size;    # LLM returned: $buffer = "\0" x $buffer_size;

    #    my ( $buffer, $size ) =
    #      scalar_to_buffer $scalar;    # added to facilitate buffer management
    my $bytes =
      $bitset->extract($scalar);    # added to facilitate buffer management

    my $first_byte = unpack( 'C', substr( $scalar, 0, 1 ) )
      ;    # LLM returned: unpack('C', substr($buffer, 0, 1))
    is( $first_byte, 0b00000101, 'Bit_extract produces correct buffer' );
    undef $bitset;

    # test_bit_load
    $scalar =
      "\0" x $buffer_size;    # LLM returned: $buffer = "\0" x $buffer_size;

    #    ( $buffer, $size ) =
    #      scalar_to_buffer $scalar;    # added to facilitate buffer management

    substr( $scalar, 0, 1 ) = pack( 'C', 0b00000101 )
      ;    # LLM returned: substr($buffer, 0, 1) = pack('C', 0b00000101);
    $bitset = Bit::Set->load( SIZE_OF_TEST_BIT, $scalar );

    my $load_success =
      ( $bitset->get(0) == 1 && $bitset->get(2) == 1 );
    ok( $load_success, 'Bit_load creates bitset from buffer correctly' );
    undef $bitset;
};

subtest 'Comparison Operations (OO)' => sub {

    # test_bit_eq
    my $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);

    $bit1->bset(1);
    $bit1->bset(3);
    $bit2->bset(1);
    $bit2->bset(3);

    ok( $bit1->eq($bit2), 'Bit_eq returns true for equal bitsets' );

    $bit2->bset(8);
    ok( !$bit1->eq($bit2), 'Bit_eq returns false for unequal bitsets' );

    $bit2->bclear(8);
    $bit2->bset(75);
    ok( !$bit1->eq($bit2),
        'Bit_eq returns false for different unequal bitsets' );

    undef $bit1;
    undef $bit2;

    # test_bit_leq
    $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);

    $bit1->bset(1);
    $bit1->bset(3);

    $bit2->bset(1);
    $bit2->bset(3);
    $bit2->bset(5);

    my $leq_success = $bit1->leq($bit2) && !$bit2->leq($bit1);
    ok( $leq_success, 'Bit_leq works correctly' );

    undef $bit1;
    undef $bit2;

    # test_bit_lt
    $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);

    $bit1->bset(1);
    $bit1->bset(3);

    $bit2->bset(1);
    $bit2->bset(3);
    $bit2->bset(5);

    my $lt_success = $bit1->lt($bit2) && !$bit2->lt($bit1);
    ok( $lt_success, 'Bit_lt works correctly' );

    undef $bit1;
    undef $bit2;
};

subtest 'Set Operations (OO)' => sub {

    # test_bit_union
    my $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bit1->bset(1);
    $bit1->bset(3);

    $bit2->bset(3);
    $bit2->bset(5);

    my $union_bit = $bit1->union($bit2);

    my $union_success =
      (      $union_bit->get(1) == 1
          && $union_bit->get(3) == 1
          && $union_bit->get(5) == 1
          && $union_bit->get(0) == 0
          && $union_bit->get(2) == 0
          && $union_bit->get(4) == 0 );

    ok( $union_success, 'Bit_union works correctly' );

    undef $bit1;
    undef $bit2;
    undef $union_bit;

    # test_bit_inter
    $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);

    $bit1->bset(1);
    $bit1->bset(3);
    $bit1->bset(5);
    $bit2->bset(3);
    $bit2->bset(5);
    $bit2->bset(7);

    my $inter_bit = $bit1->inter($bit2);

    my $inter_success =
      (      $inter_bit->get(3) == 1
          && $inter_bit->get(5) == 1
          && $inter_bit->get(1) == 0
          && $inter_bit->get(7) == 0 );

    ok( $inter_success, 'Bit_inter works correctly' );

    undef $bit1;
    undef $bit2;
    undef $inter_bit;

    # test_bit_minus
    $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);

    $bit1->bset(1);
    $bit1->bset(3);
    $bit1->bset(5);

    $bit2->bset(3);
    $bit2->bset(5);
    $bit2->bset(7);
    my $minus_bit = $bit1->minus($bit2);

    my $minus_success =
      (      $minus_bit->get(1) == 1
          && $minus_bit->get(3) == 0
          && $minus_bit->get(5) == 0
          && $minus_bit->get(7) == 0 );

    ok( $minus_success, 'Bit_minus works correctly' );

    undef $bit1;
    undef $bit2;
    undef $minus_bit;

    # test_bit_diff
    $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);

    $bit1->bset(1);
    $bit1->bset(3);
    $bit1->bset(5);
    $bit2->bset(3);
    $bit2->bset(5);
    $bit2->bset(7);

    my $diff_bit = $bit1->diff($bit2);

    my $diff_success =
      (      $diff_bit->get(1) == 1
          && $diff_bit->get(7) == 1
          && $diff_bit->get(3) == 0
          && $diff_bit->get(5) == 0 );

    ok( $diff_success, 'Bit_diff works correctly' );

    undef $bit1;
    undef $bit2;
    undef $diff_bit;
};

subtest 'Count Operations (OO)' => sub {
    my $bit1 = Bit::Set->new(SIZE_OF_TEST_BIT);
    my $bit2 = Bit::Set->new(SIZE_OF_TEST_BIT);

    $bit1->bset(1);
    $bit1->bset(3);
    $bit1->bset(5);
    $bit2->bset(3);
    $bit2->bset(5);
    $bit2->bset(7);

    # Set extra bits to test final bits
    my $num_of_final_bits = SIZE_OF_TEST_BIT - 8;
    for my $i ( 8 .. SIZE_OF_TEST_BIT - 1 ) {
        $bit1->bset($i);
        $bit2->bset($i);
    }

    my $union_count = $bit1->union_count($bit2);
    my $inter_count = $bit1->inter_count($bit2);
    my $minus_count = $bit1->minus_count($bit2);
    my $diff_count  = $bit1->diff_count($bit2);

    my $count_success =
      (      $union_count == 4 + $num_of_final_bits
          && $inter_count == 2 + $num_of_final_bits
          && $minus_count == 1
          && $diff_count == 2 );

    ok( $count_success, 'All count operations work correctly' );

    undef $bit1;
    undef $bit2;
};

subtest 'BitDB Operations (OO)' => sub {

    # test_bitDB_new
    my $bitdb = Bit::Set::DB->new( SIZE_OF_TEST_BIT, 10 );
    ok( defined $bitdb, 'BitDB_new creates bitset database' );

    # test_bitDB_properties
    my $props_success =
      ( $bitdb->length == SIZE_OF_TEST_BIT && $bitdb->nelem == 10 );
    ok( $props_success, 'BitDB properties are correct' );

    undef $bitdb;

    # test_bitDB_get_put
    $bitdb = Bit::Set::DB->new( SIZE_OF_TEST_BIT, 10 );
    my $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bitset->bset(1);
    $bitset->bset(3);

    $bitdb->put_at( 0, $bitset );
    my $retrieved = $bitdb->get_from(0);
    my $get_put_success =
      ( $retrieved->get(1) == 1 && $retrieved->get(3) == 1 );
    ok( $get_put_success, 'BitDB get/put operations work correctly' );

    undef $bitset;
    undef $retrieved;

    # test_bitDB_extract_replace
    $bitset = Bit::Set->new(SIZE_OF_TEST_BIT);
    $bitset->bset(1);
    $bitset->bset(3);

    $bitdb->put_at( 0, $bitset );

    # LLM returned: my $buffer        = "\0" x ( SIZE_OF_TEST_BIT / 8 );
    # Following 3 lines added to create a buffer using API calls
    my $buffer_size = Bit::Set->buffer_size(SIZE_OF_TEST_BIT);
    my $scalar      = "\0" x $buffer_size;
    my ( $buffer, $size ) = scalar_to_buffer $scalar;

    my $bytes_written = $bitdb->extract_from( 0, $buffer );

    # LLM returned: my $first_byte      = unpack( 'C', substr( $buffer, 0, 1 )
    # );
    my $first_byte      = unpack( 'C', substr( $scalar, 0, 1 ) );
    my $extract_success = ( $bytes_written == SIZE_OF_TEST_BIT / 8
          && $first_byte == ( ( 1 << 1 ) | ( 1 << 3 ) ) );

    $bitdb->replace_at( 0, $buffer );

    $retrieved = $bitdb->get_from(0);

    my $replace_success =
      ( $retrieved->get(1) == 1 && $retrieved->get(3) == 1 );

    ok( $extract_success && $replace_success,
        'BitDB extract/replace operations work correctly' );

    undef $bitset;
    undef $retrieved;
    undef $bitdb;
};

subtest 'BitDB Examples 1+2 (OO)' => sub {
    my $size            = 1024;
    my $num_of_bits     = 3;
    my $num_of_ref_bits = 5;

    my @bits;
    my @bitsets;

    # Initializing and setting the values of the bitsets
    for my $i ( 0 .. $num_of_bits - 1 ) {
        $bits[$i] = Bit::Set->new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
        $bits[$i]->set( int( $size / 2 ), $end );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $bitsets[$i] = Bit::Set->new($size);
        my $end = int( $size / 2 ) + $i;
        $end = ( $end > $size - 1 ) ? $size - 1 : $end;
        $bitsets[$i]->set( int( $size / 2 ), $end );
    }
    $bits[0]->set( int( $size / 2 ) - 1, int( $size / 2 ) + 5 );
    $bitsets[0]->set( int( $size / 2 ), int( $size / 2 ) + 5 );

    # Create BitDB containers
    my $db1 = Bit::Set::DB->new( $size, $num_of_bits );
    my $db2 = Bit::Set::DB->new( $size, $num_of_ref_bits );

    # Now put the bitsets into the containers
    for my $i ( 0 .. $num_of_bits - 1 ) {
        $db1->put_at( $i, $bits[$i] );
    }
    for my $i ( 0 .. $num_of_ref_bits - 1 ) {
        $db2->put_at( $i, $bitsets[$i] );
    }
    ok( defined $db1 && defined $db2, 'BitDB containers created' );

    use Test::More;
    use FFI::Platypus::Buffer;
    use FFI::Platypus::Memory;
    use Config;    # to get the size of int

    my $num_threads = 4;
    my $opts        = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        num_cpu_threads     => $num_threads,
        device_id           => 0,
        upd_1st_operand     => 0,
        upd_2nd_operand     => 0,
        release_1st_operand => 0,
        release_2nd_operand => 0,
        release_counts      => 0
    );
    my $nelem = $db1->nelem() * $db2->nelem();

    # Method 1: Using Perl arrays of Bit::Set
    my @cpu_set_counts;
    for my $i ( 0 .. $num_of_bits - 1 ) {
        for my $j ( 0 .. $num_of_ref_bits - 1 ) {
            my $count = $bits[$i]->inter_count( $bitsets[$j] );
            push @cpu_set_counts, $count;
        }
    }

    # Method 2: Using Bit::Set::DB containers
    my $cpu_DB_counts_ptr = $db1->inter_count_cpu( $db2, $opts );

    my $scalar = buffer_to_scalar $cpu_DB_counts_ptr, $nelem * $Config{intsize};
    my @cpu_DB_counts = unpack( "i[$nelem]", $scalar );
    free $cpu_DB_counts_ptr;
    my $test_result = 1;
    for my $k ( 0 .. $nelem - 1 ) {
        if ( $cpu_DB_counts[$k] != $cpu_set_counts[$k] ) {
            $test_result = 0;
            last;
        }
    }
    ok( $test_result, "BitDB CPU intersection counts match Bit::Set counts" );
};

# Note: Skipping the BitDB intersection count test as it requires the SETOP_COUNT_OPTS
# structure to be properly initialized and the count operations may need additional setup

done_testing();
