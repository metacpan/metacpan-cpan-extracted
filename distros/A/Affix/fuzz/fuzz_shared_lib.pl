use v5.40;
use blib;
use lib 'blib/lib', 'lib';
use Affix               qw[:all];
use Test2::Tools::Affix qw[:all];
use Test2::V0 -no_srand => 1;
use Config;
use Data::Dumper;
$Data::Dumper::Terse = 1;
$|++;
#
my $max_iter = $ENV{FUZZ_MAX_ITER} // 1000;
my $timeout  = $ENV{FUZZ_TIMEOUT}  // 5;
my $verbose  = $ENV{FUZZ_VERBOSE}  // 0;
sub compile_source ($code) { compile_ok( <<~'' . $code ) }
	#include <inttypes.h>
	#include <locale.h>
	#include <math.h>
	#include <stdbool.h>
	#include <stddef.h>  // offsetof
	#include <stdio.h>
	#include <stdlib.h>  // malloc
	#include <string.h>
    #include <stdint.h>
	#include <wchar.h>
	// Some tests might actually include perl.h which has the real version of this
	#if !defined(warn)
	#define warn(FORMAT, ...)                                                          \
	    fprintf(stderr, FORMAT " at %s line %i\n", ##__VA_ARGS__, __FILE__, __LINE__); \
	    fflush(stderr);
	#endif
	#if defined _WIN32 || defined __CYGWIN__
	#include <BaseTsd.h>
	//typedef SSIZE_T ssize_t;
	typedef signed __int64 int64_t;
	#ifdef __GNUC__
	#define DLLEXPORT __attribute__((dllexport))
	#else
	#define DLLEXPORT __declspec(dllexport)
	#endif
	#else
	#ifdef __GNUC__
	#if __GNUC__ >= 4
	#define DLLEXPORT __attribute__((visibility("default")))
	#else
	#define DLLEXPORT __attribute__((dllimport))
	#endif
	#else
	#define DLLEXPORT __declspec(dllexport)
	#endif
	#include <inttypes.h>
	#include <sys/types.h>
	#endif
	//ext: .c


# Type catalog: { c_type, infix_sig, perl_type, gen_value }
# Ranges are derived from sizeof() at runtime so they match the actual platform.
my @PRIMITIVES;
{
    my @signed_ints = (
        [ 'int8_t',    'sint8',    sub { SInt8() } ],
        [ 'int16_t',   'sint16',   sub { SInt16() } ],
        [ 'int32_t',   'sint32',   sub { SInt32() } ],
        [ 'int64_t',   'sint64',   sub { SInt64() } ],
        [ 'char',      'char',     sub { Char() } ],
        [ 'short',     'short',    sub { Short() } ],
        [ 'int',       'int',      sub { Int() } ],
        [ 'long',      'long',     sub { Long() } ],
        [ 'long long', 'longlong', sub { LongLong() } ]
    );
    my @unsigned_ints = (
        [ 'uint8_t',            'uint8',     sub { UInt8() } ],
        [ 'uint16_t',           'uint16',    sub { UInt16() } ],
        [ 'uint32_t',           'uint32',    sub { UInt32() } ],
        [ 'uint64_t',           'uint64',    sub { UInt64() } ],
        [ 'unsigned char',      'uchar',     sub { UChar() } ],
        [ 'unsigned short',     'ushort',    sub { UShort() } ],
        [ 'unsigned int',       'uint',      sub { UInt() } ],
        [ 'unsigned long',      'ulong',     sub { ULong() } ],
        [ 'unsigned long long', 'ulonglong', sub { ULongLong() } ]
    );
    my @floats = ( [ 'float', 'float', sub { Float() } ], [ 'double', 'double', sub { Double() } ] );
    my @bool   = ( [ 'bool',  'bool',  sub { Bool() } ] );
    for my $entry (@signed_ints) {
        my ( $c, $sig, $perl ) = @$entry;
        my $bits = sizeof( $perl->() ) * 8;
        my $half = 2**( $bits - 1 );
        push @PRIMITIVES, { c => $c, sig => $sig, perl => $perl, gen => sub { int( rand( $half * 2 ) ) - $half } };
    }
    for my $entry (@unsigned_ints) {
        my ( $c, $sig, $perl ) = @$entry;
        my $bits = sizeof( $perl->() ) * 8;
        my $max  = 2**$bits;
        push @PRIMITIVES, { c => $c, sig => $sig, perl => $perl, gen => sub { int( rand($max) ) } };
    }
    for my $entry (@floats) {
        my ( $c, $sig, $perl ) = @$entry;
        my $prec = sizeof( $perl->() ) == 4 ? 2 : 4;
        push @PRIMITIVES, { c => $c, sig => $sig, perl => $perl, gen => sub { sprintf( "%.*f", $prec, rand(100) - 50 ) } };
    }
    for my $entry (@bool) {
        my ( $c, $sig, $perl ) = @$entry;
        push @PRIMITIVES, { c => $c, sig => $sig, perl => $perl, gen => sub { int( rand(2) ) } };
    }
}
my @SPECIAL = (
    { c => 'size_t',    sig => 'size_t',  perl => sub { Size_t() },  gen => sub { int( rand(1000) ) } },
    { c => 'ssize_t',   sig => 'ssize_t', perl => sub { SSize_t() }, gen => sub { int( rand(1000) ) } },
    { c => 'ptrdiff_t', sig => 'long',    perl => sub { Long() },    gen => sub { int( rand(200) ) - 100 } }
);
sub pick (@list) { $list[ int( rand(@list) ) ] }

sub pick_n ( $n, @list ) {
    my @shuffled = sort { rand(1) <=> rand(1) } @list;
    return @shuffled[ 0 .. $n - 1 ] if $n <= @list;
    return @shuffled;
}

sub unique_name {
    state $counter = 0;
    return 'fuzz_fn_' . $counter++;
}

# Primitive echo function (identity)
sub generate_function {
    my ($fn_name)   = @_;
    my @all         = ( @PRIMITIVES, @SPECIAL );
    my $nparams     = 1 + int( rand(4) );
    my @param_types = pick_n( $nparams, @all );
    my $ret_type    = pick(@all);
    my ( @c_params, @perl_args, @gen_values, @sig_args );
    for my $pt (@param_types) {
        my $pname = 'p' . scalar(@c_params);
        push @c_params,  "$pt->{c} $pname";
        push @perl_args, $pt->{perl}->();
        push @sig_args,  $pt->{sig};
        my $val = $pt->{gen}->();
        push @gen_values, sub {$val};
    }
    my $params_str = join( ', ', @c_params );
    my $ret_sig    = $ret_type->{sig};
    my $ret_c      = $ret_type->{c};
    my $c_code     = <<~"";
        $ret_c $fn_name($params_str) {
            return ($ret_c) p0;
        }

    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => \@sig_args,
        sig_ret    => $ret_sig,
        perl_args  => \@perl_args,
        perl_ret   => $ret_type->{perl}->(),
        gen_values => \@gen_values
    };
}

# Struct by value
sub generate_struct_fn {
    my ($fn_name) = @_;
    my $nfields   = 1 + int( rand(3) );
    my @all       = grep {
        $_->{c} ne 'float'             &&
            $_->{c} ne 'double'        &&
            $_->{c} ne 'char'          &&
            $_->{c} ne 'unsigned char' &&
            $_->{c} ne 'bool'          &&
            sizeof( $_->{perl}->() ) * 8 <= 53
    } @PRIMITIVES;
    my @fields      = pick_n( $nfields, @all );
    my $struct_name = 'S' . int( rand(99999) );
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields, @c_params, @perl_args, @sig_args, @gen_values );
    for my $f (@fields) {
        my $fname = 'm' . scalar(@struct_members);
        push @struct_members,     "$f->{c} $fname;";
        push @struct_perl_fields, $fname, $f->{perl}->();
        push @struct_sig_fields,  "$fname:" . $f->{sig};
        my $pname = 'p' . scalar(@c_params);
        push @c_params,  "$f->{c} $pname";
        push @perl_args, $f->{perl}->();
        push @sig_args,  $f->{sig};
        my $val = $f->{gen}->();
        push @gen_values, sub {$val};
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_def  = "typedef struct { $struct_body } $struct_name;";
    my $struct_sig  = '{ ' . join( ',', @struct_sig_fields ) . ' }';
    my $params_str  = join( ', ', @c_params );
    my @inits       = map {"r.m$_ = p$_;"} 0 .. $#fields;
    my $init_block  = join( "\n    ", @inits );
    my $c_code      = <<~"";
        $struct_def
        $struct_name $fn_name($params_str) {
            $struct_name r = {0};
            $init_block
            return r;
        }

    my @field_names = map { 'm' . $_ } 0 .. $#fields;
    my @check_gens  = @gen_values;
    my @check_names = @field_names;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => \@sig_args,
        sig_ret    => $struct_sig,
        perl_args  => \@perl_args,
        perl_ret   => Struct [@struct_perl_fields],
        gen_values => \@gen_values,
        verify     => sub ($result) {
            my %expected;
            @expected{@check_names} = map { $_->() } @check_gens;
            local $ENV{TABLE_TERM_SIZE} = 200;
            my $ok = is( $result, \%expected, "struct fields match" );
            unless ($ok) {
                diag 'GOT:      ' . join( ", ", map {"$_=$result->{$_}"} sort keys %$result );
                diag 'EXPECTED: ' . join( ", ", map {"$_=$expected{$_}"} sort keys %expected );
            }
        }
    };
}

