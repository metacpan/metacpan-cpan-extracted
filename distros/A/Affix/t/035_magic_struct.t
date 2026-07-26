use v5.40;
use Test2::V0;
use blib;
use Affix qw[:all];

# Define our structure
typedef Point => Struct [ x => Int, y => Int ];
typedef Transform => Struct [ origin => Point(), scale => Float ];
#
subtest 'Direct memory write-back' => sub {

    # Allocate raw memory
    my $ptr = Affix::malloc( sizeof( Point() ) );

    # Initialize memory to zeros manually
    memset( $ptr, 0, sizeof( Point() ) );

    # BIND the hash to the pointer (The new system)
    my $struct = cast $ptr, Point();

    # ACT: Modify the hash
    $struct->{x} = 123;
    $struct->{y} = 456;

    # ASSERT: Read raw memory back using cast (bypassing the hash magic)
    my $raw_x = cast $ptr, Int;
    my $raw_y = cast ptr_add( $ptr, 4 ), Int;    # offset of 'y' is 4
    is $raw_x, 123, 'C memory for x updated immediately';
    is $raw_y, 456, 'C memory for y updated immediately';
};
subtest 'Reference counting and persistence' => sub {
    my $sub_hash;
    {
        my $root_ptr = Affix::malloc( sizeof( Transform() ) );
        my $tx       = cast $root_ptr, Transform();

        # Grab a reference to a nested struct
        $sub_hash = $tx->{origin};
    }

    # Attempt to write to the sub-hash after parent is technically "gone"
    $sub_hash->{y} = 77;

    # If we are here and haven't crashed, success.
    # We can verify by re-pinning a pointer to see if the value is there.
    is $sub_hash->{y}, 77, 'Sub-struct remains valid and writable after parent scope ends';
};
subtest 'Magical Array Indexing (Primitives)' => sub {

    # Allocate memory for 5 integers
    my $ptr = Affix::malloc( sizeof( Array [ Int, 5 ] ) );
    memset( $ptr, 0, sizeof( Array [ Int, 5 ] ) );

    # Cast to Pointer[Int] so Affix knows the element size
    $ptr = cast( $ptr, Array [ Int, 5 ] );

    # ACT: Write to various indices
    $ptr->[0] = 10;
    $ptr->[4] = 50;

    # ASSERT: Check raw memory via pointer arithmetic to confirm direct write
    is cast( $ptr,                             Int ), 10, 'Index 0 wrote to base address';
    is cast( ptr_add( $ptr, sizeof(Int) * 4 ), Int ), 50, 'Index 4 wrote to correct offset';

    # ASSERT: Read back via indexing
    is $ptr->[0], 10, 'Read back index 0';
    is $ptr->[4], 50, 'Read back index 4';
};
subtest 'Magical Array Indexing (Nested Structs)' => sub {

    # Allocate memory for 2 Points
    my $ptr = Affix::malloc( sizeof( Array [ Point(), 2 ] ) );
    memset( $ptr, 0, sizeof( Array [ Point(), 2 ] ) );
    $ptr = cast( $ptr, Array [ Point(), 2 ] );

    # ACT: Access second point and modify field
    # This combines the Magical Array FETCH and Magical Hash BIND
    $ptr->[1]{y} = 99;

    # ASSERT: Verify offset calculation
    # Point 0: 8 bytes, Point 1: starts at +8. 'y' is at +4. Total offset = 12.
    my $raw_val = cast( ptr_add( $ptr, 12 ), Int );
    is $raw_val,     99, 'Direct write through index and hash field worked';
    is $ptr->[1]{y}, 99, 'Lazy read back through index and hash worked';
};
subtest 'Array Element Longevity' => sub {
    my $element_ref;
    {
        my $root = Affix::malloc( sizeof(Int) * 10 );
        $root = cast( $root, Array [Int] );
        $root->[5] = 12345;

        # Take a reference to a specific element's magical SV
        $element_ref = \( $root->[5] );

        # $root goes out of scope here.
        # In the new system, $element_ref's magic keeps the root alive.
    }

    # ASSERT: We can still read and write to the element
    is $$element_ref, 12345, 'Magical element SV kept root memory alive';
    $$element_ref = 54321;
    is $$element_ref, 54321, 'Magical element SV still writable after root object scope ended';
};
subtest 'Out of bounds (C-style)' => sub {

    # In C, pointers don't have bounds. Our magical system should behave like C.
    # To prevent ACTUAL heap corruption (which crashes the Perl allocator
    # during global destruction), we allocate enough backing memory here.
    my $ptr = Affix::malloc( 15 * sizeof(Int) );
    $ptr = cast( $ptr, Pointer [Int] );

    # This is "dangerous" but should work without a Perl exception
    # because it's just pointer arithmetic.
    #~ ok lives { $ptr->[10] = 0 }, 'Accessing out-of-bounds index does not throw Perl exception';
    # Since pointers have no bounds and we avoid `tie`, pointer arithmetic
    # is done explicitly via ptr_add.
    my $p10 = ptr_add( $ptr, 10 * sizeof(Int) );
    ok lives { $$p10 = 0 }, 'Accessing out-of-bounds memory via ptr_add does not throw Perl exception';
};
#
done_testing;
