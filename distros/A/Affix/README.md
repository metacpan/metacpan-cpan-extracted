# NAME

Affix - A Foreign Function Interface eXtension

# SYNOPSIS

```perl
use v5.40;
use Affix qw[:all];

# Load a Library
# Affix finds the system math library automatically
my $libm = libm();

# Bind Functions
# double pow(double x, double y);
affix $libm, 'pow', [Double, Double] => Double;

# Call from Perl
warn pow(2.0, 10.0); # 1024

# Wrap an exported function in a code reference
my $bar = wrap( 'libfoo', 'bar', [Str, Float] => Double );

# Call from Perl
print $bar->( 'Baz', 3.14 );

# Bind an exported value to a Perl value
pin( my $ver, 'libfoo', 'VERSION', Int );

# Read the value
say $ver;

# Write to it too
$ver = 9;

# Complex Types (Structs)
# typedef struct { int x, y; int w, h; } Rect;
typedef Rect => Struct [
    x => Int, y => Int,
    w => Int, h => Int
];

# void draw_rect(Rect r);
affix $lib, 'draw_rect', [ Rect() ] => Void;

# Pass a simple HashRef - Affix marshals it automatically
draw_rect( { x => 10, y => 10, w => 100, h => 50 } );

# High performance memory
# For hot loops, allocate once and reuse
my $rect_ptr = calloc(1, Rect());

# Create views into the memory for fast updates
my $ptr_x = cast( $rect_ptr, Pointer[Int] );

while ($running) {
    # Pointer arithmetic and dereferencing
    my $next_int = ptr_add($ptr_x, 4);
    $$next_int = 99;

    draw_rect($rect_ptr);  # Pass the pointer
}
```

# DESCRIPTION

**Affix** is a modern Foreign Function Interface (FFI) that allows Perl to call functions exported by dynamic libraries
(DLLs, .so files, dylibs) developed in C, C++, Rust, Zig, Fortran, Assembly, and others without writing XS code.

It is built on top of **infix**, a lightweight C-based JIT engine designed specifically for zero-overhead calls. Affix
handles the complex ABI details of passing Structs, Arrays, and Callbacks by value or reference, on Windows, macOS,
Linux, and BSD, on both x64 and AArch64.

# EXPORTS

No functions are exported by default. You may import them individually or using tags.

```perl
use Affix qw[:all];     # Everything
use Affix qw[:types];   # Int, Float, Struct, Pointer, Enum...
use Affix qw[:memory];  # malloc, free, cast, dump, ptr_add...
use Affix qw[:lib];     # load_library, find_symbol, get_last_error_message...
use Affix qw[:pin];     # pin, unpin
```

# THE BASICS

Affix's API is designed to be expressive. Let's start at the beginning with the eponymous `affix( ... )` function.

## `affix( ... )`

Attaches a given symbol to a named perl sub in the current namespace.

```perl
affix libm, 'pow', [Double, Double] => Double;
warn pow( 3, 5 );

affix libc, 'puts', [String], Int;
puts( 'Hello' );

# Rename a function during import
affix './mylib.dll', ['output', 'write'], [String], Int;
write( 'Hello' );

# Use current process symbols (e.g. standard C library)
affix undef, [ 'rint', 'round' ], [Double], Double;
warn round(3.14);
```

Parameters:

- `$lib` - required

    A library handle returned by ["load\_library( $path )"](#load_library-path), a file path string, or `undef` (to pull functions from the
    main executable).

- `$symbol_name` - required

    Name of the symbol to wrap.

    If you pass a string, Affix will try to load the symbol with that exact name.

    If you pass an array reference (e.g., `['real_name', 'alias']`), Affix will look up `real_name` in the library but
    install the subroutine as `alias` in your Perl package.