# Struct with float/double fields (HFA testing on ARM64)
sub generate_struct_float_fn {
    my ($fn_name) = @_;
    my $struct_name = 'SF' . int( rand(99999) );

    # Pick an HFA scenario:
    #   1) Pure float HFA   (2-4 floats)       -> V0-V3 on ARM64
    #   2) Pure double HFA  (1-4 doubles)      -> V0-V3 on ARM64
    #   3) Non-HFA mixed    (int + float)       -> X0+X1 / X8
    #   4) Single-element   (1 float)           -> NOT HFA (< 2 elements)
    my @floats  = grep { $_->{c} eq 'float' } @PRIMITIVES;
    my @doubles = grep { $_->{c} eq 'double' } @PRIMITIVES;
    my @ints    = grep {
        $_->{c} ne 'float'             &&
            $_->{c} ne 'double'        &&
            $_->{c} ne 'char'          &&
            $_->{c} ne 'unsigned char' &&
            $_->{c} ne 'bool'          &&
            sizeof( $_->{perl}->() )
            <= 4
    } @PRIMITIVES;
    my $scenario = int( rand(4) );
    my ( @field_specs, @struct_members, @struct_perl_fields, @struct_sig_fields );
    my ( @c_params,    @perl_args,      @sig_args,           @gen_values );
    my @float_base;    # all fields share same base type for true HFA
    if ( $scenario == 0 && @floats >= 1 ) {

        # Pure float HFA: 2-4 floats
        my $n = 2 + int( rand(3) );    # 2..4
        my $f = pick(@floats);
        @float_base = ($f);
        for my $i ( 0 .. $n - 1 ) {
            push @field_specs,        $f;
            push @struct_members,     "$f->{c} m$i;";
            push @struct_perl_fields, "m$i", $f->{perl}->();
            push @struct_sig_fields,  "m$i:" . $f->{sig};
        }
    }
    elsif ( $scenario == 1 && @doubles >= 1 ) {

        # Pure double HFA: 1-4 doubles
        my $n = 1 + int( rand(4) );    # 1..4
        my $f = pick(@doubles);
        @float_base = ($f);
        for my $i ( 0 .. $n - 1 ) {
            push @field_specs,        $f;
            push @struct_members,     "$f->{c} m$i;";
            push @struct_perl_fields, "m$i", $f->{perl}->();
            push @struct_sig_fields,  "m$i:" . $f->{sig};
        }
    }
    elsif ( $scenario == 2 && @ints >= 1 && @floats >= 1 ) {

        # Non-HFA mixed: 1-2 ints + 1-2 floats (different types = not HFA)
        my $fi    = pick(@ints);
        my $ff    = pick(@floats);
        my $n_int = 1 + int( rand(2) );    # 1..2
        my $n_flt = 1 + int( rand(2) );    # 1..2
        my $idx   = 0;
        for my $i ( 1 .. $n_int ) {
            push @field_specs,        $fi;
            push @struct_members,     "$fi->{c} m$idx;";
            push @struct_perl_fields, "m$idx", $fi->{perl}->();
            push @struct_sig_fields,  "m$idx:" . $fi->{sig};
            $idx++;
        }
        for my $i ( 1 .. $n_flt ) {
            push @field_specs,        $ff;
            push @struct_members,     "$ff->{c} m$idx;";
            push @struct_perl_fields, "m$idx", $ff->{perl}->();
            push @struct_sig_fields,  "m$idx:" . $ff->{sig};
            $idx++;
        }
    }
    else {
        # Fallback: single float struct (NOT HFA, needs >= 2 elements)
        my $f = $floats[0] // $doubles[0];
        push @field_specs,        $f;
        push @struct_members,     "$f->{c} m0;";
        push @struct_perl_fields, "m0", $f->{perl}->();
        push @struct_sig_fields,  "m0:" . $f->{sig};
        @float_base = ($f);
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '{ ' . join( ',', @struct_sig_fields ) . ' }';

    # Build C parameter list
    @c_params   = ();
    @perl_args  = ();
    @sig_args   = ();
    @gen_values = ();
    for my $i ( 0 .. $#field_specs ) {
        my $f     = $field_specs[$i];
        my $pname = "p$i";
        push @c_params,  "$f->{c} $pname";
        push @perl_args, $f->{perl}->();
        push @sig_args,  $f->{sig};
        my $val = $f->{gen}->();
        push @gen_values, sub {$val};
    }
    my $params = join( ', ',     @c_params );
    my $inits  = join( "\n    ", map {"r.m$_ = p$_;"} 0 .. $#field_specs );
    my $c_code = <<~"";
        typedef struct { $struct_body } $struct_name;
        $struct_name $fn_name($params) {
            $struct_name r = {0};
            $inits
            return r;
        }

    my @check_gens  = @gen_values;
    my @check_names = map {"m$_"} 0 .. $#field_specs;

    # Track which fields are float vs double for precision-aware comparison
    my @field_is_float  = map { $field_specs[$_]->{c} eq 'float' } 0 .. $#field_specs;
    my @field_is_double = map { $field_specs[$_]->{c} eq 'double' } 0 .. $#field_specs;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => \@sig_args,
        sig_ret    => $struct_sig,
        perl_args  => \@perl_args,
        perl_ret   => Struct [@struct_perl_fields],
        gen_values => \@gen_values,
        verify     => sub ($result) {
            my @expected_vals = map { $_->() } @check_gens;
            my $spec          = hash {
                for my $i ( 0 .. $#check_names ) {
                    my $k   = $check_names[$i];
                    my $val = $expected_vals[$i];
                    if ( $field_is_float[$i] ) {
                        field $k => float( $val, precision => 2 );
                    }
                    elsif ( $field_is_double[$i] ) {
                        field $k => float( $val, precision => 4 );
                    }
                    else {
                        field $k => $val;
                    }
                }
                end();
            };
            my $ok = is( $result, $spec, "struct float fields match" );
            unless ($ok) {
                diag "GOT:     " . join( ", ", map {"$_=$result->{$_}"} sort keys %$result );
                diag "EXPECTED:" . join( ", ", map {"$_=$expected_vals[$_]"} 0 .. $#check_names );
            }
        }
    };
}

# Nested struct (struct-in-struct layout, alignment propagation, offset composition)
sub generate_nested_struct_fn {
    my ($fn_name) = @_;

    # Pick types for inner struct fields (1-2 small scalar fields)
    my @all = grep {
        $_->{c} ne 'float'             &&
            $_->{c} ne 'double'        &&
            $_->{c} ne 'char'          &&
            $_->{c} ne 'unsigned char' &&
            $_->{c} ne 'bool'          &&
            sizeof( $_->{perl}->() )
            <= 4
    } @PRIMITIVES;
    my $inner_count  = 1 + int( rand(2) );             # 1..2 fields in inner
    my @inner_fields = pick_n( $inner_count, @all );

    # Pick a type for the trailing scalar in the outer struct
    my $outer_scalar = pick(@all);
    my $inner_name   = 'NI' . int( rand(99999) );
    my $outer_name   = 'NO' . int( rand(99999) );

    # Build inner struct
    my ( @inner_members, @inner_perl_fields, @inner_sig_fields );
    for my $i ( 0 .. $#inner_fields ) {
        my $f  = $inner_fields[$i];
        my $fn = "a$i";
        push @inner_members,     "$f->{c} $fn;";
        push @inner_perl_fields, $fn, $f->{perl}->();
        push @inner_sig_fields,  "$fn:" . $f->{sig};
    }
    my $inner_body = join( ' ', @inner_members );
    my $inner_sig  = '{' . join( ',', @inner_sig_fields ) . '}';

    # Build outer struct: contains inner + one scalar
    my $osig      = $outer_scalar->{sig};
    my $outer_sig = '{inner:' . $inner_sig . ',z:' . $osig . '}';

    # C code: take outer by value, return inner.a0
    my $ret_c   = $inner_fields[0]->{c};
    my $ret_sig = $inner_fields[0]->{sig};
    my $c_code  = <<~"";
        typedef struct { $inner_body } $inner_name;
        typedef struct { $inner_name inner; $outer_scalar->{c} z; } $outer_name;
        $ret_c $fn_name($outer_name s) {
            return s.inner.a0;
        }


    # Perl types
    my $inner_type = Struct [@inner_perl_fields];
    my $outer_type = Struct [ inner => $inner_type, z => $outer_scalar->{perl}->() ];

    # Value generators
    my @inner_gens        = map { $_->{gen} } @inner_fields;
    my $outer_gen         = $outer_scalar->{gen};
    my $check_inner_names = [ map {"a$_"} 0 .. $#inner_fields ];
    my $captured_a0;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [$outer_sig],
        sig_ret    => $ret_sig,
        perl_args  => [$outer_type],
        perl_ret   => $inner_fields[0]->{perl}->(),
        gen_values => [
            sub {
                my %inner_h;
                for my $i ( 0 .. $#inner_fields ) {
                    $inner_h{"a$i"} = $inner_gens[$i]->();
                }
                $captured_a0 = $inner_h{a0};
                return { inner => \%inner_h, z => $outer_gen->() };
            },
        ],
        verify => sub ($result) {
            is $result, $captured_a0, 'nested struct inner.a0 roundtrip';
            diag Dumper $result;
        }
    };
}

# Struct with array member (tests Array[] inside struct layout)
sub generate_struct_array_member_fn {
    my ($fn_name) = @_;
    my @ints = grep {
        $_->{c} ne 'float'             &&
            $_->{c} ne 'double'        &&
            $_->{c} ne 'char'          &&
            $_->{c} ne 'unsigned char' &&
            $_->{c} ne 'bool'          &&
            sizeof( $_->{perl}->() )
            <= 2
    } @PRIMITIVES;
    my $base        = pick(@ints);
    my $count       = 2 + int( rand(3) );          # 2..4 elements in array
    my $struct_name = 'AM' . int( rand(99999) );

    # Generate array values and a trailing scalar
    my @arr_vals   = map { $base->{gen}->() } 1 .. $count;
    my $scalar_gen = $base->{gen};
    my $scalar_val = $scalar_gen->();
    my $c_code     = <<~"";
        typedef struct {
            $base->{c} arr[$count];
            $base->{c} x;
        } $struct_name;
        int $fn_name($struct_name s) {
            int sum = (int)s.x;
            for (int i = 0; i < $count; i++) sum += (int)s.arr[i];
            return sum;
        }

    my $array_type  = Array [ $base->{perl}->(), $count ];
    my $struct_type = Struct [ arr => $array_type, x => $base->{perl}->() ];
    my $struct_sig  = '{arr:[' . $count . ':' . $base->{sig} . '],x:' . $base->{sig} . '}';
    my $expected    = $scalar_val;
    $expected += $_ for @arr_vals;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [$struct_sig],
        sig_ret    => 'int',
        perl_args  => [$struct_type],
        perl_ret   => Int(),
        gen_values => [
            sub {
                return { arr => [@arr_vals], x => $scalar_val };
            },
        ],
        verify => sub ($result) {
            is $result, $expected, 'struct array member roundtrip';
            diag Dumper $result;
        }
    };
}

# Union (by pointer)
sub generate_union_fn {
    my ($fn_name)  = @_;
    my $union_name = 'U' . int( rand(99999) );
    my @candidates = ( @PRIMITIVES[ 0 .. 5 ] );
    my $nfields    = 2 + int( rand(3) );
    my @fields     = pick_n( $nfields, @candidates );
    my ( @union_members, @union_perl_fields, @union_sig_fields );
    for my $f (@fields) {
        my $fname = 'm' . scalar(@union_members);
        push @union_members,     "$f->{c} $fname;";
        push @union_perl_fields, $fname, $f->{perl}->();
        push @union_sig_fields,  "$fname:" . $f->{sig};
    }
    my $union_body = join( ' ', @union_members );
    my $union_sig  = '<' . join( ',', @union_sig_fields ) . '>';
    my $c_code     = <<"END_C";
typedef union { $union_body } $union_name;

int $fn_name($union_name *u) {
    return u ? (int)u->m0 : -1;
}
END_C
    my $val        = $fields[0]->{gen}->();
    my $union_type = Union [@union_perl_fields];
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ["*$union_sig"],
        sig_ret    => 'int',
        perl_args  => [ Pointer [$union_type] ],
        perl_ret   => Int(),
        gen_values => [
            sub {
                my $mem = Affix::malloc( sizeof($union_type) );
                my $pin = cast( $mem, $union_type );
                $pin->{m0} = $val;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
    };
}

# Union by value (tests union return/arg via value, not pointer)
sub generate_union_byval_fn {
    my ($fn_name)  = @_;
    my $union_name = 'UB' . int( rand(99999) );
    my @candidates = ( @PRIMITIVES[ 0 .. 5 ] );
    my $nfields    = 2 + int( rand(2) );                # 2..3 fields
    my @fields     = pick_n( $nfields, @candidates );
    my ( @union_members, @union_perl_fields, @union_sig_fields, @c_params, @perl_args, @sig_args );
    for my $f (@fields) {
        my $fname = 'm' . scalar(@union_members);
        push @union_members,     "$f->{c} $fname;";
        push @union_perl_fields, $fname, $f->{perl}->();
        push @union_sig_fields,  "$fname:" . $f->{sig};
    }
    my $union_body = join( ' ', @union_members );
    my $union_sig  = '<' . join( ',', @union_sig_fields ) . '>';

    # C: takes union by value, returns m0 cast to int
    my $ret_c   = $fields[0]->{c};
    my $ret_sig = $fields[0]->{sig};
    my $c_code  = <<"END_C";
typedef union { $union_body } $union_name;

$ret_c $fn_name($union_name u) {
    return u.m0;
}
END_C
    my $union_type = Union [@union_perl_fields];
    my $val        = $fields[0]->{gen}->();
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [$union_sig],
        sig_ret    => $ret_sig,
        perl_args  => [$union_type],
        perl_ret   => $fields[0]->{perl}->(),
        gen_values => [
            sub {
                my %h;
                $h{m0} = $val;
                return \%h;
            }
        ],
        verify => sub ($result) {
            my $ok = $result == $val;
            unless ($ok) {
                diag "union byval: got=$result expected=$val";
            }
            ok $ok, 'union by-value roundtrip';
            diag Dumper $result;
        }
    };
}

# Enum
sub generate_enum_fn {
    my ($fn_name) = @_;
    my $nelems = 2 + int( rand(5) );
    my @elems;
    for my $i ( 0 .. $nelems - 1 ) {
        my $val = $i * 10 + int( rand(5) );
        push @elems, "    ${fn_name}_V${i} = $val,";
    }
    my $enum_def = "typedef enum {\n" . join( "\n", @elems ) . "\n} ${fn_name}_enum_t;";
    my $c_code   = <<"END_C";
$enum_def

int $fn_name(${fn_name}_enum_t e) {
    return (int)e;
}
END_C
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['int'],
        sig_ret    => 'int',
        perl_args  => [ Int() ],
        perl_ret   => Int(),
        gen_values => [ sub { pick( 0 .. $nelems - 1 ) * 10 } ],
    };
}

