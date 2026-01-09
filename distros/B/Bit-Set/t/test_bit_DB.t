#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl

use strict;
use warnings;
use Test::More tests => 7;
use Bit::Set      qw(:all);
use Bit::Set::DB qw(:all);
use FFI::Platypus::Buffer;    # added to facilitate buffer management
use FFI::Platypus::Memory qw( malloc memcpy free );    # for memory management

# Test constants
use constant SIZE_OF_TEST_BIT => 65536;
use constant SIZEOF_BITDB     => 10;

use Config;
my $ivsize = $Config{ivsize};

subtest 'Defining Options ' => sub {

    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        {
            num_cpu_threads     => 1,
            device_id           => 2,
            upd_1st_operand     => 0,
            upd_2nd_operand     => 0,
            release_1st_operand => 1,
            release_2nd_operand => 1,
            release_counts      => 1
        }
    );
    ok(
        $opts->device_id() == 2,
'SETOP_COUNT_OPTS created with correct device_id (initialized via hashref)'
    );
    $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        num_cpu_threads     => 1,
        device_id           => 3,
        upd_1st_operand     => 0,
        upd_2nd_operand     => 0,
        release_1st_operand => 1,
        release_2nd_operand => 1,
        release_counts      => 1

    );
    ok(
        $opts->device_id() == 3,
'SETOP_COUNT_OPTS created with correct device_id (initialized via hash)'
    );

};

subtest 'BitDB Operations' => sub {

    my $bitdb = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );
    ok( defined $bitdb, 'BitDB_new creates bitset database' );

    # test_bitDB_get_put
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

};
subtest 'BitDB Content Manipulation' => sub {
    my $bitdb = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );

    # test_bitDB_get_put
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

};
subtest 'BitDB Properties' => sub {

    my $bitdb = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );

    my $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 1 );
    Bit_bset( $bitset, 3 );
    my $bitset2 = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset2, 2 );
    BitDB_put_at( $bitdb, 0, $bitset );
    BitDB_put_at( $bitdb, 1, $bitset2 );

    # verify length
    my $length = BitDB_length($bitdb);
    ok( $length == SIZE_OF_TEST_BIT, 'BitDB_length returns correct length' );

    # verify nelem
    my $nelem = BitDB_nelem($bitdb);
    ok( $nelem == SIZEOF_BITDB, 'BitDB_nelem returns correct nelem' );

    # get counts via a single argument
    my $counts         = BitDB_count($bitdb);
    my $counts_success = ( $$counts[0] == 2 && $$counts[1] == 1 );
    $counts_success &&= ( $$counts[$_] == 0 ) for ( 3 .. SIZEOF_BITDB - 1 );
    ok( $counts_success,
        'BitDB count operation works correctly (no argument)' );

    # get counts via zero
    $counts         = BitDB_count( $bitdb, undef );
    $counts_success = ( $$counts[0] == 2 && $$counts[1] == 1 );
    $counts_success &&= ( $$counts[$_] == 0 ) for ( 3 .. SIZEOF_BITDB - 1 );
    ok( $counts_success, 'BitDB count operation works correctly (undef)' );

    # get counts via undef
    $counts         = BitDB_count( $bitdb, 0 );
    $counts_success = ( $$counts[0] == 2 && $$counts[1] == 1 );
    $counts_success &&= ( $$counts[$_] == 0 ) for ( 3 .. SIZEOF_BITDB - 1 );
    ok( $counts_success,
        'BitDB count operation works correctly (0 : Perl Array)' );

    # get counts via 1
    $counts = BitDB_count( $bitdb, 1 );

    # use pack to convert $counts to an array of integers (since it's a pointer)
    my $scalar       = buffer_to_scalar $counts, SIZEOF_BITDB * $ivsize;
    my @counts_array = unpack( "i[" . SIZEOF_BITDB . "]", $scalar );
    $counts_success = ( $counts_array[0] == 2 && $counts_array[1] == 1 );
    $counts_success &&= ( $counts_array[$_] == 0 )
      for ( 3 .. SIZEOF_BITDB - 1 );
    ok( $counts_success,
        'BitDB count operation works correctly (1 : Raw Buffer)' );

    # now use count_at
    my $count0 = BitDB_count_at( $bitdb, 0 );
    my $count1 = BitDB_count_at( $bitdb, 1 );
    $counts_success = ( $count0 == 2 && $count1 == 1 );
    $counts_success &&= ( BitDB_count_at( $bitdb, $_ ) == 0 )
      for ( 3 .. SIZEOF_BITDB - 1 );
    ok( $counts_success, 'BitDB count_at operation works correctly' );

    Bit_free( \$bitset );
    Bit_free( \$bitset2 );
    BitDB_free( \$bitdb );

};

subtest 'BitDB Further Content Manipulation' => sub {

    my $bitdb = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );

    my $bitset = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset, 1 );
    Bit_bset( $bitset, 3 );
    my $bitset2 = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset2, 2 );
    BitDB_put_at( $bitdb, 0, $bitset );
    BitDB_put_at( $bitdb, 1, $bitset2 );

    BitDB_clear_at( $bitdb, 0 );
    my $count0 = BitDB_count_at( $bitdb, 0 );
    ok( $count0 == 0, 'BitDB clear_at operation works correctly' );

    BitDB_clear($bitdb);
    my $counts         = BitDB_count($bitdb);
    my $counts_success = 1;
    $counts_success &&= ( $$counts[$_] == 0 ) for ( 0 .. SIZEOF_BITDB - 1 );
    ok( $counts_success, 'BitDB clear operation works correctly' );

};

