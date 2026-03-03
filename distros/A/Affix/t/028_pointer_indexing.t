use v5.40;
use lib 'lib', 'blib/arch', 'blib/lib';
use blib;
use Affix               qw[:all];
use Test2::Tools::Affix qw[:all];
use Config;
#
subtest 'Objectification' => sub {
    my $ptr = malloc(32);
    isa_ok $ptr, ['Affix::Pointer'], 'malloc return is blessed';
    ok ref($ptr), 'malloc returns a reference';
    is ref($ptr), 'Affix::Pointer', 'malloc return ref type is Affix::Pointer';
    can_ok $ptr, [qw(address type element_type size count cast)], 'Pointer methods exist';
    ok $ptr->address > 0, 'address() works';
    is $ptr->type,         '*void', 'type() works for void*';
    is $ptr->element_type, 'void',  'element_type() works for void*';
};
subtest 'Indexing (Primitives)' => sub {
    my $ptr = calloc( 4, Int );
    diag "calloc pointer type: " . $ptr->type();
    diag "calloc pointer element_type: " . $ptr->element_type();
    isa_ok $ptr, ['Affix::Pointer'], 'calloc return is blessed';
    like $ptr->type,         qr/^\[4:(s?int(32)?)\]$/, 'type() works for Array[Int, 4]';
    like $ptr->element_type, qr/^(s?int(32)?)$/,       'element_type() works for Array[Int, 4]';
    is $ptr->count, 4, 'count() works for fixed array';

    # Test FETCH
    is $ptr->[0], 0, 'FETCH index 0';
    is $ptr->[3], 0, 'FETCH index 3';

    # Test STORE
    $ptr->[0] = 42;
    $ptr->[3] = 123;
    is $ptr->[0], 42,  'Read back index 0';
    is $ptr->[3], 123, 'Read back index 3';

    # Compatibility: $$ptr should still work (points to index 0 usually)
    # Wait, $$ptr for Array[T, N] currently returns an arrayref in Affix?
    # Let's check.
    is ref($$ptr), 'ARRAY', '$$ptr for Array returns an arrayref';
    is $$ptr->[0], 42,      'Value in arrayref matches';
};
subtest 'Indexing (Void*)' => sub {
    my $ptr = malloc(8);

    #decided byte-indexed for void*
    is $ptr->count, 8, 'count() for void* pin returns size';
    $ptr->[0] = 65;    # 'A'
    $ptr->[1] = 66;    # 'B'
    is $ptr->[0], 65, 'Read byte 0';
    is $ptr->[1], 66, 'Read byte 1';

    # Compatibility: $$ptr for void* pin returns address
    ok $$ptr == $ptr->address, '$$ptr for void* returns address';
};
subtest 'Compatibility' => sub {

    # Existing code uses $$ptr
    my $int_p = cast( malloc(4), Pointer [Int] );
    $$int_p = 12345;
    is $$int_p, 12345, '$$ptr still works for simple pointers';

    # $int_p->[0] should now FAIL because it's not an array or void*
    my $ok  = eval { my $val = $int_p->[0]; 1 };
    my $err = $@;
    ok !$ok, '$ptr->[0] fails for non-array pointers';
    like $err, qr/Cannot index into non-aggregate type/, 'Error message matches';

    # But it works for void*
    my $v_p = malloc(4);
    $v_p->[0] = 42;
    is $v_p->[0], 42, '$ptr->[0] works for Pointer[Void] (byte-indexed)';
};
done_testing;