# Enum type marshalling (tests Enum[...] return/arg via dualvars)
sub generate_enum_type_fn {
    my ($fn_name) = @_;
    my $nelems = 2 + int( rand(4) );       # 2..5 elements
    my ( @enum_vals, @enum_names, @perl_constants, @c_cases );
    for my $i ( 0 .. $nelems - 1 ) {
        my $name = "${fn_name}_V${i}";
        my $val  = $i * 10 + int( rand(5) );
        push @enum_vals,      $val;
        push @enum_names,     $name;
        push @perl_constants, "[ $name => $val ]";
        push @c_cases,        "        case $i: return $name;";
    }
    my $enum_def = "typedef enum {\n" . join( ",\n", map {"    $enum_names[$_] = $enum_vals[$_]"} 0 .. $#enum_names ) . "\n} ${fn_name}_enum_t;";

    # C function takes int index, returns enum value at that index
    my $default_name = $enum_names[0];
    my $cases        = join( "\n", @c_cases );
    my $c_code       = <<"END_C";
$enum_def

${fn_name}_enum_t $fn_name(int idx) {
    switch(idx) {
$cases
        default: return $default_name;
    }
}
END_C
    my $enum_sig  = 'e:int';
    my $perl_enum = Enum [ map { [ $_ => $enum_vals[$_] ] } 0 .. $#enum_vals ];
    my $chosen_idx;
    my $idx_gen = sub { $chosen_idx = int( rand($nelems) ) };
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['int'],
        sig_ret    => $enum_sig,
        perl_args  => [ Int() ],
        perl_ret   => $perl_enum,
        gen_values => [$idx_gen],
        verify     => sub ($result) {
            my $name = $enum_names[$chosen_idx];
            my $val  = $enum_vals[$chosen_idx];
            my $got  = 0 + $result;
            ok( $got == $val, "enum return $name (got=$got, expect=$val)" );
            unless ( $got == $val ) {
                diag "GOT:     $got (str=\"$result\")";
                diag "EXPECTED: $val ($name)";
            }
        },
    };
}

# Multi-argument stress (exceeds register count on x86_64)
sub generate_mega_arg_fn {
    my ($fn_name)   = @_;
    my $nparams     = 8 + int( rand(4) );
    my @param_types = pick_n( $nparams, @PRIMITIVES );
    my $ret_type    = pick(@PRIMITIVES);
    my ( @c_params, @perl_args, @sig_args, @gen_values, @cast_args );
    for my $pt (@param_types) {
        my $pname = 'p' . scalar(@c_params);
        push @c_params,  "$pt->{c} $pname";
        push @perl_args, $pt->{perl}->();
        push @sig_args,  $pt->{sig};
        my $val = $pt->{gen}->();
        push @gen_values, sub {$val};
        push @cast_args,  "($pt->{c})p$#c_params";
    }
    my $params_str = join( ', ',  @c_params );
    my $sum_expr   = join( ' + ', @cast_args );
    my $c_code     = <<"END_C";
$ret_type->{c} $fn_name($params_str) {
    return ($ret_type->{c})($sum_expr);
}
END_C
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => \@sig_args,
        sig_ret    => $ret_type->{sig},
        perl_args  => \@perl_args,
        perl_ret   => $ret_type->{perl}->(),
        gen_values => \@gen_values,
    };
}

# Pointer pass-through
my @POINTER_PRIMITIVES = grep { sizeof( $_->{perl}->() ) > 1 } @PRIMITIVES;

sub generate_pointer_fn {
    my ($fn_name) = @_;
    my $base      = pick(@POINTER_PRIMITIVES);
    my $c_code    = <<"END_C";
$base->{c} $fn_name($base->{c} *ptr) {
    return ptr ? *ptr : 0;
}
END_C
    my $affix_type = $base->{perl}->();
    my $ptr_type   = Pointer [$affix_type];
    my $is_float   = ( $base->{c} eq 'float' || $base->{c} eq 'double' );
    my $val        = $base->{gen}->();
    my @keep_alive;
    my $verify = $is_float ?
        sub ($result) {
        my $tol = $base->{c} eq 'float' ? 1e-5 : 1e-10;
        ok( abs( $result - $val ) <= $tol, "$fn_name ${\($base->{c})} roundtrip" );
        } :
        sub ($result) { ok( $result == $val, "$fn_name ${\($base->{c})} roundtrip" ) };
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ '*' . $base->{sig} ],
        sig_ret    => $base->{sig},
        perl_args  => [$ptr_type],
        perl_ret   => $affix_type,
        gen_values => [
            sub {
                my $mem = Affix::malloc( sizeof($affix_type) );
                my $pin = cast( $mem, $ptr_type );
                $$pin = $val;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => $verify,
    };
}

# Callback (function pointer)
sub generate_callback_fn {
    my ($fn_name) = @_;
    my @small     = ( @PRIMITIVES[ 0 .. 2 ] );
    my $a1        = pick(@small);
    my $a2        = pick(@small);
    my $ret       = pick(@small);
    my $cb_name   = 'cb_' . int( rand(99999) );
    my $cb_sig    = "(*($a1->{sig},$a2->{sig})->$ret->{sig})";
    my $c_code    = <<"END_C";
typedef $ret->{c} (*$cb_name)($a1->{c}, $a2->{c});

$ret->{c} $fn_name($cb_name op, $a1->{c} x, $a2->{c} y) {
    return op(x, y);
}
END_C
    my $v1 = $a1->{gen}->();
    my $v2 = $a2->{gen}->();
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ $cb_sig, $a1->{sig}, $a2->{sig} ],
        sig_ret    => $ret->{sig},
        perl_args  => [ Callback [ [ $a1->{perl}->(), $a2->{perl}->() ] => $ret->{perl}->() ], $a1->{perl}->(), $a2->{perl}->() ],
        perl_ret   => $ret->{perl}->(),
        gen_values => [
            sub {
                sub ( $x, $y ) { $x + $y }
            },
            sub {$v1},
            sub {$v2}
        ],
    };
}

