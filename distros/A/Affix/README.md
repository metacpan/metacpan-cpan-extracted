# NAME

Affix - A Foreign Function Interface eXtension

# SYNOPSIS

```perl
use Affix;

# Load a Library
my $lib = load_library('m'); # libm.so / m.dll

# Bind a Function
#    double pow(double x, double y);
affix $lib, 'pow', [Double, Double] => Double;

# Call it
say pow(2.0, 10.0); # 1024

# Manual Memory Management (optional)
my $ptr = malloc(1024);
# ... use ptr ...
free($ptr);
```

# DESCRIPTION

**Affix** is a Foreign Function Interface (FFI) for Perl. It allows you to load dynamic libraries (DLLs, shared objects)
and call their functions natively without writing XS code or configuring a C compiler.

It distinguishes itself from other FFI solutions by using **infix**, a custom lightweight JIT engine. When you bind a
function, Affix generates machine code at runtime to handle the argument marshalling, resulting in significantly lower
overhead than generic FFI wrappers.

# EXPORTS

Affix exports nothing by default. You can import tags:

```perl
use Affix qw[:all];    # Everything
use Affix qw[:lib];    # Library loading (load_library, libc, ...)
use Affix qw[:memory]; # malloc, free, cast, ...
use Affix qw[:types];  # Int, Void, String, ...
```

# THE BASICS

Affix's API is designed to be expressive. Let's start at the beginning with the eponymous `affix( ... )` function.

## `affix( ... )`

Attaches a given symbol to a named perl sub in the current namespace.

```perl
# Standard: Load from library
affix $lib, 'pow', [Double, Double] => Double;

# Rename: Load 'pow', install as 'power'
affix $lib, ['pow' => 'power'], [Double, Double] => Double;

# Raw Pointer: Bind a specific memory address
# Useful for vtables, JIT code, or manual dlsym
affix undef, [ $ptr => 'my_func' ], [Int] => Void;
```

Parameters:

