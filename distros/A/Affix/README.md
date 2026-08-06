# NAME

Affix - A Foreign Function Interface eXtension

# SYNOPSIS

```perl
use v5.40;
use Affix qw[:all];

# Bind a function and call it natively.
# Here, we use libm which might be in libm.so, msvcrt.dll, etc.
# C: double pow(double x, double y);
affix libm(), 'pow', [ Double, Double ] => Double;
say pow( 2.0, 10.0 ); # 1024

# Working with C structs is easy
# C: typedef struct { int x; int y; } Point;
#    void draw_point(Point p);
typedef Point => Struct[ x => Int, y => Int ];
affix $lib, 'draw_point', [ Point() ] => Void;
draw_point( { x => 10, y => 20 } );
affix $lib, 'get_pos', [] => Point();
my $pt = get_pos();
say sprintf 'x: %d, y: %d', $pt->{x}, $pt->{y};

# We can also allocate and manage raw memory and write data to it
my $ptr = Affix::malloc(1024);
$ptr->[0] = ord('t'); # Direct byte-level access
memcpy( $ptr, 'test', 4 );

# We can also do pointer arithmetic to create new references
my $offset_ptr = Affix::ptr_add( $ptr, 12 );
memcpy( $offset_ptr, 'test', 4 );

# Inspect memory with a hex dump to STDOUT
Affix::dump( $ptr, 32 );

# And release the memory. This is automatic when such a scalar falls out of scope
Affix::free($ptr);
```

# DESCRIPTION

Call native code from Perl without XS, compilers, or runtime overhead.

Affix is a high-performance Foreign Function Interface (FFI) for Perl. It bridges Perl to C, Rust, Zig, C++, Go,
Fortran, and more via JIT-compiled trampolines that handle argument marshalling at runtime. No generic dispatch loops
here. The result is near-native call speed with a rich type system covering primitives, structs, unions, enums, SIMD
vectors, and pointers.

