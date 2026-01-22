# NAME

Affix - A Foreign Function Interface eXtension

# SYNOPSIS

```perl
use v5.40;
use Affix;

# Load a Library
my $lib = load_library(libm);    # libm.so / msvcrt.dll

# Bind a Function
#    double pow(double x, double y);
affix $lib, 'pow', [ Double, Double ] => Double;

# Call it
say pow( 2.0, 10.0 );    # 1024

# Allocate 1KiB of raw memory
my $ptr = Affix::malloc(1024);

# Write raw data to the pointer
Affix::memcpy( $ptr, 'test', 4 );

# Poiner arithmetic creates a new reference (doesn't modify original)
my $offset_ptr = Affix::ptr_add( $ptr, 12 );
Affix::memcpy( $offset_ptr, 'test', 4 );

# Inspect memory with a hex dump to STDOUT
Affix::dump( $ptr, 32 );

# Release the memory
Affix::free($ptr);
=head1 DESCRIPTION
```

**Affix** is a high-performance Foreign Function Interface (FFI) for Perl. It allows you to load dynamic libraries
(DLLs, shared objects) and call their functions natively without writing XS code or configuring a C compiler.

It distinguishes itself from other FFI solutions by using [**infix**](https://github.com/sanko/infix/), a custom
lightweight JIT engine. When you bind a function, Affix generates machine code at runtime (a 'trampoline') to handle
the argument marshalling. This results in significantly lower overhead than generic FFI wrappers that rely on dynamic
dispatch per-call.

# EXPORTS

Affix exports standard types (`Int`, `Double`, etc.) and core functions (`affix`, `wrap`, `load_library`) by
default.

You can control imports using tags:

```perl
use Affix qw[:all];    # Import everything
use Affix qw[:lib];    # Library helpers (libc, libm, load_library...)
use Affix qw[:memory]; # malloc, free, memcpy, cast, dump...
use Affix qw[:pin];    # Variable binding (pin, unpin)
use Affix qw[:types];  # Types only (Int, Struct, Pointer...)
```

# Core API

Affix's API is designed to be expressive. Let's start at the beginning with the eponymous `affix( ... )` function.

## `affix( ... )`

Attaches a symbol from a library to a named perl subroutine in the current namespace.

```perl
# Standard: Load from library
affix $lib, 'pow', [ Double, Double ] => Double;

# Rename: Load 'pow', install as 'power'
affix $lib, [ pow => 'power' ], [ Double, Double ] => Double;

# Raw pointer: Bind a specific memory address (vtables, JIT, dlsym, etc.)
affix undef, [ $ptr => 'my_func' ], [Int] => Void;
```

Parameters:

- `$lib`

    A library handle returned by `[load_library( $path )](#load_library-path)`, a path string, or `undef` (searches
    the main executable/process).

- `$symbol_name`

    The name of the function to find. Pass an array list (`['real_name', 'alias']`) to rename it in Perl.

- `$parameters`

    An array reference of argument types. See [Types](#types) for the full list.

- `$return`

    A single return type for the function.

On success, `affix( ... )` installs the subroutine and returns the generated code reference.

## `wrap( ... )`

Creates a wrapper around a given symbol and returns it as an anonymous `CODE` reference.

```perl
# From library
my $pow = wrap $lib, 'pow', [ Double, Double ] => Double;

# Call the function
my $result = $pow->( 2, 5 );

# From a raw pointer
# Note: Library argument is undef
my $func = wrap undef, $ptr, [Int] => Void;
```

Arguments are nearly identical to `[affix( ... )](#affix)` except you cannot provide an alias for the function
name.

## `pin( ... )`

```perl
my $scalar;
# Bind $scalar to the global integer variable 'errno' in libc
pin $scalar, libc(), 'errno', Int;
$scalar = 0;   # Writes to C memory
sysopen( ... );
say $scalar;   # Reads from C memory
```

Variables exported by a library (global/extern variables) can be accessed using `pin`. Reading the scalar reads the
memory; writing to it writes to the memory.

Parameters:

- `$var`

    The scalar to bind.

- `$lib`

    The library handle.

- `$symbol`

    Name of the exported variable.

- `$type`

    The type of data the variable contains.

## `unpin( ... )`

```
unpin $errno;
```

Removes the magic applied by `pin( ... )` to a variable. The variable retains its last value but is no longer linked
to C memory.

## `typedef( ... )`

```perl
typedef MyType => Struct[ name => String, age => Int ];


# Now use it in signatures
affix $lib, 'func', [ MyType() ] => Void;
```

Registers a named type alias. This is required for:

- 1. **Recursive Types**: A struct that contains a pointer to itself.
- 2. **Reusability**: Defining a complex signature once and using it in multiple functions.
- 3. **Smart Enums**: Generating Perl constants in your package.

## `coerce( $type, $value )`

Used primarily with [Variadic Functions](#variadic-functions-varargs). It wraps a value with type information so
Affix knows how to marshal it when no compile-time signature is available.

```
# Hint that we are passing a Float, not a Double
coerce( Float, 1.5 );
```

## `get_last_error_message( )`

Returns a string describing the most recent error that occurred during library loading or symbol lookup.

# Library Utilities

Locating libraries on different platforms can be tricky. These utilities help you load and manage dynamic libraries.

They are exported by default but may be imported specifically with the `:lib` tag.

## `load_library( $path )`

```perl
my $lib = load_library( 'user32.dll' );
```

Locates and loads a dynamic library, returning an opaque (`Affix::Lib`) handle.

If you pass a name without an extension (e.g., 'm'), Affix applies platform-specific prefixes/suffixes (e.g.,
'libm.so', 'libm.dylib', 'm.dll') and searches standard system paths.

## `locate_lib( $name, [$version] )`

```perl
my $path = locate_lib('ssl', '1.1');
```

Searches system paths (`LD_LIBRARY_PATH`, `PATH`, `DYLD_LIBRARY_PATH`, etc.) and returns the full absolute path to
the library file without loading it.

## `find_symbol( $lib, $name )`

Returns the raw memory address (as an integer) of a symbol. Useful if you need to pass a function pointer **value** to
C, rather than calling it.

## `libc()` / `libm()`

Helpers returning handles to the standard C library and math library.

# Memory Management

Affix uses **pins** to manage raw memory. A pin is a magical scalar reference holding a memory address and type
information.

## `malloc( $size )`

```perl
my $ptr = malloc( 1024 );
```

Allocates `$size` bytes of uninitialized memory. Returns a `Pointer[Void]` pin. Memory allocated this way is
**managed** by Perl (freed automatically when the pin goes out of scope).

## `calloc( $num, $size_or_type )`

```perl
my $array = calloc( 10, Int );
```

Allocates memory for an array of `$count` elements and initializes them to zero. You may pass a Type object (like
`Int`) or a raw size in bytes.

## `realloc( $ptr, $new_size )`

```
$ptr = realloc( $ptr, $new_size );
```

Resizes the memory pointed to by `$ptr`. Returns the new pointer (the original pin is updated automatically).

## `free( $ptr )`

```
free( $ptr );
```

Releases memory allocated by Affix.

**Note:** Only use this on memory allocated by `malloc`, `calloc`, or `strdup`. Do not attempt to free pointers
returned by C libraries unless the library documentation explicitly says you own that memory.

## `cast( $ptr, $type )`

```perl
my $void  = malloc(4);
my $int   = cast( $void, Int ); # Read immediate value
my $int_p = cast( $void, Pointer[Int] ); # Return new Pin
```

Reinterprets a pointer.

- **To value** (`Int`, etc.): Reads the memory immediately and returns a Perl scalar.
- **To reference** (`Pointer[Int]`): Returns a new pin aliasing the memory. Dereferencing it (`$$pin`) reads/writes the value.

## `own( $ptr, [$bool] )`

```
own( $ptr, $bool );
```

Controls lifecycle management of the pointer.

- `own($p, 1)`: Perl assumes ownership. `free()` will be called when `$p` goes out of scope.
- `own($p, 0)`: Perl releases ownership. `free()` is never called by Perl.

**Double free warning:** If you call `own($p, 1)` and then pass `$p` to a C function that _also_ frees that memory,
your program will crash. Only take ownership if you are sure the C library expects you to free the memory.

## `address( $ptr )`

Returns the virtual memory address of the pointer as a `UInt64`.

## Pointer Arithmetic & Utilities

- `ptr_add( $ptr, $offset )`

    Returns a new unmanaged pin offset by `$bytes`. If `$ptr` is an array type, it decays to a pointer type.

- `ptr_diff( $ptr1, $ptr2 )`

    Returns the difference in bytes (`$ptr1 - $ptr2`).

- `is_null( $ptr )`

    Returns true if the pointer is `NULL` (`0x0`).

- `strdup( $string )`

    Allocates memory and copies the Perl string (plus `NULL` terminator) into it.

- `strnlen( $ptr, $maxlen )`

    Safe string length calculation.

## Raw Memory Operatoins

Standard C memory operations are available for high-performance manipulation of pins.

- `memchr( $ptr, $ch, $count )`
- `memcmp( $lhs, $rhs, $count )`
- `memset( $dest, $ch, $count )`
- `memcpy( $dest, $src, $count )`
- `memmove( $dest, $src, $count )`

## `dump( $ptr, $length )`

Prints a hex dump of the memory at `$ptr` to `STDOUT`.

# Introspection

## `sizeof( $type )`

```perl
my $size = sizeof( Int );
my $size_rect = sizeof( Struct[ x => Int, y => Int ] );
```

Returns the size, in bytes, of a Type object.

## `offsetof( $struct_type, $field_name )`

```perl
my $struct = Struct[ name => String, age => Int ];
my $offset = offsetof( $struct, 'age' );
```

Returns the byte offset of a field within a Struct or Union.

## `alignof( $type )`

Returns the required alignment bytes for a Type.

## `types()`

Returns a list of all named types currently registered in the system.

# Types

Affix signatures are built using these helper functions

```perl
# Example Signature
[ Int, String ] => Void
```

## Primitive Types

Primitives map to native C types.

<div>
     <table border="1" cellpadding="4" cellspacing="0">
        <thead>
            <tr><th>Type</th><th>Description</th></tr>
        </thead>
        <tbody>
            <tr><td>Void</td><td>Returns nothing</td></tr>
            <tr><td>Bool</td><td>Mapped to Perl true/false</td></tr>
            <tr><td>Char</td><td>signed char (8-bit usually)</td></tr>
            <tr><td>UChar</td><td>unsigned char</td></tr>
            <tr><td>SChar</td><td>Explicitly signed char</td></tr>
            <tr><td>Short</td><td>signed short</td></tr>
            <tr><td>UShort</td><td>unsigned short</td></tr>
            <tr><td>Int</td><td>signed int (platform native, usually 32-bit)</td></tr>
            <tr><td>UInt</td><td>unsigned int</td></tr>
            <tr><td>Long</td><td>signed long (32-bit on Win64, 64-bit on Linux64)</td></tr>
            <tr><td>ULong</td><td>unsigned long</td></tr>
            <tr><td>LongLong</td><td>signed long long (guaranteed 64-bit)</td></tr>
            <tr><td>ULongLong</td><td>unsigned long long</td></tr>
            <tr><td>Float</td><td>32-bit float</td></tr>
            <tr><td>Double</td><td>64-bit float</td></tr>
            <tr><td>LongDouble</td><td>Platform specific (80-bit or 128-bit)</td></tr>
            <tr><td>Size_t</td><td>size_t</td></tr>
            <tr><td>SSize_t</td><td>ssize_t</td></tr>
        </tbody>
     </table>
</div>

### Explicit Width Types

For precise control, use these types which are guaranteed to have specific bit widths across all platforms:

```
Int8, UInt8
Int16, UInt16
Int32, UInt32
Int64, UInt64
Int128, UInt128 (Passed as Decimal Strings)
```

128-bit integers, if supported by the compiler, must be passed as strings to/from Perl.

## Pointers

Pointers are the glue of C. Affix provides distinct ways to handle them based on intent.

- Basic Pointers (`Pointer[Type]`)

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

- Strings (`String` vs `Pointer[Char]`)
    - **`String`**: Use this for `const char*` (input strings). Affix copies the Perl string to a temporary C buffer.
    - **`Pointer[Char]`**: Use this for mutable strings `char*`. You must ensure the scalar passed has enough pre-allocated capacity (e.g. using `"\0" x 1024`).
- Void Pointers (`Pointer[Void]`)

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

Maps to Perl hash references with a single key.

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

- 1. **Array References**: Simplest to read and write.
- 2. **Packed Strings**: Highest performance (avoids marshalling overhead).

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

# Utilities

## `errno()`

```perl
my $err = errno();
die "Error $err: " . int($err);
```

Access the `errno` (Linux/Unix) or `GetLastError` (Windows) from the most recent FFI call. This must be called
immediately after the function invokes to ensure accuracy.

The return value is a **dualvar**:

- **Numeric context**: Returns the integer error code.
- **String context**: Returns the human-readable system error message (via `strerror` or `FormatMessage`).

## `sv_dump( $sv )`

Dumps the internal flags and structure of a Perl `SV`.

# Thread Safety & Concurrency

Affix bridges Perl (a single-threaded interpreter, generally) with libraries that may be multi-threaded. This creates
potential hazards that you must manage.

## 1. Initialization Phase vs. Execution Phase

Functions that modify Affix's global state are **not thread-safe**. You must perform all definitions in the main thread
before starting any background threads or loops in the library.

Unsafe operations that you should never call from Callbacks or in a threaded context:

- `affix( ... )` - Binding new functions.
- `typedef( ... )` - Registering new types.

## 2. Callbacks

When passing a Perl subroutine as a `Callback`, avoid performing complex Perl operations like loading modules or
defining subs inside callback triggered on a foreign thread. Such callbacks should remain simple: process data, update
a shared variable, and return.

If the library executes the callback from a background thread (e.g., window managers, audio callbacks), Affix attempts
to attach a temporary Perl context to that thread. This should be sufficient but Perl is gonna be Perl.

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

Copyright (C) 2023-2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