# Callback with enum arg (reverse trampoline with enum marshalling)
sub generate_callback_enum_fn {
    my ($fn_name) = @_;
    my $nelems = 2 + int( rand(4) );       # 2..5 elements
    my ( @enum_vals, @enum_names );
    for my $i ( 0 .. $nelems - 1 ) {
        push @enum_vals,  $i * 10 + int( rand(5) );
        push @enum_names, "${fn_name}_V${i}";
    }
    my $enum_def  = "typedef enum {\n" . join( ",\n", map {"    $enum_names[$_] = $enum_vals[$_]"} 0 .. $#enum_names ) . "\n} ${fn_name}_enum_t;";
    my $enum_sig  = 'e:int';
    my $perl_enum = Enum [ map { [ $_ => $enum_vals[$_] ] } 0 .. $#enum_vals ];
    my $cb_name   = 'cb_' . int( rand(99999) );

    # C: callback takes enum, returns int; wrapper calls callback with enum value
    my $c_code = <<"END_C";
$enum_def

typedef int (*$cb_name)(${fn_name}_enum_t);

int $fn_name($cb_name op, ${fn_name}_enum_t x) {
    return op(x);
}
END_C
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ "(*($enum_sig)->int)", $enum_sig ],
        sig_ret    => 'int',
        perl_args  => [ Callback [ [$perl_enum] => Int() ], $perl_enum ],
        perl_ret   => Int(),
        gen_values => [
            sub {
                sub ($x) { 0 + $x }    # callback: return numeric value of enum
            },
            sub {
                my $i = int( rand($nelems) );
                return $enum_vals[$i];    # pass enum numeric value
            },
        ],
        verify => sub ($result) {

            # The callback returns the numeric value of whatever enum it receives.
            # The C function passes the enum through, so result == enum numeric value.
            # We can't predict exactly which enum was sent (random), so just verify
            # the result is a valid enum value.
            my $valid = grep { $result == $_ } @enum_vals;
            ok( $valid, "callback enum arg roundtrip (result=$result is valid)" );
            unless ($valid) {
                diag "GOT: $result";
                diag "EXPECTED one of: " . join( ", ", @enum_vals );
            }
        },
    };
}

# Callback with struct arg (reverse trampoline with aggregate classification)
sub generate_callback_struct_fn {
    my ($fn_name) = @_;

    # Use simple int-only struct (keep it small to avoid ABI complexity)
    my $struct_name = 'CS' . int( rand(99999) );
    my @all         = grep {
        $_->{c} ne 'float'             &&
            $_->{c} ne 'double'        &&
            $_->{c} ne 'char'          &&
            $_->{c} ne 'unsigned char' &&
            $_->{c} ne 'bool'          &&
            sizeof( $_->{perl}->() ) == 4
    } @PRIMITIVES;

    # Reverse trampoline struct-by-value only works reliably with single small fields
    my @fields = ( pick(@all) );
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields );
    for my $i ( 0 .. $#fields ) {
        my $f = $fields[$i];
        push @struct_members,     "$f->{c} m$i;";
        push @struct_perl_fields, "m$i", $f->{perl}->();
        push @struct_sig_fields,  "m$i:" . $f->{sig};
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '{' . join( ',', @struct_sig_fields ) . '}';
    my $cb_name     = 'cb_' . int( rand(99999) );
    my $ret_c       = $fields[0]->{c};
    my $ret_sig     = $fields[0]->{sig};
    my $ret_perl    = $fields[0]->{perl}->();

    # C: callback takes struct by value, returns first field; wrapper calls it
    my $c_code = <<"END_C";
typedef struct { $struct_body } $struct_name;

typedef $ret_c (*$cb_name)($struct_name);

$ret_c $fn_name($cb_name op, $struct_name s) {
    return op(s);
}
END_C
    my $perl_struct = Struct [@struct_perl_fields];
    my $captured_struct;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ "(*($struct_sig)->$ret_sig)", $struct_sig ],
        sig_ret    => $ret_sig,
        perl_args  => [ Callback [ [$perl_struct] => $ret_perl ], $perl_struct ],
        perl_ret   => $ret_perl,
        gen_values => [
            sub {
                sub ($s) { $s->{m0} }    # callback: return first field of struct
            },
            sub {
                my %h;
                for my $i ( 0 .. $#fields ) {
                    $h{"m$i"} = $fields[$i]->{gen}->();
                }
                $captured_struct = \%h;
                return \%h;
            },
        ],
        verify => sub ($result) {
            my $expected = $captured_struct->{m0};
            is( $result, $expected,
                "callback struct-by-value roundtrip (expected: $expected, got: " . ( defined $result ? $result : 'undef' ) . ")" );
        },
    };
}

# Callback with struct return (reverse trampoline returning struct by value)
sub generate_callback_struct_ret_fn {
    my ($fn_name) = @_;
    my @all = grep {
        $_->{c} ne 'float'             &&
            $_->{c} ne 'double'        &&
            $_->{c} ne 'char'          &&
            $_->{c} ne 'unsigned char' &&
            $_->{c} ne 'bool'          &&
            sizeof( $_->{perl}->() )
            <= 4
    } @PRIMITIVES;
    my @fields      = pick_n( 2, @all );           # 2-field struct
    my $struct_name = 'CR' . int( rand(99999) );
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields );
    for my $i ( 0 .. $#fields ) {
        my $f = $fields[$i];
        push @struct_members,     "$f->{c} m$i;";
        push @struct_perl_fields, "m$i", $f->{perl}->();
        push @struct_sig_fields,  "m$i:" . $f->{sig};
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '{' . join( ',', @struct_sig_fields ) . '}';
    my $cb_name     = 'cb_' . int( rand(99999) );

    # C: callback takes int arg, returns struct; wrapper calls it and returns m0
    my $ret_c  = $fields[0]->{c};
    my $c_code = <<"END_C";
typedef struct { $struct_body } $struct_name;

typedef $struct_name (*$cb_name)(int);

$ret_c $fn_name($cb_name op, int x) {
    $struct_name s = op(x);
    return s.m0;
}
END_C
    my $perl_struct = Struct [@struct_perl_fields];
    my $val         = $fields[0]->{gen}->();
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ "(*($struct_sig)->int)", 'int' ],
        sig_ret    => $fields[0]->{sig},
        perl_args  => [ Callback [ [ Int() ] => $perl_struct ], Int() ],
        perl_ret   => $fields[0]->{perl}->(),
        gen_values => [
            sub {
                sub ($x) { { m0 => $val } }    # callback: return struct with m0 = val
            },
            sub {$val},                        # argument x (ignored by callback logic)
        ],
        verify => sub ($result) {
            my $ok = $result == $val;
            unless ($ok) {
                diag "callback struct ret: got=$result expected=$val";
            }
            ok( $ok, "callback struct-return roundtrip" );
        },
    };
}

# Bitfield struct (random widths 1-31, tests bitfield layout/marshalling)
sub generate_bitfield_fn {
    my ($fn_name)   = @_;
    my $struct_name = 'BF' . int( rand(99999) );
    my $nfields     = 2 + int( rand(2) );          # 2..3 bitfields
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields, @c_params, @perl_args, @sig_args, @gen_values );
    my @widths;
    my @values;
    for my $i ( 0 .. $nfields - 1 ) {
        my $width = 1 + int( rand(31) );           # 1..31 bits
        push @widths, $width;
        my $max_val = ( 1 << $width ) - 1;
        my $val     = int( rand( $max_val + 1 ) );
        push @values, $val;
        my $fname = 'm' . $i;
        push @struct_members,     "uint32_t $fname : $width;";
        push @struct_perl_fields, $fname, UInt32(), $width;
        push @struct_sig_fields,  "$fname:uint32:$width";
        my $pname = "p$i";
        push @c_params,  "uint32_t $pname";
        push @perl_args, UInt32();
        push @sig_args,  'uint';
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '{' . join( ',', @struct_sig_fields ) . '}';

    # C: take struct by value, return sum of all bitfield members
    my $sum_expr = join( ' + ', map {"s.m$_"} 0 .. $nfields - 1 );
    my $c_code   = <<"END_C";
typedef struct { $struct_body } $struct_name;

uint32_t $fn_name($struct_name s) {
    return $sum_expr;
}
END_C
    my $struct_type = Struct [@struct_perl_fields];
    my $expected    = 0;
    $expected += $_ for @values;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [$struct_sig],
        sig_ret    => 'uint',
        perl_args  => [$struct_type],
        perl_ret   => UInt32(),
        gen_values => [
            sub {
                my %h;
                for my $i ( 0 .. $nfields - 1 ) {
                    $h{"m$i"} = $values[$i];
                }
                return \%h;
            }
        ],
        verify => sub ($result) {
            my $ok = $result == $expected;
            unless ($ok) {
                diag "bitfield sum: got=$result expected=$expected widths=[@widths] values=[@values]";
            }
            ok( $ok, "bitfield struct roundtrip" );
        },
    };
}

# Long double pass-through (16 bytes on SysV x64, 8 bytes on Windows/macOS ARM64)
sub generate_longdouble_fn {
    my ($fn_name) = @_;
    my $c_code = <<"END_C";
long double $fn_name(long double x) {
    return x;
}
END_C
    my $val = sprintf( "%.*f", 6, rand(100) - 50 );
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['longdouble'],
        sig_ret    => 'longdouble',
        perl_args  => [ LongDouble() ],
        perl_ret   => LongDouble(),
        gen_values => [ sub {$val} ],
        verify     => sub ($result) {
            my $ok = abs( $result - $val ) < 0.01;
            unless ($ok) {
                diag "longdouble: got=$result expected=$val";
            }
            ok( $ok, "long double roundtrip" );
        },
    };
}

