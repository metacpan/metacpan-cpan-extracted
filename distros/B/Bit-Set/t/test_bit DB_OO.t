#!/home/chrisarg/perl5/perlbrew/perls/current/bin/perl

use strict;
use warnings;
use Test::More tests => 2;
use Bit::Set::OO;
use Bit::Set::DB::OO;
use FFI::Platypus::Buffer;    # added to facilitate buffer management

# Test constants
use constant SIZE_OF_TEST_BIT => 131072;
use constant SIZEOF_BITDB     => 45;
use Config;
my $ivsize = $Config{ivsize};

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
    my $v = $buffer;
    $bitdb->extract_from( 0, $buffer );


    my $first_byte      = unpack( 'C', substr( $scalar, 0, 1 ) );
    my $extract_success = ( $first_byte == ( ( 1 << 1 ) | ( 1 << 3 ) ) );

    $bitdb->replace_at( 0, $buffer );

    $retrieved = $bitdb->get_from(0);

    my $replace_success =
      ( $retrieved->get(1) == 1 && $retrieved->get(3) == 1 );

    ok( $extract_success && $replace_success, 
        "BitDB extract/replace operations work correctly " . $bitset->count() ." \t$v\t$replace_success ".$retrieved->get(1). " | " . $first_byte );

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



    my $num_threads = 1;
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
    my $cpu_DB_counts = $db1->inter_count_cpu( $db2, $opts );
    my $test_result = 1;
    for my $k ( 0 .. $nelem - 1 ) {
        if ( $cpu_DB_counts->[$k] != $cpu_set_counts[$k] ) {
            $test_result = 0;
            last;
        }
    }
    ok( $test_result, "BitDB CPU intersection counts match Bit::Set counts" );

};

# Note: Skipping the BitDB intersection count test as it requires the SETOP_COUNT_OPTS
# structure to be properly initialized and the count operations may need additional setup

done_testing();