- `$parameters` - required

    An array reference of argument types. See ["TYPES"](#types) for the full list (primitives, Struct, Pointer, etc.).

    If you pass an empty array `[]`, Affix assumes the function takes no arguments.

- `$return` - required

    A single return type for the function. Use `Void` if the function returns nothing.

On success, `affix( ... )` installs the subroutine and returns the generated code reference.

## `wrap( ... )`

Creates a wrapper around a given symbol but returns it as an anonymous CodeRef.

```perl
my $pow = wrap libm, 'pow', [Double, Double] => Double;
warn $pow->(5, 10); # 5**10
```

Arguments are nearly identical to ["affix( ... )"](#affix). `wrap( ... )` allows you to use FFI functions without polluting
your namespace which means you cannot rename the function with an alias.

## `pin( ... )`

```perl
my $errno;
pin $errno, libc, 'errno', Int;
print $errno;
$errno = 0;
```

Variables exported by a library - also referred to as "global" or "extern" variables - can be accessed using `pin( ...
)`. The above example code applies magic to `$errno` that binds it to the integer variable named "errno" as exported
by the C runtime. Reading the scalar reads the memory; writing to it writes to the memory.

Parameters:

- `$var` - required

    The scalar that will be bound to the exported variable.

- `$lib` - required

    The library handle or path.

- `$symbol_name` - required

    Name of the exported variable.

- `$type` - required

    Indicate to Affix what type of data the variable contains.

This is might be broken on BSDs. I don't run BSD to figure out if it's impossible but patches are welcome.

## `unpin( ... )`

```
unpin $errno;
```

Removes the magic applied by `pin( ... )` to a variable. The variable retains its last value but is no longer linked
to C memory.

## `typedef( ... )`

```perl
typedef MyType => Struct[ name => String, age => Int ];

# Use it
affix $lib, 'func', [ MyType() ] => Void;
```

Registers a named type alias in the Affix system. This is required for:

1. **Recursive Types**: A struct that contains a pointer to itself.
2. **Reusability**: Defining a complex signature once and using it in multiple functions.
3. **Smart Enums**: Generating Perl constants in your package.

# LIBRARY FUNCTIONS

Locating libraries on different platforms can be tricky. These utilities help you load and manage dynamic libraries.

They are exported by default but may be imported specifically with the `:lib` tag.

## `load_library( $path )`

```perl
my $lib = load_library('user32.dll');
```

Locates and loads a dynamic library, returning an opaque handle (`Affix::Lib`).

If you pass a name without an extension (e.g., 'm'), Affix will apply platform-specific prefixes and suffixes (e.g.,
'libm.so', 'libm.dylib', 'm.dll') and search standard system paths.

## `locate_lib( $name, [$version] )`

```perl
my $path = locate_lib('ssl', '1.1');
```

Searches system paths (LD\_LIBRARY\_PATH, PATH, DYLD\_LIBRARY\_PATH, etc.) and returns the full absolute path to the
library file, without loading it.

## `find_symbol( $lib, $name )`

Returns the raw memory address (as a pointer/integer) of a symbol within a loaded library.

## `get_last_error_message( )`

Returns a human-readable string describing the most recent error that occurred during library loading or symbol lookup.

## `libc()` / `libm()`

Convenience functions that return handles to the standard C library and Math library, respectively.

# MEMORY FUNCTIONS

Affix uses a concept I decided to call **pins** to manage C pointers safely. A pin is a magical scalar reference that
holds a raw memory address.

Memory functions are exported via the `:memory` or `:all` tags.

## `malloc( ... )`

```perl
my $ptr = malloc( $size );
```

Allocates `$size` bytes of uninitialized storage.

Returns a managed pin. When this variable goes out of scope in Perl, the memory is automatically freed.

## `calloc( ... )`

```perl
my $ptr = calloc( $num, $size_or_type );
```

Allocates memory for an array of `$num` objects and initializes them to zero. You may pass a type object (like `Int`)
as the second argument, and Affix will calculate the size for you. Returns a managed pin.

## `realloc( ... )`

```
$ptr = realloc( $ptr, $new_size );
```

Reallocates the given area of memory. Returns the new pointer (which may be different from the original). The original
pointer object is updated to point to the new address.

## `free( ... )`

```
free( $ptr );
```

Manually deallocates the space pointed to by `$ptr`.

**Note:** This only works on managed pins created by Affix. Attempting to free a pointer returned by a C library (which
probably uses the system allocator) will throw an exception to prevent heap corruption. To free C memory, you should
bind the library's `free` function.

## `cast( ... )`

```perl
my $int_ptr = cast( $void_ptr, Pointer[Int] );
```

Reinterprets a pointer.

- **To value:** If casting to a value type (`Int`, `String`, etc.), it immediately reads the memory and returns a Perl
scalar value.
- **To reference:** If casting to a Pointer or other aggregate type, it returns a new pin that aliases the same memory.
You can dereference this pin (`$$pin`) to read or write to the memory using the new type definition.

## `own( ... )`

```
own( $ptr, $bool );
```

Changes the ownership status of a pin.

- `own($p, 1)`: Perl takes ownership. The memory will be freed when `$p` goes out of scope.
- `own($p, 0)`: Perl relinquishes ownership. The memory will **not** be freed by Perl. Use this when passing a buffer to
a C function that takes ownership of it.

## `address( $ptr )`

Returns the numerical virtual memory address of a pointer as a `UInt64` (probably).

## Pointer Utilities

- `ptr_add( $ptr, $offset_bytes )`

    Returns a new unmanaged pin pointing `$offset_bytes` from the original. If the original pin is an Array type (e.g.,
    `[10:int]`), the new pin decays to a Pointer type (e.g., `*int`).

- `ptr_diff( $ptr1, $ptr2 )`

    Returns the difference in bytes between two pointers (`$ptr1 - $ptr2`).

- `is_null( $ptr )`

    Returns true if the pointer is NULL (0x0).

- `strdup( $string )`

    Allocates managed C memory and copies the Perl string into it (including the null terminator). Returns a
    `Pointer[Char]` pin.

- `strnlen( $ptr, $maxlen )`

    Calculates the length of a C string pointed to by `$ptr`, checking at most `$maxlen` bytes.

## Raw Memory Ops

Standard C memory operations are available for high-performance manipulation of Pins.

- `memchr( $ptr, $ch, $count )`
- `memcmp( $lhs, $rhs, $count )`
- `memset( $dest, $ch, $count )`
- `memcpy( $dest, $src, $count )`
- `memmove( $dest, $src, $count )`

## `dump( $ptr, $length )`

Dumps `$length` bytes of raw data from a given point in memory to STDOUT in a hex editor style. Useful for debugging
layout issues.

# INTROSPECTION

## `sizeof( ... )`

```perl
my $size = sizeof( Int );
my $size_rect = sizeof( Struct[ x => Int, y => Int ] );
```

Returns the size, in bytes, of the Type passed to it.

## `offsetof( ... )`

```perl
my $struct = Struct[ name => String, age => Int ];
my $offset = offsetof( $struct, 'age' );
```

Returns the byte offset of a field within a structure, accounting for platform alignment and padding.

## `alignof( ... )`

Returns the alignment requirement (in bytes) of a type.

## `types()`

Returns a list of all named types currently registered in the Affix system.

# TYPES

Affix uses type helpers to define signatures. These are exported via the `:types` tag.

```perl
# Example Signature
[ Int, String ] => Void
```

## Primitive Types

Primitives map to native C types.

```
Type        Description
----------------------------------------------------------------------------
Void        Return type only
Bool        Mapped to Perl true/false
Char        signed char (8-bit usually)
UChar       unsigned char
SChar       Explicitly signed char
Short       signed short
UShort      unsigned short
Int         signed int (platform native, usually 32-bit)
UInt        unsigned int
Long        signed long (32-bit on Win64, 64-bit on Linux64)
ULong       unsigned long
LongLong    signed long long (guaranteed 64-bit)
ULongLong   unsigned long long
Float       32-bit float
Double      64-bit float
LongDouble  Platform specific (80-bit or 128-bit)
Size_t      size_t
SSize_t     ssize_t
```

### Explicit Width Types

For precise control, use these types which are guaranteed to have specific bit widths across all platforms:

```
Int8, UInt8
Int16, UInt16
Int32, UInt32
Int64, UInt64
Int128, UInt128 (Passed as Decimal Strings)
```

## Pointers

Pointers are the glue of C. Affix provides distinct ways to handle them based on intent.

### Basic Pointers (`Pointer[Type]`)

When a function expects `int*` or `double*`, pass a **reference to a scalar**.

```perl
# C: void split_float(double val, int* whole, double* frac);
affix $lib, 'split_float', [ Double, Pointer[Int], Pointer[Double] ] => Void;

my ($whole, $frac);
split_float( 3.14, \$whole, \$frac );

say "Whole: $whole, Frac: $frac"; # Whole: 3, Frac: 0.14
```

Affix automatically:

- 1. Allocates temporary memory.
- 2. Copies the Perl value into it (if defined).
- 3. Passes the pointer to C.
- 4. Copies the result back into your Perl scalar after the call.

### Strings (`String` vs `Pointer[Char]`)

- **`String`**: Use this for `const char*` (input strings). Affix copies the Perl string to a temporary C buffer.
- **`Pointer[Char]`**: Use this for mutable strings `char*`. You must ensure the scalar passed has enough pre-allocated capacity (e.g. using `"\0" x 1024`).

### Void Pointers (`Pointer[Void]`)

Used for opaque handles or generic data.

- Pass `undef` to send `NULL`.
- Pass a reference `\$scalar` to send the address of that scalar.
- Pass a **Pin** (from `malloc` or `cast`) to pass that memory address directly.

### Pins (Managed Pointers)

For manual memory management, use `malloc`, `calloc`, or `cast`. These return **Pins**. A Pin is a reference to a
scalar holding the memory address, blessed with magic.

```perl
my $ptr = malloc(1024);   # Allocate 1024 bytes
my $view = cast($ptr, Int); # Treat it as an integer

$$view = 123;             # Write 123 to the memory
free($ptr);               # Free it manually (optional, GC handles it otherwise)
```

- `String`

    Alias for `const char*`. Affix automatically handles UTF-8 encoding (Perl to C) and decoding (C to Perl).

- `WString`

    Alias for `const wchar_t*`. Affix handles the complexity of UTF-16 (Windows) vs UTF-32 (Linux/macOS) and Surrogate
    Pairs automatically.

- `SV`

    The raw Perl Interpreter Object (`SV*`). Use this if you are writing a function that manipulates Perl internals
    directly.

## Aggregates

### Structs

Structs are the bread and butter of C APIs. In Affix, they map to **Perl Hash References**.

```perl
# C: typedef struct { int x; int y; } Point;
#    void draw_line(Point a, Point b);

# 1. Define the type (recommended for reuse)
typedef Point => Struct [
    x => Int,
    y => Int
];

# 2. Bind the function
affix $lib, 'draw_line', [ Point, Point ] => Void;

# 3. Call with HashRefs
draw_line( { x => 0, y => 0 }, { x => 100, y => 100 } );
```

**Nested Structs:** Affix handles deep structures automatically.

```perl
typedef Rect => Struct [
    top_left     => Point,
    bottom_right => Point,
    color        => Int
];

draw_rect({
    top_left     => { x => 10, y => 10 },
    bottom_right => { x => 50, y => 50 },
    color        => 0xFF0000
});
```

### Unions

Unions allow storing different data types in the same memory location. In Affix, pass a Hash Reference with **exactly
one key** corresponding to the field you want to set.

```perl
# C: union Event { int key_code; float pressure; };
typedef Event => Union [
    key_code => Int,
    pressure => Float
];

# Pass an integer
handle_event( { key_code => 27 } );

# Pass a float
handle_event( { pressure => 0.5 } );
```

- `Packed [ $align, $aggregate ]`

    Defines a struct with specific byte alignment (e.g. `#pragma pack(1)`).

    ```perl
    Packed [ 1,
        Struct[
            name => Pointer[Char],
            # ...etc.
        ]
    ];
    ```

## Working with Arrays

Fixed-size C arrays are mapped to Perl Array References.

```perl
# C: void process_matrix(int matrix[9]);
affix $lib, 'process_matrix', [ Array[Int, 9] ] => Void;

# Pass a reference to a Perl array
process_matrix( [1..9] );
```

For character arrays (`char[N]`), you can pass a standard Perl string. Affix will copy the bytes and ensure it is
null-terminated if space permits, or truncated if it does not.

```perl
# C: void set_name(char name[32]);
affix $lib, 'set_name', [ Array[Char, 32] ] => Void;

set_name("Affix");
```

## SIMD Vectors

Vectors (e.g. `__m128` on x86, `float32x4_t` on ARM) are first-class types in Affix. You can interact with them in
two ways:

1. **Array References**: Simplest to read and write
2. **Packed Strings**: Highest performance (avoids marshalling overhead)

```perl
# C: typedef float v4f __attribute__((vector_size(16)));
#    v4f add_vecs(v4f a, v4f b);
affix $lib, 'add_vecs', [ Vector[4, Float], Vector[4, Float] ] => Vector[4, Float];

# Option 1: Array References (Convenient)
my $res = add_vecs( [1, 2, 3, 4], [10, 20, 30, 40] );
# $res is [11.0, 22.0, 33.0, 44.0]

# Option 2: Packed Strings (Fast)
# Useful for tight loops, graphics, or physics math
my $packed_a = pack('f4', 1.0, 2.0, 3.0, 4.0);
my $packed_b = pack('f4', 10.0, 20.0, 30.0, 40.0);

# Pass binary strings directly
my $res_ref = add_vecs( $packed_a, $packed_b );
```

## Enumerations

```perl
typedef Status => Enum [
    [ OK => 0 ],
    'ERROR',                    # Auto-increments to 1
    [ FLAG_A => 1 << 0 ],       # Bit shifting
    [ FLAG_B => '1 << 1' ],     # String expression
    [ FLAG_C => 'FLAG_B << 1' ] # References previous keys
];
```

Defines a C enum backed by an integer.

- **Constants**: `typedef` installs constants (like `OK`) into your package.
- **Dualvars:** Values returned from C are dual-typed. `OK` behaves as the integer `0` in numeric operations, but prints
as the string `"OK"`.
- **Calculated Values:** You can use string expressions to define values. These are evaluated at definition time and can
refer to previously defined constants within the same Enum.

    ```perl
    typedef Permissions => Enum [
        [ READ    => 4 ],
        [ WRITE   => 2 ],
        [ EXEC    => 1 ],
        [ R_W     => 'READ | WRITE' ],          # 6
        [ ALL     => 'READ | WRITE | EXEC' ]    # 7
    ];
    ```

## Callbacks

You can pass Perl subroutines to C functions that expect function pointers.

```perl
# C: void set_handler( void (*callback)(int status, const char* msg) );

affix $lib, 'set_handler',
    [ Callback[ [Int, String] => Void ] ] => Void;

set_handler(sub ($status, $msg) {
    say "Received status $status: $msg";
});
```

**Note:** The callback is valid only as long as the C function holds onto it. If the C library stores the function
pointer globally, ensure your Perl code keeps the reference alive if necessary (though Affix handles the trampoline
lifecycle automatically for the duration of the call).

# UTILITIES

## `get_system_error()`

Returns the `errno` (Linux/Unix) or `GetLastError` (Windows) from the most recent FFI call. This must be called
immediately after the function invokes to ensure accuracy.

## `sv_dump( $sv )`

Dumps the internal structure of a Perl scalar to STDERR. Useful for debugging Perl internals.

# COMPILER WRAPPER

Affix includes a lightweight, cross-platform C compiler wrapper `Affix::Compiler`. This is useful for compiling small
C stubs or "glue" code at runtime to bridge complex macros or inline functions that cannot be bound directly.

```perl
use Affix;
my $compiler = Affix::Compiler->new(
    name   => 'my_wrapper',
    source => [ 'wrapper.c' ]
);
$compiler->compile();
my $lib_path = $compiler->link;
affix $lib_path, 'some_function', [], Void;
```

Supported languages include C and C++. Other languages will be supported in the future provided the underlying
toolchain is installed on the system.

# EXAMPLES

## High Performance Batching

```perl
# Allocate one C struct and reuse it to avoid GC overhead
my $rect = calloc(1, 'SDL_Rect');
my $x_ptr = cast(address($rect) + 0, 'Pointer[int]');

while ($running) {
    # Update C memory directly
    $$x_ptr++;
    # Pass the pointer to C
    SDL_RenderFillRect($renderer, $rect);
}
```

## Vectors and 128bit Math

```perl
use Affix;

# 128-bit Integers (Passed as Strings)
# __int128_t add128(__int128_t a, __int128_t b);
my $add = Affix::affix('libtest', 'add128', '(sint128, sint128) -> sint128');

# Pass strings, receive string
my $result = $add->("100000000000000000000", "5");
print $result; # "100000000000000000005"


# SIMD Vectors (Passed as Packed Data)
# m128 add_vecs(m128 a, m128 b); # Adds 4 floats
my $vec_add = Affix::affix('libtest', 'add_vecs', '(v[4:float], v[4:float]) -> v[4:float]');

# Pack arguments (4 floats)
my $v1 = pack('f4', 1.0, 2.0, 3.0, 4.0);
my $v2 = pack('f4', 5.0, 5.0, 5.0, 5.0);

# Pass binary strings directly (Fast Path)
my $res_ref = $vec_add->($v1, $v2);

# Result comes back as Array Ref by default from pull_vector
use Data::Dumper;
print Dumper($res_ref); # [6.0, 7.0, 8.0, 9.0]
```

# SEE ALSO

[FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus), [C::DynaLib](https://metacpan.org/pod/C%3A%3ADynaLib), [XS::TCC](https://metacpan.org/pod/XS%3A%3ATCC)

All the heavy lifting is done by **infix** ([https://github.com/sanko/infix](https://github.com/sanko/infix)).

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# COPYRIGHT

Copyright (C) 2023-2025 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