subtest 'BitDB Binary Operations (CPU)' => sub {
    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        {
            num_cpu_threads     => 1,
            device_id           => 0,
            upd_1st_operand     => 0,
            upd_2nd_operand     => 0,
            release_1st_operand => 1,
            release_2nd_operand => 1,
            release_counts      => 1
        }
    );

    my $bitdb1        = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );
    my $bitdb2        = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );
    my $num_of_counts = SIZEOF_BITDB * SIZEOF_BITDB;

    # Fill both databases with bitsets
    my $bitset1 = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset1, 1 );
    Bit_bset( $bitset1, 3 );
    my $bitset2 = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset2, 1 );
    Bit_bset( $bitset2, 2 );
    for ( 0 .. SIZEOF_BITDB - 1 ) {
        BitDB_put_at( $bitdb1, $_, $bitset1 );
        BitDB_put_at( $bitdb2, $_, $bitset2 );
    }

    my %true_counts = (
        union => Bit_union_count( $bitset1, $bitset2 ),
        diff  => Bit_diff_count( $bitset1, $bitset2 ),
        inter => Bit_inter_count( $bitset1, $bitset2 ),
        minus => Bit_minus_count( $bitset1, $bitset2 ),
    );

    no strict 'refs';
    for my $op (qw/union inter diff minus/) {
        my $method          = "BitDB_${op}_count_cpu";
        my $expected_count  = 0;
        my $expected_count2 = 0;
        my $counts_ptr      = $method->( $bitdb1, $bitdb2, $opts );
        my $counts_ptr2     = $method->( $bitdb1, $bitdb2, $opts, 1 );
        map { $expected_count += $_ } $counts_ptr->@*;

        my $scalar = buffer_to_scalar $counts_ptr2, $num_of_counts * $ivsize;

        my @counts_array = unpack( "i[" . $num_of_counts . "]", $scalar );

        map { $expected_count2 += $_ } @counts_array;

        my $op_success =
          ( $expected_count == $true_counts{$op} * $num_of_counts );

        $op_success &&=
          ( $expected_count2 == $true_counts{$op} * $num_of_counts );

        ok( $op_success,
                "BitDB ${op}_count operation works correctly"
              . " $expected_count vs "
              . $true_counts{$op} * $num_of_counts );

    }
    use strict 'refs';

    BitDB_free( \$bitdb1 );
    BitDB_free( \$bitdb2 );
    Bit_free( \$bitset1 );
    Bit_free( \$bitset2 );
};

subtest 'BitDB Binary Operations (CPU,store)' => sub {
    my $opts = Bit::Set::DB::SETOP_COUNT_OPTS->new(
        {
            num_cpu_threads     => 1,
            device_id           => 0,
            upd_1st_operand     => 0,
            upd_2nd_operand     => 0,
            release_1st_operand => 1,
            release_2nd_operand => 1,
            release_counts      => 1
        }
    );

    my $bitdb1        = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );
    my $bitdb2        = BitDB_new( SIZE_OF_TEST_BIT, SIZEOF_BITDB );
    my $num_of_counts = SIZEOF_BITDB * SIZEOF_BITDB;

    # Fill both databases with bitsets
    my $bitset1 = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset1, 1 );
    Bit_bset( $bitset1, 3 );
    my $bitset2 = Bit_new(SIZE_OF_TEST_BIT);
    Bit_bset( $bitset2, 1 );
    Bit_bset( $bitset2, 2 );
    for ( 0 .. SIZEOF_BITDB - 1 ) {
        BitDB_put_at( $bitdb1, $_, $bitset1 );
        BitDB_put_at( $bitdb2, $_, $bitset2 );
    }

    my %true_counts = (
        union => Bit_union_count( $bitset1, $bitset2 ),
        diff  => Bit_diff_count( $bitset1, $bitset2 ),
        inter => Bit_inter_count( $bitset1, $bitset2 ),
        minus => Bit_minus_count( $bitset1, $bitset2 ),
    );

    my $counts_ptr = malloc $num_of_counts * $ivsize;
    no strict 'refs';
    for my $op (qw/union inter diff minus/) {
        my $method          = "BitDB_${op}_count_store_cpu";
        my $expected_count  = 0;
        my $expected_count2 = 0;

        $method->( $bitdb1, $bitdb2, $counts_ptr, $opts );
        map { $expected_count += $_ } $counts_ptr->@*;

        my $scalar = buffer_to_scalar $counts_ptr, $num_of_counts * $ivsize;

        my @counts_array = unpack( "i[" . $num_of_counts . "]", $scalar );

        map { $expected_count += $_ } @counts_array;

        my $op_success =
          ( $expected_count == $true_counts{$op} * $num_of_counts );

        ok( $op_success,
                "BitDB ${op}_count operation works correctly"
              . " $expected_count vs "
              . $true_counts{$op} * $num_of_counts );

    }
    use strict 'refs';
    free $counts_ptr;
    BitDB_free( \$bitdb1 );
    BitDB_free( \$bitdb2 );
    Bit_free( \$bitset1 );
    Bit_free( \$bitset2 );
};
done_testing();
