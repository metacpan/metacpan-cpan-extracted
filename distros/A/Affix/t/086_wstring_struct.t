use v5.40;
use utf8;
use blib;
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Affix qw[:all];
use Config;

# wchar_t is 2 bytes (UTF-16) on Windows and 4 bytes (UTF-32) on most Unices.
my $wchar_sz = sizeof(WChar);    #$Config{wcharsize} // ( $^O eq 'MSWin32' ? 2 : 4 );
#
my $lib = compile_ok(<<~'');
    #include "std.h"
    //ext: .c
    typedef struct {
        wchar_t * name;
    } Person;
    static Person g_person = { 0 };
    DLLEXPORT void *        get_person()     { return &g_person; }
    DLLEXPORT int           stored_is_null() { return g_person.name == NULL; }
    DLLEXPORT unsigned int  stored_units()   { return g_person.name ? (unsigned int)wcslen( g_person.name ) : 0; }
    DLLEXPORT unsigned int  stored_unit( unsigned int i ) { return (unsigned int)g_person.name[i]; }
    DLLEXPORT void          set_fixed_name() { g_person.name = L"world"; }
    DLLEXPORT int           wlen_arg( const wchar_t * s ) { return s ? (int)wcslen( s ) : -1; }
    DLLEXPORT const wchar_t * wide_ret() { return L"hello"; }

typedef Person => Struct [ name => WString ];
#
affix $lib, 'get_person',     []        => Pointer [ Person() ];
affix $lib, 'stored_is_null', []        => Int32;
affix $lib, 'stored_units',   []        => UInt32;
affix $lib, 'stored_unit',    [UInt32]  => UInt32;
affix $lib, 'set_fixed_name', []        => Void;
affix $lib, 'wlen_arg',       [WString] => Int32;
affix $lib, 'wide_ret',       []        => WString;
#
my $live = cast( get_person(), Struct [ name => WString ] );
#
subtest 'WString field assignment stores a wide string' => sub {
    $live->{name} = "héllo";
    ok no_warnings {
        ok !stored_is_null(), 'C pointer is set';
        is stored_units(), 5,       'five wchar units stored';
        is stored_unit(1), 0xE9,    'second unit is U+00E9 (é)';
        is $live->{name},  "héllo", 'field reads back as a Perl string';
    }, 'assignment produces no warning';
};
subtest 'astral characters become surrogate pairs in UTF-16' => sub {
    my $s = "𝄞";    # U+1D11E
    $live->{name} = $s;
    if ( $wchar_sz == 2 ) {
        is stored_units(), 2,      'two UTF-16 units (high + low surrogate)';
        is stored_unit(0), 0xD834, 'high surrogate';
        is stored_unit(1), 0xDD1E, 'low surrogate';
    }
    else {
        is stored_units(), 1,       'one UTF-32 unit';
        is stored_unit(0), 0x1D11E, 'unit is U+1D11E';
    }
    is $live->{name}, $s, 'field roundtrips';
};
subtest 'empty string and undef' => sub {
    $live->{name} = '';
    is stored_units(), 0,  'empty wide string stored';
    is $live->{name},  '', 'reads back empty';
    $live->{name} = undef;
    ok stored_is_null(),       'undef clears the pointer';
    ok !defined $live->{name}, 'reads back undef';
};
subtest 'read a C-owned wide string' => sub {
    set_fixed_name();
    is $live->{name}, "world", 'reads a C literal';
};
subtest 'deep copy of a struct with a WString field' => sub {
    my $copy = $live;
    $copy->{name} = 'deep';
    is $copy->{name}, 'deep', 'deep copy stores and reads back';
};
subtest 'WString as a direct argument' => sub {
    is wlen_arg('hello'),  5, 'wide string argument roundtrips';
    is wlen_arg('héllo'),  5, 'non-ASCII argument roundtrips';
    is wlen_arg(undef),   -1, 'undef becomes a null pointer';
};
subtest 'WString as a return value' => sub {
SKIP: {
        skip 'WString returns resolve to a pin on non-Windows (wchar_t is 4 bytes)', 1 unless $^O eq 'MSWin32';
        is wide_ret(), 'hello', 'wide string return roundtrips';
    }
};
#
done_testing;