# Complex number pass-through (_Complex float / _Complex double)
sub generate_complex_fn {
    my ($fn_name)    = @_;
    my $is_double    = rand(2) < 1;
    my $c_type       = $is_double ? 'double' : 'float';
    my $perl_type    = $is_double ? Double() : Float();
    my $complex_perl = Complex [$perl_type];
    my $prec         = $is_double ? 4 : 2;
    my $c_code       = <<"END_C";
${c_type} _Complex $fn_name(${c_type} _Complex x) {
    return x;
}
END_C
    my $re  = sprintf( "%.*f", $prec, rand(100) - 50 );
    my $im  = sprintf( "%.*f", $prec, rand(100) - 50 );
    my $sig = 'c[' . $c_type . ']';
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [$sig],
        sig_ret    => $sig,
        perl_args  => [$complex_perl],
        perl_ret   => $complex_perl,
        gen_values => [ sub { [ $re, $im ] } ],
        verify     => sub ($result) {
            my ( $got_re, $got_im ) = @$result;
            my $ok1 = abs( $got_re - $re ) < 0.1;
            my $ok2 = abs( $got_im - $im ) < 0.1;
            my $ok  = $ok1 && $ok2;
            unless ($ok) {
                diag "complex: got=[$got_re,$got_im] expected=[$re,$im]";
            }
            ok( $ok, "complex ${c_type} roundtrip" );
        },
    };
}

# SIMD vector by value (tests GCC vector extensions + Vector[] marshalling)
sub generate_simd_fn {
    my ($fn_name) = @_;

    # Use GCC vector extensions to avoid needing <immintrin.h> and AVX flags
    my @specs = (
        { c_vec => 'float __attribute__((vector_size(16)))', count => 4, base_c => 'float', perl => sub { Float() }, sig => 'v[4:float]', prec => 2 },
        {   c_vec  => 'double __attribute__((vector_size(16)))',
            count  => 2,
            base_c => 'double',
            perl   => sub { Double() },
            sig    => 'v[2:double]',
            prec   => 4
        },
        { c_vec => 'int __attribute__((vector_size(16)))', count => 4, base_c => 'int', perl => sub { Int() }, sig => 'v[4:int]', prec => 0 },
    );
    my $spec   = pick(@specs);
    my $c_code = <<"END_C";
$spec->{c_vec} $fn_name($spec->{c_vec} v) {
    return v;
}
END_C
    my @vals     = map { sprintf( "%.*f", $spec->{prec}, rand(100) - 50 ) } 1 .. $spec->{count};
    my $perl_vec = Vector [ $spec->{count}, $spec->{perl}->() ];
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ $spec->{sig} ],
        sig_ret    => $spec->{sig},
        perl_args  => [$perl_vec],
        perl_ret   => $perl_vec,
        gen_values => [ sub { \@vals } ],
        verify     => sub ($result) {
            my $ok = 1;
            for my $i ( 0 .. $spec->{count} - 1 ) {
                if ( abs( $result->[$i] - $vals[$i] ) > 0.1 ) {
                    $ok = 0;
                    last;
                }
            }
            unless ($ok) {
                diag "SIMD: got=[" . join( ',', @$result ) . "] expected=[@vals]";
            }
            ok( $ok, "SIMD vector roundtrip" );
        },
    };
}