Powered by [infix](https://github.com/sanko/infix/), which has been tested on Linux, Windows, macOS, Solaris, BSD, and
across x86\_64, ARM64, and RISC-V.

# EXPORTS

Import types and functions with built-in tags. By default, Affix exports standard types (`Int`, `Double`, etc.) and
core functions (`affix`, `wrap`, `load_library`).

Control what gets imported:

```perl
use Affix qw[:all];    # Import everything
use Affix qw[:lib];    # Library helpers (libc, libm, load_library...)
use Affix qw[:memory]; # malloc, free, memcpy, cast, dump, raw, snapshot, pin, unpin...
use Affix qw[:types];  # Types only (Int, Struct, Pointer...)
```

# CORE API

Bind functions to Perl subroutines and define custom types. These are the primary entry points for interacting with
foreign libraries.

## `affix( $lib, $symbol, $params, $return )`

Attaches a symbol from a library to a named Perl subroutine in the current namespace.

- **`$lib`**: A library handle returned by `load_library`, a string name, or `undef` to search the currently running process/executable.
- **`$symbol`**: The name of the C function. To install it under a different name in Perl, pass an array reference: `['c_name', 'perl_alias']`. To bind a raw memory address, pass it directly: `[$ptr, 'perl_alias']`.
- **`$params`**: An `ArrayRef` of Affix Type objects representing the function's arguments.
- **`$return`**: A single Affix Type object representing the return value.

```perl
# Standard: Load from library
affix $lib, 'pow', [ Double, Double ] => Double;

# Rename: Load 'pow', install as 'power' in Perl
affix $lib, [ pow => 'power' ], [ Double, Double ] => Double;

# Raw pointer: Bind a specific memory address (e.g., from dlsym or JIT)
affix undef,[ $ptr => 'my_func' ], [Int] => Void;
```

On success, installs the subroutine and returns the generated code reference.

## `wrap( $lib, $symbol, $params, $return )`

Creates a wrapper around a given symbol and returns it as an anonymous `CODE` reference. Arguments are identical to
`affix` except you cannot provide an alias.

```perl
my $pow = wrap $lib, 'pow', [ Double, Double ] => Double;
my $result = $pow->( 2, 5 );
```

## `typedef( $name => $type )`

Registers a named type alias. This makes signatures more readable and is required for recursive types and smart Enums.

```perl
# C: typedef struct { int x; int y; } Point;
typedef Point => Struct[ x => Int, y => Int ];

# C: typedef double Vector3[3];
typedef Vector3 => Array[ Double, 3 ];

# C: typedef int* IntPtr;
typedef IntPtr => Pointer[ Int ];
```

Once registered, use these types in signatures by calling them as functions: `Point()`.

## `coerce( $type, $value )`

Explicitly hints types for [Variadic Functions](#variadic-functions-varargs).

```
# Hint that we are passing a Float, not a Double
coerce( Float, 1.5 );
```

# VARIABLES & PINNING

Bind Perl scalars directly to C global variables for real-time, two-way access to C memory.

## `pin( ... )`

Binds a scalar to a C variable. Reading the scalar reads C memory; writing to it updates C memory immediately. Three
calling conventions are supported:

- **pin( $var, $lib, $symbol, $type )**

    Binds to an exported symbol. This is the most common form.

    ```perl
    # C: extern int errno;
    my $errno;
    pin $errno, libc(), 'errno', Int;

    $errno = 0;   # Writes directly to C memory
    ```

- **pin( $var, $address, $type )**

    Binds to a raw memory address (e.g., from `find_symbol` or pointer arithmetic).

    ```perl
    my $addr = address($some_ptr);
    pin my $val, $addr, Int;
    ```

- **pin( $var, $existing\_pin )**

    Clones the binding from an existing pin (copies the address and type).

    ```perl
    pin my $copy, $original_pin;
    ```

## `unpin( $var )`

Removes the magic applied by `pin`. The variable retains its last value but is no longer linked to C memory.

# TYPE SYSTEM

Map C types to Perl with a rich, built-in vocabulary. Affix signatures are built using helper functions that map
precisely to C types. These are exported by default, or can be imported explicitly using the `:types` tag.

## Primitive Types

### Void & Booleans

- `Void`: Used for functions that return nothing (`void`).
- `Bool`: Mapped to Perl's true/false values (`stdbool.h` / `_Bool`).

### Characters

- `Char`: Standard signed `char` (usually 8-bit).
- `SChar`: Explicitly signed `signed char`.
- `UChar`: Unsigned `unsigned char`.
- `WChar`: Wide character (`wchar_t`), usually 16-bit on Windows and 32-bit on Linux/macOS.
- `Char8`, `Char16`, `Char32`: Explicit-width C++ character types (`char8_t`, etc.).

### Platform-Native Integers

These types map to the system's native bit-widths (e.g., `Long` is 32-bit on Windows x64, but 64-bit on Linux x64).

- `Short` / `UShort`: `short` / `unsigned short`.
- `Int` / `UInt`: `int` / `unsigned int` (typically 32-bit).
- `Long` / `ULong`: `long` / `unsigned long`.
- `LongLong` / `ULongLong`: `long long` / `unsigned long long` (guaranteed at least 64-bit).
- `Size_t` / `SSize_t`: Standard memory and array indexing types (`size_t`, `ssize_t`).

### Fixed-Width Integers

Use these when a C library explicitly requests a `stdint.h` type.

- `Int8` / `SInt8` / `UInt8`: 8-bit integers (`int8_t`, `uint8_t`).
- `Int16` / `SInt16` / `UInt16`: 16-bit integers (`int16_t`, `uint16_t`).
- `Int32` / `SInt32` / `UInt32`: 32-bit integers (`int32_t`, `uint32_t`).
- `Int64` / `SInt64` / `UInt64`: 64-bit integers (`int64_t`, `uint64_t`).
- `Int128` / `SInt128` / `UInt128`: 128-bit integers. _Note: Because standard Perl scalars cannot hold 128-bit numbers natively, these must be passed to/from Affix as decimal strings._

### Floating Point

- `Float16`: Half-precision 16-bit float (IEEE 754).
- `Float` / `Float32`: Standard 32-bit `float`.
- `Double` / `Float64`: Standard 64-bit `double`.
- `LongDouble`: Platform-specific extended precision (typically 80-bit on x86 or 128-bit).

### Complex Numbers

- `Complex[ $type ]`: C99 complex numbers (e.g., `Complex[Double]`). In Perl, these map to an `ArrayRef` of two numbers: `[ $real, $imaginary ]`.

## String Types

- **`String`**: Maps to `const char*`. Affix handles UTF-8 encoding (Perl to C) and decoding (C to Perl) automatically.
- **`WString`**: Maps to `const wchar_t*`. Affix automatically handles UTF-16/UTF-32 conversions, including Windows Surrogate Pairs.
- **`StringList`**: Maps a Perl `ArrayRef` of strings to a null-terminated `char**` array (common in C APIs like `execve` or `main(argc, argv)`).
- **`Buffer`**: Maps a mutable `char*` to the raw memory buffer of a Perl scalar. **Zero-copy**. The scalar must have pre-allocated capacity (e.g., `"\0" x 1024`).

## Pointer & Reference Types

### `Pointer[ $type ]`

A pointer to another type. Affix wraps pointers in magical Perl scalar references that read and write C memory directly
via the `$$` dereference operator.

#### Reading

Dereferencing reads the value from C memory:

```perl
affix $lib, 'get_ptr', [] => Pointer[Int];
my $ptr = get_ptr();
say $$ptr;  # Reads the int value from C memory
```

#### Writing

Assigning through the dereference writes directly to C memory:

```
$$ptr = 42;  # Writes 42 to the C memory address
```

This works for deep pointer chains as well:

```perl
# int*** ptr; ***ptr = 5;
my $ppp = cast( $mem, Pointer[ Pointer[ Pointer[Int] ] ] );
$$ppp = $pp_val;  # Writes the pointer address through the chain
```

#### Passing Scalars as Pointers

When a function expects a `Pointer[$type]` argument, pass a **scalar reference** (`\$var`) to send the address of a
Perl scalar. Affix automatically handles the marshalling:

```perl
# C: int deref_and_add(int* p);
affix $lib, 'deref_and_add', [ Pointer[Int] ] => Int;

my $val = 50;
is deref_and_add( \$val ), 60;  # Passes address of $val as int*

# C: void modify_int_ptr(int* p, int new_val);
affix $lib, 'modify_int_ptr', [ Pointer[Int], Int ] => Void;
modify_int_ptr( \$val, 999 );
say $val;  # 1000; C function wrote through the pointer
```

#### Array Indexing

Pointers to arrays support direct element access via array subscript syntax. Reads and writes go directly to C memory:

```perl
affix $lib, 'get_array_ptr', [] => Pointer[ Array[ Int, 4 ] ];
my $arr = get_array_ptr();
say $arr->[0];   # Read first element from C memory
$arr->[2] = 99;  # Write third element in C memory
```

To take a deep copy (snapshot), dereference into an anonymous array ref:

```perl
my $snapshot = [@$arr];
$snapshot->[0] = 100;  # Modifying snapshot does NOT affect C memory
```

#### Void Pointers

If `$type` is `Void`, the pointer is "terminal." Dereferencing it will return `undef`. In this case, use `cast()`
or `address()` to work with the raw memory address.

### Specialized Pointers

- **`File`** / **`PerlIO`**: Maps Perl filehandles (Globs or IO objects) to `FILE*` or `PerlIO*`. **Must** be wrapped in a pointer: `Pointer[File]`.
- **`SockAddr`**: Specialized marshalling for packed socket strings (e.g., from `Socket::pack_sockaddr_in`) to `struct sockaddr*`.
- **`SV`**: Direct, low-level access to Perl's internal Interpreter Object (`SV*`). **Must** be wrapped in a pointer: `Pointer[SV]`.

## Aggregate Types

### `Struct[ @members ]`

A C struct, mapped to a Perl `HashRef`.

```perl
# C: typedef struct { int x; int y; } Point;
typedef Point => Struct[ x => Int, y => Int ];
```

### `Union[ @members ]`

A C union, mapped to a Perl `HashRef` with exactly one key.

```perl
# C: union { int key_code; float pressure; };
typedef Event => Union[ key_code => Int, pressure => Float ];
```

### `Packed[ $aggregate ]` / `Packed[ $align, $aggregate ]`

Forces specific byte alignment on a Struct or Union (e.g., `#pragma pack(1)`).

```perl
# Without explicit alignment (default):
Packed[ Struct[ flag => Char, data => Int ] ];

# With explicit alignment (e.g., #pragma pack(push, 1)):
Packed( 1, Struct[ flag => Char, data => Int ] );
```

### `Array[ $type, $count ]`

A fixed-size C array. Maps to a Perl `ArrayRef`.

```perl
# C: double Vector3[3];
typedef Vector3 => Array[ Double, 3 ];
```

### Bitfields

Specify bit widths using the pipe (`|`) operator within Structs/Unions. Affix handles all masking and shifting.

```perl
# C: typedef struct { uint32_t a : 1; uint32_t b : 3; } Config;
typedef Config => Struct[ a => UInt32 | 1, b => UInt32 | 3 ];
```

## Live Views (Zero-Copy Aggregates)

In Affix, memory structures are live by design. When C returns a pointer to an aggregate (Struct, Union, or Array), or
when you use `cast()` to overlay a type onto a memory address, Affix does not copy the data.

Instead, it returns a magical Perl reference (blessed into `Affix::Pointer`) mapped directly to the C memory via Perl
VTables. This means zero-copy performance without the overhead of `tie`.

Modifying keys or elements in these structures updates C memory immediately, and reading them reads directly from the C
heap.

```perl
# Example: Live view of a struct
my $live = cast( $ptr, Struct[ x => Int, y => Int ] );
$live->{x} = 42; # Updates C memory
```

### Unified Access

Magical `Affix::Pointer` references allow direct field access (`$p->{field}`) without explicit casting.

```perl
affix $lib, 'get_ptr', [] => Pointer[Point];
my $p = get_ptr();
say $p->{x};  # Unified access! Reads directly from C memory.
$p->{y} = 50; # Writes directly to C memory.
```

## Callbacks & Functions

- **`Callback[ [$params] => $ret ]`**: Defines the signature of a C function pointer. Allows you to pass Perl subroutines into C functions.

    ```perl
    # C: void set_handler( void (*cb)(int) );
    affix $lib, 'set_handler', [ Callback[ [Int] => Void ] ] => Void;
    ```

- **`ThisCall( $cb_or_sig )`**: Helper for C++-style `__thiscall` callbacks. Prepends a `Pointer[Void]` (the `this` pointer) to the signature.

## Variadic Functions (VarArgs)

Affix supports C functions that take a variable number of arguments (e.g., `printf`, `ioctl`). When defining a
signature, use the `VarArgs` token at the end of the argument list.

### Basic Usage

```perl
# C: int printf(const char* format, ...);
affix libc(), ['printf' => 'my_printf'], [ String, VarArgs ] => Int;

# Basic types are marshalled automatically based on Perl's internal state
my_printf("Integer: %d, String: %s\n", 42, "Hello");
```

### Explicit Type Control with `coerce()`

In variadic functions, C relies on the caller to pass data in the exact format the function expects. While Affix
attempts to guess the correct C type for Perl scalars, these guesses might not always match the library's expectations
like passing a 64-bit integer where a 32-bit one is expected, or a float instead of a double.

Use `coerce( $type, $value )` to explicitly tell Affix how to marshal a variadic argument.

```perl
# Suppose we have a variadic log function that expects specific bit-widths
# C: void custom_log(int level, ...);
affix $lib, 'custom_log', [ Int, VarArgs ] => Void;

custom_log(
    1,
    coerce(Short, 10),    # Explicitly pass as a 16-bit signed int
    coerce(Float, 1.5),    # Explicitly pass as a 32-bit float
    coerce(ULong, 1000)    # Explicitly pass as a platform-native unsigned long
);
```

Note: Standard C default argument promotions still apply. For example, passing a `Float` to a variadic function will
typically be promoted to a `Double` by the C runtime unless the receiving function specifically handles raw floats.

## Enumerations

```perl
# C: enum Status { OK = 0, ERROR = 1, FLAG_A = 1<<0, FLAG_B = 1<<1 };
typedef Status => Enum[
    [ OK => 0 ],
    'ERROR',                    # Auto-increments to 1
    [ FLAG_A => 1 << 0 ],       # Bit shifting
    [ FLAG_B => '1 << 1' ]      # String expression
];
```

- **Constants:** `typedef` installs constants (e.g., `OK() == 0`) into your package.
- **Dualvars:** Values returned from C act as dualvars. They print as strings (`"OK"`) but evaluate mathematically as integers (`0`).
- **String Marshalling:** You can pass the string name of an element (`"OK"`) directly to functions that expect
that enum type.
- **Aliases:** You can also use `IntEnum[ ... ]`, `CharEnum[ ... ]`, and `UIntEnum[ ... ]` to force the underlying integer size.

## SIMD Vectors

Vectors are first-class types. You can interact with them using standard **ArrayRefs** (convenient) or **Packed Strings**
(high-performance, zero-overhead).

- **`Vector[ $size, $type ]`**: Create a custom vector (e.g., `Vector[ 4, Float ]`).
- **Aliases**: `M256`, `M256d`, `M512`, `M512d`, `M512i`.

```perl
# C: __m256 add_vecs(__m256 a, __m256 b);
affix $lib, 'add_vecs', [ M256, M256 ] => M256;
my $v1 = pack('f8', 1..8);
my $v2 = pack('f8', 10, 20, 30, 40, 50, 60, 70, 80);
my $packed_res = add_vecs( $v1, $v2 );
```

# MEMORY MANAGEMENT

Allocate, cast, and manage C memory safely from Perl using zero-copy VTable magic. When bridging Perl and C, handling
raw memory safely is critical. Affix uses **Pins** to manage this boundary.

Affix now features a completely reimagined memory access system using Perl's internal magic to map Perl variables
directly to native C memory. This provides zero-copy performance with the ergonomics of native Perl Hashes and Arrays.

## Managed vs. Unmanaged Memory

Memory in Affix is handled by life lines.

- **Affix::Memory:** Created via `malloc()` or `calloc()`. These are root objects. When the Perl variable is destroyed, `safefree()` is called automatically.
- **Pins:** Created via `cast()` or pointer dereferencing. These variables do not own the memory, but they hold a reference to a life line to prevent the parent memory from being freed prematurely.

## Allocation & Deallocation

These functions allocate memory on the C heap. Memory allocated via these functions is **managed by Perl** by default.

### `malloc( $size )`

Allocates `$size` bytes of uninitialized memory. Returns a `Pointer[Void]` pin.

```perl
my $ptr = malloc(1024); # Allocates 1KB
```

### `calloc( $count, $size )`

Allocates zero-initialized memory for `$count` elements of `$size`. Returns a `Pointer[Void]` pin.

```perl
my $ptr = calloc( 10, sizeof(Int) );
my $arr = cast( $ptr, Array[Int, 10] );
```

### `realloc( $ptr, $new_size )`

Resizes the memory area pointed to by `$ptr` to `$new_size` bytes. The original pin is updated automatically
in-place.

```
$ptr = realloc( $ptr, 2048 );
```

### `strdup( $string )`

Allocates managed memory and copies the Perl string (along with a `NULL` terminator) into it. Returns a managed
`Pointer[Char]` pin.

```perl
my $str_ptr = strdup("Hello C!");
```

### `free( $ptr )`

Manually releases memory.

**Warning:** Only use this on memory that you exclusively own (e.g., allocated via `malloc`). Do not call `free` on
unmanaged pointers returned by C libraries unless the library explicitly transfers ownership to you, or you will cause
a segmentation fault.

```
free($ptr);
```

### `own( $pin )`

Returns true if the given pin is an owned `Affix::Memory` object (i.e., memory allocated via `malloc` or `calloc`
that Perl manages directly). Returns false for unmanaged pins or raw scalars.

```
if (own($ptr)) {
    say "Perl owns this memory; it will be freed automatically.";
}
```

### `is_pin( $var )`

Returns true if the variable is currently bound to C memory via `pin`, `cast`, or pointer dereferencing. Returns
false for ordinary Perl scalars.

```perl
my $x = 42;
say is_pin($x); # false

pin $x, libc(), 'errno', Int;
say is_pin($x); # true
```

## Lifecycle & Ownership

### `attach_destructor( $pin, $func_ptr, [$lib] )`

Attaches a custom C function to be called when the Pin is destroyed. This is incredibly useful for C libraries that
require specific cleanup routines (e.g., `SDL_DestroyWindow`, `sqlite3_free`).

```perl
# Find the address of the library's custom free function
my $free_func = find_symbol($my_lib, 'custom_free');

# When $ptr goes out of scope, Affix will call custom_free($ptr)
attach_destructor($ptr, $free_func, $my_lib);
```

### `readonly( $pin, [$bool] )`

Gets or sets the "const" status of a memory pin. If set to true, any attempt to write to that memory from Perl will
throw an exception.

```
readonly($point, 1);
$point->{x} = 20; # CRASH: Modification of a read-only C value
```

## Type Casting

### `cast( $ptr, $type )`

The most powerful tool in the memory kit. It "overlays" a C type definition onto a raw memory address.

```perl
my $mem = malloc(16);
my $point = cast($mem, Struct[ x => Int, y => Int ]);
$point->{x} = 10;
```

# POINTER UTILITIES

Navigate and inspect raw pointers with helper functions for address arithmetic, null checks, and more.

### `address( $ptr )`

Returns the virtual memory address of the pointer as a Perl Unsigned Integer (`UInt64`). Useful for passing addresses
to other FFI libraries or debugging.

```
say sprintf("Address: 0x%X", address($ptr));
```

### `ptr_add( $ptr, $offset_bytes )`

Returns a new **unmanaged alias Pin** offset by `$offset_bytes`.

```perl
my $int_arr   = calloc(10, Int);
my $next_elem = ptr_add($int_arr, sizeof(Int));
```

_Note: If `$ptr` is an Array type, `ptr_add` correctly decays the returned pin into a Pointer to the element type._

### `ptr_diff( $ptr1, $ptr2 )`

Returns the byte difference (`$ptr1 - $ptr2`) between two pointers as an integer.

### `is_null( $ptr )`

Returns true if the address is `NULL` (`0x0`).

### `strnlen( $ptr, $max )`

Safe string length calculation. Checks the pointer for a `NULL` terminator, scanning at most `$max` bytes.

### `raw( $ptr, $length_in_bytes )`

Returns a Perl string containing the raw, un-decoded binary data extracted directly from the memory address. This is
the programmatic, binary equivalent of `dump()`.

### `snapshot( $pin )`

Deeply reads the C memory backing a Pin and returns a pure, non-magical native Perl data structure (ArrayRef, HashRef,
or Scalar). Because it does not apply VTable magic to the returned values, reading elements from the returned structure
in a bulk operation (like summing a 10,000 element array) is exceptionally fast.

# Raw Memory Operations

Classic C memory functions (memcpy, memset, etc.) available directly from Perl for high-performance byte manipulation.
These functions accept either Pins or raw integer addresses.

- `memcpy( $dest, $src, $bytes )`: Copies exactly `$bytes` from `$src` to `$dest`.
- `memmove( $dest, $src, $bytes )`: Copies `$bytes` from `$src` to `$dest`. Safe to use if the memory regions overlap.
- `memset( $ptr, $byte_val, $bytes )`: Fills the first `$bytes` of the memory block with the value `$byte_val`.
- `memcmp( $ptr1, $ptr2, $bytes )`: Compares the first `$bytes` of two memory blocks. Returns an integer less than, equal to, or greater than zero.
- `memchr( $ptr, $byte_val, $bytes )`: Locates the first occurrence of `$byte_val` within the first `$bytes` of the memory block. Returns a new Pin pointing to the match, or `undef`.

# `Const` & Readonly Memory

Enforce C's const contract at the Perl level. Affix intercepts writes to read-only memory and throws a fatal exception:
`Modification of a read-only C value attempted`.

## Declarative Const: `Const[ $type ]`

You can wrap any type in `Const[ ... ]` within a signature.

```perl
# C: void process(const char* name, const int* values);
affix $lib, 'process', [ Const[String], Pointer[ Const[Int] ] ] => Void;
```

## Imperative Const: `readonly( $pin, [$bool] )`

The `readonly()` function allows you to inspect or toggle the const status of a Pin or Aggregate at runtime. This acts
as an _FFI Escape Hatch_ (similar to `const_cast` in C++).

```perl
my $point = cast($addr, Struct[ x => Int, y => Int ]);

readonly($point, 1); # Lock the entire struct
$point->{x} = 10;    # FATAL ERROR
```

## Recursive Protection

When an aggregate (Struct or Array) is marked as read-only, Affix automatically propagates that protection to all of
its members.

```perl
my $rect = cast($addr, Const[Struct[top => Struct[ x => Int, y => Int ], bottom => Struct[ x => Int, y => Int ] ]]);

# Even though 'x' wasn't explicitly marked Const, it inherited protection
# from the parent struct.
$rect->{top}{x} = 5; # FATAL ERROR
```

## Casting with Const

When using `cast( ... )`, you can prepend a `+` to the type signature to create an immutable view of a raw memory
address.

```perl
my $view = cast($raw_addr, Const[MyStruct]);
# $view is now a read-only HashRef mapping to C memory.
```

# Zero-copy Aggregates

Structs, unions, and arrays map directly to C memory—no deep copies required. When C returns a pointer to an
aggregate, Affix wraps it in a magical Perl reference that reads and writes C memory in real time.

### Native Array Indexing

C Arrays are traversed using standard Perl array syntax.

```perl
typedef Task => Struct[ id => Int, name => String ];
affix $lib, 'get_tasks', [] => Pointer[ Array[ Task(), 10 ] ];

my $tasks = get_tasks();
$tasks->[5]{id} = 404; # Writes directly to C memory!
```

### Deep Null Safety

Traversing a \`NULL\` pointer in C causes a segfault. Affix wraps C memory in Perl safety rails. If you try to traverse a
\`NULL\` pointer inside a struct, Affix intercepts it and throws a standard Perl exception (`Can't use an undefined
value as a HASH reference`).

# LIBRARIES & SYMBOLS

Load and inspect dynamic libraries across platforms. Affix's smart discovery engine handles varying extensions,
prefixes, and search paths automatically.

## Library Discovery

When you provide a bare library name (e.g., `'z'`, `'ssl'`, `'user32'`) rather than an absolute path, Affix
automatically formats the name for the current platform (e.g., `libz.so`, `libz.dylib`, `z.dll`) and searches the
following locations in order:

- 1. **Standard System Paths:** Windows `System32`/`SysWOW64`; Unix `/usr/local/lib`, `/usr/lib`, `/lib`, `/usr/lib/system`.
- 2. **Environment Variables:** Paths defined in `LD_LIBRARY_PATH`, `DYLD_LIBRARY_PATH`, `DYLD_FALLBACK_LIBRARY_PATH`, or `PATH`.
- 3. **Local Paths:** The current working directory (`.`) and its `lib/` subdirectory.

## Functions

### `load_library( $path_or_name )`

Locates and loads a dynamic library into memory, returning an opaque `Affix::Lib` handle.

```perl
my $lib = load_library('sqlite3');
```

**Lifecycle:** Library handles are thread-safe and internally reference-counted. The underlying OS library is only
closed (e.g., via `dlclose` or `FreeLibrary`) when all Affix wrappers and pins relying on it are destroyed.

_Note:_ When using `affix()` or `wrap()`, you can safely pass the string name directly (e.g., `affix('sqlite3',
...)`) and Affix will call `load_library` for you internally. If you pass `undef` instead of a library name, Affix
will search the currently running executable process.

### `locate_lib( $name, [$version] )`

Searches for a library using Affix's discovery engine and returns its absolute file path as a string. It **does not**
load the library into memory. This is useful if you need to pass the library path to another tool or check for its
existence.

```perl
# Find libssl.so.1.1 or libssl.1.1.dylib
my $path = locate_lib('ssl', '1.1');
say "Found SSL at: $path" if $path;
```

### `find_symbol( $lib_handle, $symbol_name )`

Looks up an exported symbol (function or global variable) inside an already-loaded `Affix::Lib` handle. Returns an
unmanaged `Affix::Pointer` (Pin) of type `Pointer[Void]` pointing to the memory address of the symbol.

```perl
my $lib = load_library('m');

# Get the raw memory address of the 'pow' function
my $pow_ptr = find_symbol($lib, 'pow');

if ($pow_ptr) {
    say sprintf("pow() is located at: 0x%X", address($pow_ptr));
}
```

Returns `undef` if the symbol cannot be found.

### `libc()` and `libm()`

Helper functions that locate and return the file paths to the standard C library and the standard math library for the
current platform. Because platform implementations differ wildly (e.g., MSVCRT on Windows, glibc on Linux, libSystem on
macOS), using these helpers guarantees you get the correct library.

```perl
# Bind 'puts' from the standard C library
affix libc(), 'puts', [String] => Int;

# Bind 'cos' from the math library
affix libm(), 'cos', [Double] => Double;
```

### `get_last_error_message()`

If `load_library`, `find_symbol`, or a signature parsing step fails, this function returns a string describing the
most recent internal or operating system error (via `dlerror` or `FormatMessage`).

```perl
my $lib = load_library('does_not_exist');
if (!$lib) {
    die "Failed to load library: " . get_last_error_message();
}
```

# INTROSPECTION

Query type sizes, alignments, and field offsets like a compiler would. When working with C APIs, you often need to know
exactly how much memory a structure consumes or where a specific field is located within a block of memory.

### `sizeof( $type )`

Returns the size, in bytes, of any Affix Type object or registered `typedef` name.

```
# C: sizeof(int);
say sizeof( Int ); # 4 (usually)

# C: sizeof(Point);
say sizeof( Point() ); # 8
```

### `alignof( $type )`

Returns the alignment boundary (in bytes) required by the C ABI for the given type.

```perl
say alignof( Int64 ); # 8 (usually)

# Struct alignment is dictated by its largest member
typedef Mixed => Struct[ a => Char, b => Double ];
say alignof( Mixed() ); # 8
```

### `offsetof( $struct_or_union, $field_name )`

Returns the byte offset of a named field within an Aggregate type (Struct or Union). This is incredibly useful for
manual pointer arithmetic.

```perl
typedef Rect => Struct[ x => Int, y => Int, w => Int, h => Int ];

# C: offsetof(Rect, w);
say offsetof( Rect(), 'w' ); # 8 (skips x and y, 4 bytes each)
```

### `types()`

Returns a list of all custom type names currently registered in Affix's global type registry via `typedef`. In scalar
context, returns the total number of registered types.

```perl
my @known_types = types();
say "Registered types: " . join(', ', @known_types);
```

# INTERFACING WITH OTHER LANGUAGES

Guidelines for calling into C++, Rust, Fortran, Go, and Assembly from Affix. Because Affix dynamically loads symbols
according to the C ABI, it can interact with libraries written in almost any language, provided they expose their
functions correctly. Companion modules like [Affix::Build](https://metacpan.org/pod/Affix%3A%3ABuild) make compiling these languages seamless.

Here are the requirements and quirks for interfacing with non-C languages.

## C++

C++ uses "name mangling" to support function overloading and namespaces, which alters the final symbol name inside the
compiled library.

- 1. **Prevent Mangling:** Wrap your exported functions in `extern "C"` to ensure they have predictable names.

    ```
    extern "C" {
        int add(int a, int b) { return a + b; }
    }
    ```

- 2. **Or Use Mangled Names:** If you cannot change the C++ source, you must look up the exact mangled name (e.g., `_Z3addii`) using tools like `nm` or `objdump`, and bind to that.
- 3. **Object Methods:** Calling an object's method requires passing the object instance pointer (the `this` pointer) as the first argument. Use the `ThisCall( ... )` wrapper around your callback/signature to automatically insert `Pointer[Void]` at the start of the argument list.

## Rust

Rust does not use the C ABI by default. You must explicitly instruct the compiler to format the function correctly.

- 1. **Exporting:** Use `#[no_mangle]` and `pub extern "C"`.

    ```rust
    #[no_mangle]
    pub extern "C" fn add(a: i32, b: i32) -> i32 { a + b }
    ```

- 2. **Structs:** Rust structs must be annotated with `#[repr(C)]` to guarantee their memory layout matches C (and thus Affix's `Struct`).
- 3. **Strings:** Rust strings are not null-terminated. You must receive `String` arguments as `*const std::os::raw::c_char` and convert them using `CStr::from_ptr`.

## Fortran

Fortran relies heavily on pass-by-reference.

- 1. **Pointers Everywhere:** Unless a parameter uses the modern Fortran `VALUE` attribute, you must pass everything as a pointer. If the function expects a Float, your Affix signature must be `Pointer[Float]`.
- 2. **Name Mangling:** Most Fortran compilers convert subroutine names to lowercase and append an underscore. A Fortran subroutine named `CALC_STRESS` will likely be exported as `calc_stress_`.
- 3. **Strings:** Fortran does not use null-terminated strings. When passing character arrays, Fortran compilers silently append hidden "length" parameters at the **end** of the argument list (passed by value as integers).

## Assembly

When writing raw Assembly (NASM/GAS), you must manually adhere to the calling convention of your target platform:

- **Linux/macOS (System V AMD64 ABI):** Arguments are passed in `rdi, rsi, rdx, rcx, r8, r9`, with the rest on the stack.
- **Windows (Microsoft x64):** Arguments are passed in `rcx, rdx, r8, r9`, with "shadow space" reserved on the stack.

## Go

Go libraries can be loaded if they are compiled with `-buildmode=c-shared`. Note that Go slices and strings contain
internal metadata (length/capacity) and do not map directly to C arrays or `char*`. Use the `C` package inside Go
(`import "C"`) and `*C.char` to bridge the boundary.

# ERROR HANDLING & DEBUGGING

Diagnose FFI issues with built-in error reporting, memory inspection, and hex dumps. Bridging two entirely different
runtimes can lead to spectacular crashes if types or memory boundaries are mismatched.

## Error Handling

### `errno()`

Accesses the system error code from the most recent FFI or standard library call (reads `errno` on Unix and
`GetLastError` on Windows).

This function returns a **dualvar**. It behaves as an integer in numeric context, and magically resolves to the
human-readable system error message (via `strerror` or `FormatMessage`) in string context.

```perl
# Suppose a C file-open function fails
my $fd = c_open("/does/not/exist");
if (!$fd) {
    my $err = errno();

    # String context
    say "Failed to open: $err"; # "No such file or directory"

    # Numeric context
    if (int($err) == 2) {
        say "Code 2 specifically triggered.";
    }
}
```

**Note:** You must call `errno()` immediately after the C function invokes, as subsequent Perl operations (like
printing to STDOUT) might overwrite the system's error register.

## Memory Inspection

### `dump( $pin, $length_in_bytes )`

Prints a formatted hex dump of the memory pointed to by a Pin directly to `STDOUT`. This is an invaluable tool for
verifying that C structs or buffers contain the data you expect.

```perl
my $ptr = strdup("Affix Debugging");
dump($ptr, 16);

# Output:
# Dumping 16 bytes from 0x55E9A8A5 at script.pl line 42
#  000  41 66 66 69 78 20 44 65 62 75 67 67 69 6e 67 00 | Affix Debugging.
```

### `sv_dump( $scalar )`

Dumps Perl's internal interpreter structure (SV) for a given scalar to `STDOUT`. This exposes the raw flags, reference
counts, and memory layout of the Perl variable itself.

```perl
my $val = 42;
sv_dump($val);
# Exposes IV flags, memory addresses of the SV head, etc.
```

## Advanced Debugging

### `set_destruct_level( $level )`

Sets the internal `PL_perl_destruct_level` variable.

When testing XS/FFI code for memory leaks using tools like Valgrind or AddressSanitizer, you often want Perl to
meticulously clean up all global memory during its destruction phase (otherwise the leak checker will be flooded with
false-positive "leaks" that are actually just memory Perl intentionally leaves to the OS to reclaim).

```
# Call this at the start of your script when running under Valgrind
set_destruct_level(2);
```

# COMPANION MODULES

Auto-generate bindings from C/C++ headers and compile polyglot source with two companion modules:

- [**Affix::Wrap**](https://metacpan.org/pod/Affix%3A%3AWrap): Parses C/C++ headers using the Clang AST to automatically generate Affix bindings for entire libraries.
- [**Affix::Build**](https://metacpan.org/pod/Affix%3A%3ABuild): A polyglot builder that compiles inline C, C++, Rust, Zig, Go, and 15+ other languages into dynamic libraries you can bind instantly.

# THREAD SAFETY & CONCURRENCY

Understand the threading model: what's safe to do from callbacks, and what must happen in the main thread before
spawning any threads. Affix bridges Perl (a single-threaded interpreter, generally) with libraries that may be
multi-threaded. This creates potential hazards that you must manage.

## 1. Initialization Phase vs. Execution Phase

Functions that modify Affix's global state are **not thread-safe**. You must perform all definitions in the main thread
before starting any background threads or loops in the library.

Unsafe operations that you should never call from Callbacks or in a threaded context:

- `affix( ... )` - Binding new functions.
- `typedef( ... )` - Registering new types.

## 2. Callbacks

When passing a Perl subroutine as a `Callback`, avoid performing complex Perl operations like loading modules or
defining subs inside callbacks triggered on a foreign thread. Such callbacks should remain simple: process data, update
a shared variable, and return.

If the library executes the callback from a background thread (e.g., window managers, audio callbacks), Affix attempts
to attach a temporary Perl context to that thread. This should be sufficient but Perl is gonna be Perl.

# RECIPES & EXAMPLES

Real-world patterns including linked lists and C++ vtable calls. See [The Affix
Cookbook](https://github.com/sanko/Affix.pm/discussions/categories/recipes) for comprehensive guides to using Affix.

## Linked List Implementation

```perl
# C equivalent:
# typedef struct Node {
#     int value;
#     struct Node* next;
# } Node;
# int sum_list(Node* head);

typedef 'Node'; # Forward declaration for recursion
typedef Node => Struct[
    value => Int,
    next  => Pointer[ Node() ]
];

# Create a list: 1 -> 2 -> 3
my $list = {
    value => 1,
    next  => {
        value => 2,
        next  => {
            value => 3,
            next  => undef # NULL
        }
    }
};

# Passing to a function that processes the head
affix $lib, 'sum_list', [ Pointer[Node()] ] => Int;
say sum_list($list);
```

## Interacting with C++ Classes (vtable)

```perl
# Manual call to a vtable entry
# Suppose $obj_ptr is a pointer to a C++ object
my $vtable = cast($obj_ptr, Pointer[ Pointer[Void] ]);
my $func_ptr = $vtable->[0]; # Get first method address

# Bind and call
my $method = wrap undef, $func_ptr, [Pointer[Void], Int] => Void;
$method->($obj_ptr, 42);
```

# SEE ALSO

[FFI::Platypus](https://metacpan.org/pod/FFI%3A%3APlatypus), [C::DynaLib](https://metacpan.org/pod/C%3A%3ADynaLib), [XS::TCC](https://metacpan.org/pod/XS%3A%3ATCC), [C::Blocks](https://metacpan.org/pod/C%3A%3ABlocks)

All the heavy lifting is done by [infix](https://github.com/sanko/infix), my JIT compiler and type introspection
engine.

The Affix Cookbook: [https://github.com/sanko/Affix.pm/discussions/54](https://github.com/sanko/Affix.pm/discussions/54)

# AUTHOR

Sanko Robinson - [https://github.com/sanko](https://github.com/sanko)

# COPYRIGHT

Copyright (C) 2022-2026 by Sanko Robinson.

This library is free software; you can redistribute it and/or modify it under the terms of the Artistic License 2.0.