- `$lib`

    A library handle returned by ["load\_library( $path )" in load\_library](https://metacpan.org/pod/load_library#load_library-path), a path string, or `undef` (main executable).

- `$symbol_name`

    The name of the function to find.

    Pass `['real_name', 'alias']` to rename it in Perl.

- `$parameters`

    An array reference of argument types. See ["TYPES"](#types) for the full list (primitives, Struct, Pointer, etc.).

- `$return`

    A single return type for the function.

On success, `affix( ... )` installs the subroutine and returns the generated code reference.

## `wrap( ... )`

Creates a wrapper around a given symbol but returns it as an anonymous CodeRef.

```perl
# From Library
my $pow = wrap $lib, 'pow', [Double, Double] => Double;

# Call the function
my $x = $pow->(2, 5);

# From Raw Pointer
# Note: Library argument is undef
my $func = wrap undef, $ptr, [Int] => Void;
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

Affix provides tools to manage raw C memory via a concept called **pins**. A pin is a magical scalar reference that
binds to a raw memory address.

## `malloc( $size )`

```perl
my $ptr = malloc( 1024 );
```

Allocates `$size` bytes of uninitialized storage. Returns a **Pin** typed as `Pointer[Void]`.

To read or write to this memory, you must ["cast( $ptr, $type )"](#cast-ptr-type) it to a specific type or use `memcpy`.

## `calloc( $num, $size_or_type )`

```perl
my $ptr = calloc( 10, Int );
```

Allocates memory for an array of `$num` objects and initializes them to zero. You may pass a type object (like `Int`)
as the second argument, and Affix will calculate the size for you. Returns a managed pin.

## `realloc( $ptr, $new_size )`

```
$ptr = realloc( $ptr, $new_size );
```

Reallocates the given area of memory. Returns the new pointer (which may be different from the original). The original
pointer object is updated to point to the new address.

## `free( $ptr )`

```
free( $ptr );
```

Manually deallocates the space pointed to by `$ptr`.

**Note:** This only works on managed pins created by Affix. Attempting to free a pointer returned by a C library (which
probably uses the system allocator) will throw an exception to prevent heap corruption. To free C memory, you should
bind the library's `free` function.

## `cast( $ptr, $type )`

```perl
my $int_ptr = cast( $void_ptr, Pointer[Int] );
```

Reinterprets a pointer.

- **To value:** If casting to a value type (`Int`, `String`, etc.), it immediately reads the memory and returns a Perl
scalar value.
- **To reference:** If casting to a Pointer or other aggregate type, it returns a new pin that aliases the same memory.
You can dereference this pin (`$$pin`) to read or write to the memory using the new type definition.

## `own( $ptr, $bool )`

```
own( $ptr, $bool );
```

Changes the ownership status of a pin.

- `own($p, 1)`: Perl takes ownership. The memory will be freed when `$p` goes out of scope.
- `own($p, 0)`: Perl relinquishes ownership. The memory will **not** be freed by Perl. Use this when passing a buffer to
a C function that takes ownership of it.

## `address( $ptr )`

Returns the numerical virtual memory address of a pointer as a `UInt64`.

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

## `sizeof( $type )`

```perl
my $size = sizeof( Int );
my $size_rect = sizeof( Struct[ x => Int, y => Int ] );
```

Returns the size, in bytes, of the Type passed to it.

## `offsetof( $struct_type, $field_name )`

```perl
my $struct = Struct[ name => String, age => Int ];
my $offset = offsetof( $struct, 'age' );
```

Returns the byte offset of a field within a structure, accounting for platform alignment and padding.

## `alignof( $type )`

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

## Special Types

- `Buffer`

    Passes a pointer to the raw string buffer of a Perl scalar. Useful for "Zero-Copy" or "Direct-Write" C functions that
    populate a buffer.

    ```perl
    # C: void get_data(char *buf, int len);
    affix $lib, 'get_data', [ Buffer, Int ] => Void;

    my $buf = "\0" x 1024; # Pre-allocate
    get_data($buf, 1024);
    ```

    **Warning:** The scalar must be writable and have sufficient pre-allocated capacity.

- `File`

    Represents the standard C `FILE` structure. Use `Pointer[File]` to map a Perl filehandle (Glob or IO object) to
    `FILE*`.

    ```perl
    affix $lib, 'fprintf', [ Pointer[File], String ] => Int;
    open my $fh, '>', 'log.txt';
    fprintf($fh, "Hello from Affix!");
    ```

- `PerlIO`

    Represents the internal `PerlIO` structure. Use `Pointer[PerlIO]` when the C function expects `PerlIO*`.

- `SockAddr`

    Safe marshalling for packed socket addresses (e.g. from `Socket::pack_sockaddr_in`). Passed to C as `struct
    sockaddr*`.

- `String`

    Alias for `const char*`. Affix automatically handles UTF-8 encoding (Perl to C) and decoding (C to Perl).

- `StringList`

    Maps a Perl Array Reference of strings (`[ "a", "b" ]`) to a null-terminated `char**` array (common in C APIs like
    `execve` or `main(argc, argv)`).

    ```perl
    affix $lib, 'process_args', [ StringList ] => Int;
    process_args( [ "arg1", "arg2" ] );
    ```

- `SV`

    The raw Perl Interpreter Object (`SV`). Use this if you are writing a function that manipulates Perl internals
    directly. Note that this must always be a pointer: `Pointer[SV]`.

- `WString`

    Alias for `const wchar_t*`. Affix handles the complexity of UTF-16 (Windows) vs UTF-32 (Linux/macOS) and Surrogate
    Pairs automatically.

## Aggregates

### Structs

Structs are the bread and butter of C APIs. In Affix, they map to **Perl Hash References**.

```perl
# C: typedef struct { int x; int y; } Point;
#    void draw_line(Point a, Point b);

# Define the type (recommended for reuse)
typedef Point => Struct [
    x => Int,
    y => Int
];

# Bind the function
affix $lib, 'draw_line', [ Point, Point ] => Void;

# Call with HashRefs
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

- **Fixed-Size Arrays (`Array[Type, N]`)**

    Fixed-size C arrays are mapped to Perl Array References. Affix handles the decay to pointers and automatically writes
    back changes to your Perl array.

    ```perl
    # C: void process_matrix(int matrix[9]);
    affix $lib, 'process_matrix', [ Array[Int, 9] ] => Void;

    # Pass a reference to a Perl array
    process_matrix( [1..9] );
    ```

- **Binary Data**

    For arrays of bytes (`Array[UChar]` or `Array[UInt8]`), Affix treats the data as a raw binary blob. Dereferencing a
    Pin of this type yields a binary string, reading exactly the number of bytes specified.

    For arrays of characters (`Array[Char]` or `Array[SInt8]`), Affix treats the data as a C String, reading until the
    first null terminator or the array limit.

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
- **Calculated Values:** You can use string expressions to define values. These are evaluated at definition time.

## Variadic Functions (VarArgs)

Affix supports C functions that take a variable number of arguments, like `printf`.

```perl
# C: int printf(const char* format, ...);
affix libc, 'printf', [ String, VarArgs ] => Int;
```

When calling a variadic function, Affix performs dynamic type inference at runtime for the extra arguments:

- Perl Integers -> `int64_t`
- Perl Floats   -> `double` (Standard C promotion rules)
- Perl Strings  -> `char*`

```
printf("Hello %s, count is %d\n", "World", 123);
```

### Hinting Types with `coerce()`

Sometimes standard inference isn't enough (e.g., passing a `float` instead of `double`, or passing a Struct by
value). Use `coerce($type, $value)` to explicitly hint the type.

```perl
# Passing a struct by value to a variadic function
typedef Point => Struct [ x=>Int, y=>Int ];
my $p = { x => 10, y => 20 };

# Without coerce(), $p would likely be treated as an error or generic pointer
my_variadic_func( "Point: %P", coerce( Point(), $p ) );
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

## `errno()`

```perl
my $err = get_system_error();
die "Error $err: " . int($err);
```

Access the `errno` (Linux/Unix) or `GetLastError` (Windows) from the most recent FFI call. This must be called
immediately after the function invokes to ensure accuracy.

The return value is a **dualvar**:

- **Numeric context**: Returns the integer error code.
- **String context**: Returns the human-readable system error message (via `strerror` or `FormatMessage`).

## `sv_dump( $sv )`

Dumps the internal structure of a Perl scalar to STDERR. Useful for debugging Perl internals.

# COMPILER WRAPPER

Affix includes a lightweight, cross-platform C compiler wrapper `Affix::Build`. This is useful for compiling small C
stubs or "glue" code at runtime to bridge complex macros or inline functions that cannot be bound directly.

```perl
use Affix;
my $compiler = Affix::Build->new(
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

See [The Affix Cookbook](https://github.com/sanko/Affix.pm/discussions/categories/recipes) for comprehensive guides to
using Affix.

# SEE ALSO

[FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus), [C::DynaLib](https://metacpan.org/pod/C%3A%3ADynaLib), [XS::TCC](https://metacpan.org/pod/XS%3A%3ATCC), [C::Blocks](https://metacpan.org/pod/C%3A%3ABlocks)

All the heavy lifting is done by [infix](https://github.com/sanko/infix), my JIT compiler and type introspection
engine.

# AUTHOR

Sanko Robinson <sanko@cpan.org>

# COPYRIGHT

Copyright (C) 2023-2025 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