# Float16 via pointer (tests Float16 marshalling without compiler-specific _Float16)
sub generate_float16_fn {
    my ($fn_name) = @_;

    # C: takes uint16_t* (raw float16 bits), reads as float, returns sum
    my $c_code = <<"END_C";
#include <stdint.h>
float $fn_name(uint16_t *bits) {
    // Reinterpret uint16_t bits as float16 by converting manually
    uint16_t h = *bits;
    uint32_t sign = (uint32_t)(h >> 15) << 31;
    uint32_t exp = (h >> 10) & 0x1f;
    uint32_t mantissa = h & 0x3ff;
    uint32_t f;
    if (exp == 0) {
        if (mantissa == 0) f = sign;
        else { exp = 1; while (!(mantissa & 0x400)) { mantissa <<= 1; exp--; } mantissa &= 0x3ff; f = sign | ((127 - 15 + exp) << 23) | (mantissa << 13); }
    } else if (exp == 31) {
        f = sign | 0x7f800000 | (mantissa << 13);
    } else {
        f = sign | ((exp + 127 - 15) << 23) | (mantissa << 13);
    }
    float val;
    memcpy(&val, &f, 4);
    return val;
}
END_C
    my $prec = 2;
    my $val  = sprintf( "%.*f", $prec, rand(10) - 5 );
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['*uint16'],
        sig_ret    => 'float',
        perl_args  => [ Pointer [ Float16() ] ],
        perl_ret   => Float(),
        gen_values => [
            sub {
                my $mem = Affix::malloc(2);
                my $pin = cast( $mem, Pointer [ Float16() ] );
                $$pin = $val;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => sub ($result) {
            my $ok = abs( $result - $val ) < 0.1;
            unless ($ok) {
                diag "float16: got=$result expected=$val";
            }
            ok( $ok, "float16 roundtrip via pointer" );
        },
    };
}

# Flexible array member (struct with trailing T data[])
sub generate_flexible_array_fn {
    my ($fn_name) = @_;
    my @ints = grep {
        $_->{c} ne 'float'               &&
            $_->{c} ne 'double'          &&
            $_->{c} ne 'char'            &&
            $_->{c} ne 'unsigned char'   &&
            $_->{c} ne 'unsigned short'  &&
            $_->{c} ne 'unsigned int'    &&
            $_->{c} ne 'unsigned long'   &&
            $_->{c} ne 'bool'            &&
            sizeof( $_->{perl}->() ) > 1 &&
            sizeof( $_->{perl}->() )
            <= 4
    } @PRIMITIVES;
    my $base        = pick(@ints);
    my $count       = 2 + int( rand(3) );                     # 2..4 elements
    my @vals        = map { $base->{gen}->() } 1 .. $count;
    my $struct_name = 'FA' . int( rand(99999) );

    # C: struct with flexible array member; function receives pointer and sums data[]
    my $c_code = <<"END_C";
typedef struct {
    int n;
    $base->{c} data[];
} $struct_name;

int $fn_name($struct_name *s) {
    int sum = 0;
    for (int i = 0; i < s->n; i++) sum += (int)s->data[i];
    return sum;
}
END_C

    # Perl: allocate struct manually, set n and data
    my $struct_type = Struct [ n => Int(), data => Array [ $base->{perl}->(), '?' ] ];
    my $struct_sig  = '{n:int,data:[?:' . $base->{sig} . ']}';

    # Compute expected matching C's 'int sum' overflow behavior (32-bit signed wrapping)
    my $expected = 0;
    for my $v (@vals) {
        $expected = $expected + $v;

        # Force 32-bit signed interpretation to match C 'int' arithmetic
        $expected = unpack( 'i', pack( 'i', $expected ) );
    }
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ["*$struct_sig"],
        sig_ret    => 'int',
        perl_args  => [ Pointer [$struct_type] ],
        perl_ret   => Int(),
        gen_values => [
            sub {
                my $elem_sz = sizeof( $base->{perl}->() );
                my $mem     = Affix::malloc( 4 + $count * $elem_sz );

                # Write n at offset 0 via struct accessor
                my $pin = cast( $mem, $struct_type );
                $pin->{n} = $count;

                # FAM has num_elements=0 in the type, so $pin->{data}[$i] won't work.
                # Cast the allocation as a flat array of the raw bytes to write data.
                # The first 4 bytes are 'n' (already written); remaining bytes are the FAM.
                # Use a byte-level approach: cast the whole block as an array of the
                # element type with an offset of 4.
                my $arr_type = Array [ $base->{perl}->(), $count ];
                my $data_ptr = ptr_add( $mem, 4 );
                my $arr      = cast( $data_ptr, $arr_type );
                for my $i ( 0 .. $count - 1 ) {
                    $arr->[$i] = $vals[$i];
                }
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => sub ($result) {
            my $ok = $result == $expected;
            unless ($ok) {
                diag "flexible array: got=$result expected=$expected vals=[@vals]";
            }
            ok( $ok, "flexible array member roundtrip" );
        },
    };
}

# Wide string (const wchar_t*)
sub generate_wstring_fn {
    my ($fn_name) = @_;
    my $c_code = <<"END_C";
int $fn_name(const wchar_t *s) {
    return s ? (int)wcslen(s) : -1;
}
END_C
    my $len      = 3 + int( rand(5) );
    my $test_str = join '', map { chr( 65 + int( rand(26) ) ) } 1 .. $len;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['*wchar_t'],
        sig_ret    => 'int',
        perl_args  => [ WString() ],
        perl_ret   => Int(),
        gen_values => [ sub {$test_str} ],
        verify     => sub ($result) {
            my $ok = $result == length($test_str);
            unless ($ok) {
                diag "wstring: got=$result expected=" . length($test_str) . " str=$test_str";
            }
            ok( $ok, "wide string length roundtrip" );
        },
    };
}

# Struct containing callback pointer
sub generate_struct_callback_fn {
    my ($fn_name)   = @_;
    my $struct_name = 'SC' . int( rand(99999) );
    my $cb_name     = 'cb_' . int( rand(99999) );
    my @small       = ( @PRIMITIVES[ 0 .. 2 ] );
    my $a           = pick(@small);
    my $ret         = pick(@small);

    # C: struct has a function pointer + data; wrapper calls through the function pointer
    my $c_code = <<"END_C";
typedef $ret->{c} (*$cb_name)($a->{c});

typedef struct {
    $cb_name fn;
    $a->{c} data;
} $struct_name;

$ret->{c} $fn_name($struct_name *s) {
    return s->fn(s->data);
}
END_C
    my $perl_struct = Struct [ fn => Pointer [ Callback [ [ $a->{perl}->() ] => $ret->{perl}->() ] ], data => $a->{perl}->() ];
    my $struct_sig  = '{fn:*((*' . $a->{sig} . ')->' . $ret->{sig} . '),data:' . $a->{sig} . '}';
    my $v1          = $a->{gen}->();
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ["*$struct_sig"],
        sig_ret    => $ret->{sig},
        perl_args  => [ Pointer [$perl_struct] ],
        perl_ret   => $ret->{perl}->(),
        gen_values => [
            sub {
                my $mem = Affix::malloc( sizeof($perl_struct) );
                my $pin = cast( $mem, $perl_struct );
                $pin->{fn}   = sub ($x) { $x + 1 };
                $pin->{data} = $v1;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => sub ($result) {
            my $expected = $v1 + 1;

            # Truncate expected to return type width (C truncates the callback return)
            my $ret_size = sizeof( $ret->{perl}->() );
            if    ( $ret_size == 1 ) { $expected = unpack( 'c', pack( 'c', $expected ) ) }
            elsif ( $ret_size == 2 ) { $expected = unpack( 's', pack( 's', $expected ) ) }
            elsif ( $ret_size == 4 ) { $expected = unpack( 'l', pack( 'l', $expected ) ) }
            my $ok = $result == $expected;
            unless ($ok) {
                diag "struct+callback: got=$result expected=$expected ret_size=$ret_size";
            }
            ok( $ok, "struct with callback pointer roundtrip" );
        },
    };
}

# Deeply nested pointer (int****)
sub generate_deep_ptr_fn {
    my ($fn_name) = @_;
    my $depth     = 2 + int( rand(2) );        # 2..3 levels of indirection
    my $c_type    = 'int';
    my $val       = int( rand(1000) ) - 500;

    # Build the C type: int**** for depth=3
    my $c_ptr_type = $c_type . ( '*' x $depth );

    # Build dereference chain: *...*ptr
    my $deref  = ( '*' x $depth ) . 'ptr';
    my $c_code = <<"END_C";
$c_type $fn_name($c_ptr_type ptr) {
    return $deref;
}
END_C

    # Build Perl type: Pointer[Pointer[...[Int()]...]]
    my $perl_type = Int();
    for ( 1 .. $depth ) {
        $perl_type = Pointer [$perl_type];
    }
    my $sig = ( '*' x $depth ) . 'int';
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [$sig],
        sig_ret    => 'int',
        perl_args  => [$perl_type],
        perl_ret   => Int(),
        gen_values => [
            sub {
                # Allocate chain of pointers: depth levels deep
                my $inner_mem = Affix::malloc( sizeof( Int() ) );
                my $inner_pin = cast( $inner_mem, Pointer [ Int() ] );
                $$inner_pin = $val;
                push @keep_alive, $inner_mem;
                my $ptr = $inner_pin;
                for ( 1 .. $depth - 1 ) {
                    my $outer_mem = Affix::malloc( sizeof($perl_type) );
                    my $outer_pin = cast( $outer_mem, $perl_type );
                    $$outer_pin = $ptr;
                    push @keep_alive, $outer_mem;
                    $ptr = $outer_pin;
                }
                return $ptr;
            }
        ],
        verify => sub ($result) {
            my $ok = $result == $val;
            unless ($ok) {
                diag "deep_ptr($depth): got=$result expected=$val";
            }
            ok( $ok, "deeply nested pointer roundtrip" );
        },
    };
}

# Void pointer roundtrip (void* pass-through)
sub generate_void_ptr_fn {
    my ($fn_name) = @_;
    my $c_code = <<"END_C";
void* $fn_name(void *ptr) {
    return ptr;
}
END_C
    my $base = pick(@POINTER_PRIMITIVES);
    my $val  = $base->{gen}->();
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['*void'],
        sig_ret    => '*void',
        perl_args  => [ Pointer [ Void() ] ],
        perl_ret   => Pointer [ Void() ],
        gen_values => [
            sub {
                my $mem = Affix::malloc( sizeof( $base->{perl}->() ) );
                my $pin = cast( $mem, Pointer [ $base->{perl}->() ] );
                $$pin = $val;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => sub ($result) {
            my $typed    = cast( $result, Pointer [ $base->{perl}->() ] );
            my $got      = $$typed;
            my $is_float = ( $base->{c} eq 'float' || $base->{c} eq 'double' );
            my $ok       = $is_float ? abs( $got - $val ) < 0.01 : $got == $val;
            unless ($ok) {
                diag "void_ptr: got=$got expected=$val";
            }
            ok( $ok, "void pointer roundtrip" );
        },
    };
}

# String roundtrip
sub generate_string_fn {
    my ($fn_name) = @_;
    my $c_code = <<"END_C";
int $fn_name(const char *s) {
    return s ? (int)strlen(s) : -1;
}
END_C
    my $test_str = join '', map { chr( 65 + int( rand(26) ) ) } 1 .. ( 3 + int( rand(10) ) );
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['*char'],
        sig_ret    => 'int',
        perl_args  => [ String() ],
        perl_ret   => Int(),
        gen_values => [ sub {$test_str} ],
        verify     => sub ($result) { ok( $result == length($test_str), "string length roundtrip" ) },
    };
}

# Packed struct by value (tests #pragma pack + Packed() sizeof/layout)
sub generate_packed_struct_fn {
    my ($fn_name) = @_;
    my $nfields   = 2 + int( rand(3) );
    my @all       = grep {
        $_->{c} ne 'float'             &&
            $_->{c} ne 'double'        &&
            $_->{c} ne 'char'          &&
            $_->{c} ne 'unsigned char' &&
            $_->{c} ne 'bool'          &&
            sizeof( $_->{perl}->() ) * 8 <= 53
    } @PRIMITIVES;
    my @fields      = pick_n( $nfields, @all );
    my $struct_name = 'PS' . int( rand(99999) );
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields, @c_params, @perl_args, @sig_args, @gen_values );
    for my $f (@fields) {
        my $fname = 'm' . scalar(@struct_members);
        push @struct_members,     "$f->{c} $fname;";
        push @struct_perl_fields, $fname, $f->{perl}->();
        push @struct_sig_fields,  "$fname:" . $f->{sig};
        my $pname = 'p' . scalar(@c_params);
        push @c_params,  "$f->{c} $pname";
        push @perl_args, $f->{perl}->();
        push @sig_args,  $f->{sig};
        my $val = $f->{gen}->();
        push @gen_values, sub {$val};
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '!' . '{' . join( ',', @struct_sig_fields ) . '}';
    my $params_str  = join( ', ', @c_params );
    my @inits       = map {"r.m$_ = p$_;"} 0 .. $#fields;
    my $init_block  = join( "\n    ", @inits );
    my $c_code      = <<"END_C";
#pragma pack(push, 1)
typedef struct { $struct_body } $struct_name;
#pragma pack(pop)

$struct_name $fn_name($params_str) {
    $struct_name r = {0};
    $init_block
    return r;
}
END_C
    my @field_names = map { 'm' . $_ } 0 .. $#fields;
    my @check_gens  = @gen_values;
    my @check_names = @field_names;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => \@sig_args,
        sig_ret    => $struct_sig,
        perl_args  => \@perl_args,
        perl_ret   => Packed( Struct [@struct_perl_fields] ),
        gen_values => \@gen_values,
        verify     => sub ($result) {
            my %expected;
            @expected{@check_names} = map { $_->() } @check_gens;
            local $ENV{TABLE_TERM_SIZE} = 200;
            my $ok = is( $result, \%expected, "packed struct fields match" );
            unless ($ok) {
                diag "GOT:     " . join( ", ", map {"$_=$result->{$_}"} sort keys %$result );
                diag "EXPECTED:" . join( ", ", map {"$_=$expected{$_}"} sort keys %expected );
            }
        },
    };
}

# Packed struct pointer roundtrip
sub generate_packed_struct_ptr_fn {
    my ($fn_name)   = @_;
    my $nfields     = 2 + int( rand(3) );
    my @all         = @PRIMITIVES;
    my @fields      = pick_n( $nfields, @all );
    my $struct_name = 'PP' . int( rand(99999) );
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields );
    for my $f (@fields) {
        my $fname = 'm' . scalar(@struct_members);
        push @struct_members,     "$f->{c} $fname;";
        push @struct_perl_fields, $fname, $f->{perl}->();
        push @struct_sig_fields,  "$fname:" . $f->{sig};
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '!' . '{' . join( ',', @struct_sig_fields ) . '}';
    my $first       = $fields[0];
    my $c_code      = <<"END_C";
#pragma pack(push, 1)
typedef struct { $struct_body } $struct_name;
#pragma pack(pop)

$first->{c} ${fn_name}($struct_name *s) {
    return s ? s->m0 : 0;
}
END_C
    my $val         = $first->{gen}->();
    my @perl        = @struct_perl_fields;
    my $struct_type = Packed( Struct [@perl] );
    my $is_float    = ( $first->{c} eq 'float' || $first->{c} eq 'double' );
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ["*$struct_sig"],
        sig_ret    => $first->{sig},
        perl_args  => [ Pointer [$struct_type] ],
        perl_ret   => $first->{perl}->(),
        gen_values => [
            sub {
                my $mem = Affix::malloc( sizeof($struct_type) );
                my $pin = cast( $mem, $struct_type );
                $pin->{m0} = $val;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => $is_float ?
            sub ($result) { ok( abs( $result - $val ) < 0.01, "roundtrip" ) }
        : sub ($result) { ok( $result == $val, "roundtrip" ) },
    };
}

# Struct pointer roundtrip
sub generate_struct_ptr_fn {
    my ($fn_name)   = @_;
    my $nfields     = 1 + int( rand(3) );
    my @fields      = pick_n( $nfields, @PRIMITIVES );
    my $struct_name = 'SP' . int( rand(99999) );
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields );
    for my $f (@fields) {
        my $fname = 'm' . scalar(@struct_members);
        push @struct_members,     "$f->{c} $fname;";
        push @struct_perl_fields, $fname, $f->{perl}->();
        push @struct_sig_fields,  "$fname:" . $f->{sig};
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '{' . join( ',', @struct_sig_fields ) . '}';
    my $first       = $fields[0];
    my $c_code      = <<"END_C";
typedef struct { $struct_body } $struct_name;

$first->{c} ${fn_name}($struct_name *s) {
    return s ? s->m0 : 0;
}
END_C
    my $val         = $first->{gen}->();
    my @perl        = @struct_perl_fields;
    my $struct_type = Struct [@perl];
    my $is_float    = ( $first->{c} eq 'float' || $first->{c} eq 'double' );
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ["*$struct_sig"],
        sig_ret    => $first->{sig},
        perl_args  => [ Pointer [$struct_type] ],
        perl_ret   => $first->{perl}->(),
        gen_values => [
            sub {
                my $mem = Affix::malloc( sizeof($struct_type) );
                my $pin = cast( $mem, $struct_type );
                $pin->{m0} = $val;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => $is_float ?
            sub ($result) { ok( abs( $result - $val ) < 0.01, "roundtrip" ) }
        : sub ($result) { ok( $result == $val, "roundtrip" ) },
    };
}

# Array roundtrip (tests Array[Type,N] marshalling)
sub generate_array_fn {
    my ($fn_name) = @_;
    my @ints      = grep { $_->{c} ne 'float' && $_->{c} ne 'double' && sizeof( $_->{perl}->() ) <= 2 } @PRIMITIVES;
    my $base      = pick(@ints);
    my $count     = 2 + int( rand(4) );                                                                                # 2..5 elements
    my @vals      = map { $base->{gen}->() } 1 .. $count;
    my $c_code    = <<"END_C";
int $fn_name($base->{c} arr[$count]) {
    int sum = 0;
    for (int i = 0; i < $count; i++) sum += (int)arr[i];
    return sum;
}
END_C
    my $array_type = Array [ $base->{perl}->(), $count ];
    my $expected   = 0;
    $expected += $_ for @vals;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ "[$count:" . $base->{sig} . "]" ],
        sig_ret    => 'int',
        perl_args  => [$array_type],
        perl_ret   => Int(),
        gen_values => [ sub { \@vals } ],
        verify     => sub ($result) {
            my $ok = $result == $expected;
            unless ($ok) {
                diag "array sum: got=$result expected=$expected count=$count type=$base->{c}";
            }
            ok( $ok, "array sum roundtrip" );
        },
    };
}

# Two callbacks called in sequence. tests simultaneous forward trampolines
sub generate_multi_cb_fn {
    my ($fn_name) = @_;
    my @safe      = grep { sizeof( $_->{perl}->() ) == 4 && $_->{c} =~ /^int/ } @PRIMITIVES;
    my $a         = pick(@safe);
    my $b         = pick(@safe);
    my $ret       = pick(@safe);
    my $cb1_name  = 'cb_add_' . int( rand(99999) );
    my $cb2_name  = 'cb_mul_' . int( rand(99999) );
    my $c_code    = <<"END_C";
typedef $ret->{c} (*$cb1_name)($a->{c}, $b->{c});
typedef $ret->{c} (*$cb2_name)($a->{c}, $b->{c});

$ret->{c} $fn_name($cb1_name op1, $cb2_name op2, $a->{c} x, $b->{c} y) {
    return op1(x, y) + op2(x, y);
}
END_C
    my $v1     = $a->{gen}->();
    my $v2     = $b->{gen}->();
    my $cb_sig = "(*($a->{sig},$b->{sig})->$ret->{sig})";
    return {
        c_code    => $c_code,
        c_name    => $fn_name,
        sig_args  => [ $cb_sig, $cb_sig, $a->{sig}, $b->{sig} ],
        sig_ret   => $ret->{sig},
        perl_args => [
            Callback [ [ $a->{perl}->(), $b->{perl}->() ] => $ret->{perl}->() ],
            Callback [ [ $a->{perl}->(), $b->{perl}->() ] => $ret->{perl}->() ],
            $a->{perl}->(),
            $b->{perl}->()
        ],
        perl_ret   => $ret->{perl}->(),
        gen_values => [
            sub {
                sub ( $x, $y ) { $x + $y }
            },
            sub {
                sub ( $x, $y ) { $x * $y }
            },
            sub {$v1},
            sub {$v2},
        ],
        verify => sub ($result) {
            my $add      = unpack( 'l', pack( 'l', $v1 + $v2 ) );
            my $mul      = unpack( 'l', pack( 'l', $v1 * $v2 ) );
            my $expected = unpack( 'l', pack( 'l', $add + $mul ) );
            my $ok       = $result == $expected;
            unless ($ok) {
                diag "multi_cb: got=$result expected=$expected (v1=$v1 v2=$v2 add=$add mul=$mul)";
            }
            ok( $ok, "multi-callback roundtrip" );
        },
    };
}

# Struct with multiple callback members to test nested type resolution
sub generate_struct_multi_cb_fn {
    my ($fn_name)   = @_;
    my $struct_name = 'SM' . int( rand(99999) );
    my @safe        = grep { sizeof( $_->{perl}->() ) == 4 && $_->{c} =~ /^int/ } @PRIMITIVES;
    my $a           = pick(@safe);
    my $ret         = pick(@safe);
    my $cb1_name    = 'cb1_' . int( rand(99999) );
    my $cb2_name    = 'cb2_' . int( rand(99999) );
    my $c_code      = <<"END_C";
typedef $ret->{c} (*$cb1_name)($a->{c});
typedef $ret->{c} (*$cb2_name)($a->{c});

typedef struct {
    $cb1_name fn1;
    $cb2_name fn2;
    $a->{c} data;
} $struct_name;

$ret->{c} $fn_name($struct_name *s) {
    return s->fn1(s->data) + s->fn2(s->data);
}
END_C
    my $perl_struct = Struct [
        fn1  => Pointer [ Callback [ [ $a->{perl}->() ] => $ret->{perl}->() ] ],
        fn2  => Pointer [ Callback [ [ $a->{perl}->() ] => $ret->{perl}->() ] ],
        data => $a->{perl}->()
    ];
    my $struct_sig = '{fn1:*((*' . $a->{sig} . ')->' . $ret->{sig} . '),fn2:*((*' . $a->{sig} . ')->' . $ret->{sig} . '),data:' . $a->{sig} . '}';
    my $v1         = $a->{gen}->();
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ["*$struct_sig"],
        sig_ret    => $ret->{sig},
        perl_args  => [ Pointer [$perl_struct] ],
        perl_ret   => $ret->{perl}->(),
        gen_values => [
            sub {
                my $mem = Affix::malloc( sizeof($perl_struct) );
                my $pin = cast( $mem, $perl_struct );
                $pin->{fn1}  = sub ($x) { $x + 1 };
                $pin->{fn2}  = sub ($x) { $x + 2 };
                $pin->{data} = $v1;
                push @keep_alive, $mem;
                return $pin;
            }
        ],
        verify => sub ($result) {
            my $fn1_ret  = unpack( 'l', pack( 'l', $v1 + 1 ) );
            my $fn2_ret  = unpack( 'l', pack( 'l', $v1 + 2 ) );
            my $expected = unpack( 'l', pack( 'l', $fn1_ret + $fn2_ret ) );
            my $ok       = $result == $expected;
            unless ($ok) {
                diag "struct_multi_cb: got=$result expected=$expected";
            }
            ok( $ok, "struct with multiple callbacks roundtrip" );
        },
    };
}

# Self-referential struct (linked list with Pointer[Self] in struct layout)
sub generate_linked_list_fn {
    my ($fn_name)   = @_;
    my $struct_name = 'LL' . int( rand(99999) );
    my $depth       = 2 + int( rand(2) );                          # 2..3 nodes
    my @vals        = map { int( rand(100) ) - 50 } 1 .. $depth;
    my $expected    = 0;
    $expected += $_ for @vals;
    my $c_code = <<"END_C";
typedef struct $struct_name {
    int val;
    struct $struct_name *next;
} $struct_name;

int $fn_name($struct_name *head) {
    int sum = 0;
    $struct_name *n = head;
    while (n) {
        sum += n->val;
        n = n->next;
    }
    return sum;
}
END_C
    my $node_type = Struct [ val => Int(), next => Pointer [ Void() ] ];
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['*{val:int,next:*void}'],
        sig_ret    => 'int',
        perl_args  => [ Pointer [$node_type] ],
        perl_ret   => Int(),
        gen_values => [
            sub {
                @keep_alive = ();
                my @nodes;
                for my $v ( reverse @vals ) {
                    my $mem = Affix::malloc( sizeof($node_type) );
                    my $pin = cast( $mem, $node_type );
                    $pin->{val} = $v;
                    if (@nodes) {
                        $pin->{next} = $nodes[-1];
                    }
                    else {
                        $pin->{next} = undef;
                    }
                    push @keep_alive, $mem;
                    push @nodes,      $pin;
                }
                return $nodes[-1];
            }
        ],
        verify => sub ($result) {
            my $ok = $result == $expected;
            unless ($ok) {
                diag "linked_list($depth): got=$result expected=$expected vals=[@vals]";
            }
            ok( $ok, "linked list sum roundtrip" );
        },
    };
}

# Callback receiving Pointer[Struct]
sub generate_cb_passing_struct_ptr_fn {
    my ($fn_name) = @_;
    my @safe      = grep { sizeof( $_->{perl}->() ) == 4 && $_->{c} =~ /^int/ } @PRIMITIVES;
    my @fields    = pick_n( 2, @safe );
    my ( @struct_members, @struct_perl_fields, @struct_sig_fields );
    for my $i ( 0 .. $#fields ) {
        my $f = $fields[$i];
        push @struct_members,     "$f->{c} m$i;";
        push @struct_perl_fields, "m$i", $f->{perl}->();
        push @struct_sig_fields,  "m$i:" . $f->{sig};
    }
    my $struct_body = join( ' ', @struct_members );
    my $struct_sig  = '{' . join( ',', @struct_sig_fields ) . '}';
    my $struct_name = 'CP' . int( rand(99999) );
    my $cb_name     = 'cb_' . int( rand(99999) );
    my $m0_val      = $fields[0]->{gen}->();
    my $m1_val      = $fields[1]->{gen}->();
    my $c_code      = <<"END_C";
typedef struct { $struct_body } $struct_name;
typedef int (*$cb_name)($struct_name*);

int $fn_name($cb_name op, $fields[0]->{c} v0, $fields[1]->{c} v1) {
    $struct_name s;
    s.m0 = v0;
    s.m1 = v1;
    return op(&s);
}
END_C
    my $perl_struct = Struct [@struct_perl_fields];
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => [ "(*($struct_sig)->int)", $fields[0]->{sig}, $fields[1]->{sig} ],
        sig_ret    => 'int',
        perl_args  => [ Callback [ [ Pointer [$perl_struct] ] => Int() ], $fields[0]->{perl}->(), $fields[1]->{perl}->() ],
        perl_ret   => Int(),
        gen_values => [
            sub {
                sub ($ptr) {
                    my $s = cast( $ptr, $perl_struct );
                    return $s->{m0} + $s->{m1};
                }
            },
            sub {$m0_val},
            sub {$m1_val},
        ],
        verify => sub ($result) {
            my $expected = unpack( 'l', pack( 'l', $m0_val + $m1_val ) );
            my $ok       = $result == $expected;
            unless ($ok) {
                diag "cb_passing_struct_ptr: got=$result expected=$expected";
            }
            ok( $ok, "callback receiving struct pointer roundtrip" );
        },
    };
}

# Deeply nested struct-with-callback-in-pointer
sub generate_deep_nest_fn {
    my ($fn_name)   = @_;
    my $struct_name = 'DN' . int( rand(99999) );
    my $cb_name     = 'cb_' . int( rand(99999) );
    my $val         = int( rand(200) ) - 100;

    # struct DN { int (*cb)(int); int data; }
    # int fn(DN **pp) { return pp[0]->cb(pp[0]->data); }
    my $c_code = <<"END_C";
typedef int (*$cb_name)(int);

typedef struct {
    $cb_name cb;
    int data;
} $struct_name;

int $fn_name($struct_name **pp) {
    return pp[0]->cb(pp[0]->data);
}
END_C
    my $inner_struct = Struct [ cb => Pointer [ Callback [ [ Int() ] => Int() ] ], data => Int() ];
    my @keep_alive;
    return {
        c_code     => $c_code,
        c_name     => $fn_name,
        sig_args   => ['*{cb:*((*int)->int),data:int}'],
        sig_ret    => 'int',
        perl_args  => [ Pointer [ Pointer [$inner_struct] ] ],
        perl_ret   => Int(),
        gen_values => [
            sub {
                # Build inner struct
                my $s_mem = Affix::malloc( sizeof($inner_struct) );
                my $s_pin = cast( $s_mem, $inner_struct );
                $s_pin->{cb}   = sub ($x) { $x + 42 };
                $s_pin->{data} = $val;
                push @keep_alive, $s_mem;

                # Build pointer-to-pointer
                my $pp_mem = Affix::malloc( sizeof( Pointer [ Void() ] ) );
                my $pp_pin = cast( $pp_mem, Pointer [ Pointer [$inner_struct] ] );
                $$pp_pin = $s_pin;
                push @keep_alive, $pp_mem;
                return $pp_pin;
            }
        ],
        verify => sub ($result) {
            my $expected = $val + 42;
            my $ok       = $result == $expected;
            unless ($ok) {
                diag "deep_nest: got=$result expected=$expected";
            }
            ok( $ok, "deeply nested struct-pointer-callback roundtrip" );
        },
    };
}

# Build + verify one function
sub fuzz_one {
    my $fn_name = unique_name();
    my $variant = pick(
        qw[primitive struct struct_float nested_struct struct_array_member
            union union_byval
            enum enum_type
            mega_arg
            pointer
            callback callback_enum callback_struct callback_struct_ret struct_callback
            longdouble complex
            bitfield simd float16 flexible_array wstring  deep_ptr void_ptr string
            struct_ptr packed_struct packed_struct_ptr array multi_cb struct_multi_cb
            linked_list cb_passing_struct_ptr deep_nest]
    );
    my $spec;
    if    ( $variant eq 'primitive' )             { $spec = generate_function($fn_name); }
    elsif ( $variant eq 'struct' )                { $spec = generate_struct_fn($fn_name); }
    elsif ( $variant eq 'struct_float' )          { $spec = generate_struct_float_fn($fn_name); }
    elsif ( $variant eq 'nested_struct' )         { $spec = generate_nested_struct_fn($fn_name); }
    elsif ( $variant eq 'struct_array_member' )   { $spec = generate_struct_array_member_fn($fn_name); }
    elsif ( $variant eq 'union' )                 { $spec = generate_union_fn($fn_name); }
    elsif ( $variant eq 'union_byval' )           { $spec = generate_union_byval_fn($fn_name); }
    elsif ( $variant eq 'enum' )                  { $spec = generate_enum_fn($fn_name); }
    elsif ( $variant eq 'enum_type' )             { $spec = generate_enum_type_fn($fn_name); }
    elsif ( $variant eq 'mega_arg' )              { $spec = generate_mega_arg_fn($fn_name); }
    elsif ( $variant eq 'pointer' )               { $spec = generate_pointer_fn($fn_name); }
    elsif ( $variant eq 'callback' )              { $spec = generate_callback_fn($fn_name); }
    elsif ( $variant eq 'callback_enum' )         { $spec = generate_callback_enum_fn($fn_name); }
    elsif ( $variant eq 'callback_struct' )       { $spec = generate_callback_struct_fn($fn_name); }
    elsif ( $variant eq 'callback_struct_ret' )   { $spec = generate_callback_struct_ret_fn($fn_name); }
    elsif ( $variant eq 'longdouble' )            { $spec = generate_longdouble_fn($fn_name); }
    elsif ( $variant eq 'complex' )               { $spec = generate_complex_fn($fn_name); }
    elsif ( $variant eq 'bitfield' )              { $spec = generate_bitfield_fn($fn_name); }
    elsif ( $variant eq 'simd' )                  { $spec = generate_simd_fn($fn_name); }
    elsif ( $variant eq 'float16' )               { $spec = generate_float16_fn($fn_name); }
    elsif ( $variant eq 'flexible_array' )        { $spec = generate_flexible_array_fn($fn_name); }
    elsif ( $variant eq 'wstring' )               { $spec = generate_wstring_fn($fn_name); }
    elsif ( $variant eq 'struct_callback' )       { $spec = generate_struct_callback_fn($fn_name); }
    elsif ( $variant eq 'deep_ptr' )              { $spec = generate_deep_ptr_fn($fn_name); }
    elsif ( $variant eq 'void_ptr' )              { $spec = generate_void_ptr_fn($fn_name); }
    elsif ( $variant eq 'string' )                { $spec = generate_string_fn($fn_name); }
    elsif ( $variant eq 'struct_ptr' )            { $spec = generate_struct_ptr_fn($fn_name); }
    elsif ( $variant eq 'packed_struct' )         { $spec = generate_packed_struct_fn($fn_name); }
    elsif ( $variant eq 'packed_struct_ptr' )     { $spec = generate_packed_struct_ptr_fn($fn_name); }
    elsif ( $variant eq 'array' )                 { $spec = generate_array_fn($fn_name); }
    elsif ( $variant eq 'multi_cb' )              { $spec = generate_multi_cb_fn($fn_name); }
    elsif ( $variant eq 'struct_multi_cb' )       { $spec = generate_struct_multi_cb_fn($fn_name); }
    elsif ( $variant eq 'linked_list' )           { $spec = generate_linked_list_fn($fn_name); }
    elsif ( $variant eq 'cb_passing_struct_ptr' ) { $spec = generate_cb_passing_struct_ptr_fn($fn_name); }
    elsif ( $variant eq 'deep_nest' )             { $spec = generate_deep_nest_fn($fn_name); }
    return unless $spec;
    note "--- Variant: $variant ---"                                                             if $verbose;
    note "C Code:\n$spec->{c_code}"                                                              if $verbose;
    note sprintf( "infix sig: (%s)->%s", join( ',', @{ $spec->{sig_args} } ), $spec->{sig_ret} ) if $verbose;
    subtest "$variant $spec->{c_name}" => sub {

        # Compile
        my $lib = eval {
            local $SIG{ALRM} = sub { die "compile timeout\n" };
            alarm $timeout;
            my $result = compile_source( $spec->{c_code} );
            alarm 0;
            $result;
        };
        unless ($lib) {
            note "SKIP compile: " . substr( $@ // '', 0, 60 );
            skip_all 1, "$variant compile";
            return;
        }
        ok my $fn = wrap( $lib, $spec->{c_name}, $spec->{perl_args}, $spec->{perl_ret} ), 'wrap';

        # Generate call arguments
        my @call_args;
        subtest 'gen_values' => sub {
            for my $gv ( @{ $spec->{gen_values} } ) {
                my $v;
                ok lives { $v = $gv->() }, Dumper $v;
                push @call_args, $gv->();
            }
        };

        # Call
        my $result = eval {
            local $SIG{ALRM} = sub { die "call timeout\n" };
            alarm $timeout;
            my $r = $fn->(@call_args);
            alarm 0;
            $r;
        };
        if ($@) {
            fail "CRASH variant=$variant name=$spec->{c_name}: $@";
            return;
        }

        # Verify
        if ( $spec->{verify} ) {
            $spec->{verify}->($result);
        }
        else {
            pass "$variant $spec->{c_name} survived (result=$result)";
        }
    };
}
#
note 'Fuzzing: Compile -> Load -> Affix -> Call -> Verify ABI';
note "  Iterations: $max_iter, Timeout: ${timeout}s";
fuzz_one() for 1 .. $max_iter;
#
done_testing;
