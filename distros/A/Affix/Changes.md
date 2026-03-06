# Changelog

All notable changes to Affix.pm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [v1.0.9] - 2026-03-05

This release focuses on refining the "Live" zero-copy system (ugh) and fixing bitfield write-back support (yay).

### Breaking Changes
- Replaced `LiveStruct`, `LiveArray`, and `LiveUnion` with a single `Live` wrapper. It now accepts any type object or signature (`Live[Struct[...]]`, `Live[Array[Int, 10]]`) and returns a live, zero-copy view. I hate this too but I'm workin' on it.

### Added
- Fully implemented write support for bitfields in live views. Modifying a bitfield member in an `Affix::Live` hash now correctly performs bit-masked writes to the underlying C memory.
- Added `LiveUnion` as a deprecated alias for the unified `Live()` classifier.

### Fixed

- Fixed an inconsistency where `Affix::Type::Array` objects were stringifying in a format incompatible with `cast`. They now correctly use the `$type[$count]` syntax.
- Updated the internal type stringifier to correctly resolve and prefer the `signature` method over `stringify`, ensuring consistent behavior across all `Affix::Type` objects.
- Fixed a bug in `Affix_cast` where the `live_hint` (`+`) was ignored for Arrays and Unions.

## [v1.0.8] - 2026-03-02

This release introduces a modernization of pointer handling, turning pins into first-class objects with native indexing support. In other words, you can now use `$ptr->[$n]` to access the nth element.

Support for passing 128bit integers around is now complete. Additionally, functions expecting an enumeration now accept the string name of a constant; `state('PLASMA')` is the same as `state(PLASMA)` where `state` expects values defined like this: `typedef States => Enum['SOLID', 'LIQUID', 'GAS', 'PLASMA']`.

### Added

- Added support for native Perl array indexing on pointers and arrays. You can now use `$ptr->[$i]` to read or write memory at an offset without manual casting.
- New `Affix::Pointer` objects for structs and unions now allow direct field access like `$ptr->{field}` without explicit casting to `LiveStruct`.
- Recursive Liveness: Unified access and `LiveStruct` now work recursively. Accessing a nested struct member returns a live view or pointer tied to the original memory block.
- All pointers returned by `malloc`, `calloc`, `cast`, etc., are now blessed into the `Affix::Pointer` class, which provides several new methods:
    - `address()`: Returns the virtual memory address.
    - `type()`: Returns the L<infix> signature of the pointer.
    - `element_type()`: Returns the signature of the pointed-to elements.
    - `count()`: Returns the element count for Arrays, or byte size for Void pointers.
    - `size()`: Returns the total allocated size for managed pointers.
    - `cast($type)`: Reinterprets the pointer.
    - `attach_destructor($destructor, [$lib])`: Attaches a custom C cleanup routine to the pointer.
- Added `attach_destructor( $pin, $destructor, [$lib] )` to allow attaching custom C cleanup routines to managed pointers.
- Improved `VarArgs` support to automatically promote Perl strings to `char*`.
- Experimental Zero-Copy 'Live' Aggregates:
    - `LiveStruct`: A new helper to return zero-copy, live views of C structs. Modifications to the returned blessed hash reflect immediately in C memory.
    - `LiveArray`: A new helper to return live `Affix::Pointer` objects instead of deeply copied array references.
    - Implemented the `TIEHASH` interface for `Affix::Live` so perl can treat them as standard Perl hashes (`keys %$live`, `each %$live`, etc.).
- Fully implemented marshalling for `Int128` and `UInt128` (sint128/uint128) primitive types.
- Added `Affix::Wrap->generate( $lib, $pkg, $file )` for static binding generation. This emits standalone Perl modules that depend only on `Affix`, eliminating the need for `Clang` or header files at runtime.
- Recursive macro resolution support in `Affix::Wrap` for bitwise OR expressions like `(FLAG_A | FLAG_B)`.
- Support for passing string names of enum constants directly to functions.
- Added `params()` method to `Affix::Type::Callback` to allow inspecting and modifying callback parameters.
- Added string-to-integer conversion when passing Perl strings to C functions expecting enums.

### Fixed

- Optimized `Pointer` returns in the XSUB dispatcher for performance by inlining the marshalling path and caching the stash.
- Fixed several issues in `CLONE` where metadata, managed memory, and enum registries were not correctly duplicated across perl's ithreads.
- Improved `_get_pin_from_sv` and `is_pin` to safely handle both references to pins and direct magical scalars like those found in Unions.
- Fixed potential double-frees and leaks in `Affix_Lib_DESTROY` and `Affix_free_pin` by improving reference counting and ownership tracking.
- Symbols found via `find_symbol` now correctly track the parent `Affix::Lib` object to prevent the library from being unloaded while symbols are still in use.
- Corrected a memory corruption bug in `Affix_malloc` and `Affix_strdup` caused by uninitialized internal `Affix_Pin` structures.
- Fixed `dualvar` behavior for enums returned from C, ensuring they correctly function as both strings and integers in Perl.
- Fixed the `clean` action in `Affix::Builder` which was failing due to an undefined `rmtree` call.
- Fixed an issue where blessing a return value could prematurely trigger 'set' magic on the underlying SV.
- Fixed `typedef` parsing: Named types now return proper `Affix::Type::Reference` objects instead of strings, ensuring they are correctly resolved when nested in other aggregates.
- Fixed `cast` to correctly return blessed `Affix::Live` objects when the `+` hint is used for live struct views.
- Hardened pointer indexing: Added strict type checks to `$ptr->[$i]` to ensure indexing is only performed on `Array` types or `Void*` (byte-indexed).

## [v1.0.7] - 2026-02-15

Valgrind directed the work in Affix itself but infix got a lot of platform stability fixes which found their way into Affix by way of new Float16 support, bitfield width support, and SIMD improvements.

### Fixed

- Anonymous wrapper functions created via wrap() were leaking because of a redundant SvREFCNT_inc call and the use of newRV_inc instead of newRV_noinc. This prevented the underlying CV and its associated Affix struct (including its memory arenas) from being destroyed until global destruction.
- Implicitly loaded libraries (by path) were not having their reference counts decremented because the handle was not stored in the Affix struct. Additionally, using Affix::Lib objects did not increment the registry reference count, potentially leading to premature closing or double-decrements.
- Passing Pointer[SV] arguments to C functions caused a reference count leak of 1 per call because SvREFCNT_inc was called without a corresponding decrement.
- The library registry cleanup logic was missing from the main CV destructor and had a potential crash-inducing bug in the bundled destructor.
- [infix] Corrected an ARM64 bug in `emit_arm64_ldr_vpr` and `emit_arm64_str_vpr` where boolean conditions were being passed instead of actual byte sizes, causing data truncation for floating-point values in the direct marshalling path.
- [infix] Fixed MSVC ARM: SEH XDATA layout to follow the architecture's specification exactly, enabling reliable exception handling on Windows on ARM.
- [infix] Hardened instruction cache invalidation on ARM64 Linux/BSD with a robust manual fallback using assembly (`dc cvau`, `ic ivau`, etc.), ensuring generated code is immediately visible to the CPU.
- [infix] Fixed the DWARF `.eh_frame` generation for ARM64 Linux `FORWARD` trampolines, correcting the instruction sequence and offsets to enable reliable C++ exception propagation.
- [infix] Corrected a performance issue on x64 by adding `vzeroupper` calls in epilogues when AVX instructions are potentially used, avoiding transition penalties.
- [infix] Fixed bitfield parsing logic to correctly handle colons in namespaces vs bitfield widths.
- [infix] Fixed missing support for 256-bit and 512-bit vectors in SysV reverse trampolines.
- [infix] Rewrote `_layout_struct` in `src/core/types.c` to correctly handle bitfields larger than 8 bits and ensures `bit_offset` is always within the correct byte, matching standard C (well, GNU) compiler packing behavior.
- [infix] Fixed a bug in the SysV recursive classifier that was incorrectly applying strict natural alignment checks to bitfield members. This was causing structs containing bitfields to be unnecessarily passed on the stack instead of in registers.
- [infix] Trampolines allocated in a user-managed "shared arena" were being added to the internal global cache. When the user destroyed the arena, the cache retained dangling pointers to the trampoline signatures.

### Added

- Float16 support
 - Added the Float16 keyword to Affix.pm.
 - Implemented float_to_half and half_to_float conversion logic in Affix.c (IEEE 754).
 - Added optimized opcodes (OP_PUSH_FLOAT16, OP_RET_FLOAT16) to the internal VM dispatcher for high-performance marshalling.

- Bitfield Support:
 - Enhanced Struct [...] syntax in Affix.pm to support bitfield widths (e.g., a => UInt32, 3).
 - Implemented bitmask-based marshalling in Affix.c to correctly pack and unpack C-style bitfields within structs.

- SIMD Vector Improvements:
 - Added M512, M512d, and M512i type helpers.
 - Ensured compatibility with infix's refined vector alignment and passing rules.
- [infix] Added support for half-precision floating-point (`float16`).
- [infix] Implemented C++ exception propagation through JIT frames on Linux (x86-64 and ARM64) using manual DWARF `.eh_frame` generation and `__register_frame`.
- [infix] Implemented Structured Exception Handling (SEH) for Windows x64 and ARM64 for C++ exception propagation through trampolines.
- [infix] Added `infix_forward_create_safe` API to establish an exception boundary that catches native exceptions and returns a dedicated error code (`INFIX_CODE_NATIVE_EXCEPTION`).
- [infix] Added support for 256-bit (AVX) and 512-bit (AVX-512) vectors in the System V ABI.
- [infix] Added support for receiving bitfield structs in reverse call trampolines.
- [infix] Added trampoline caching. Identical signatures and targets now share the same JIT-compiled code and metadata via internal reference counting, significantly reducing memory overhead and initialization time.
- [infix] Added a new opt-in build mode (`--sanity`) that emits extra JIT instructions to verify stack pointer consistency around user-provided marshaller calls, making it easier to debug corrupting language bindings.

### Changed

- Pull infix v0.1.6.
- [infix] Explicitly enabled 16-byte stack alignment in Windows x64 trampolines to ensure SIMD compatibility.
- [infix] Updated `infix_type_create_vector` to use the vector's full size for its natural alignment (e.g., 32-byte alignment for `__m256`).
- [infix] Refined the Windows x64 ABI to pass all vector types by reference (pointer in GPR). This ensures compatibility with MSVC which expects even 128-bit vectors to be passed via pointer in many scenarios, while still returning them by value in `XMM0`.
- [infix] Move to a pre-calculated hash field in `_infix_registry_entry_t`. Lookups and rehashing now use this stored hash, significantly reducing string hashing overhead during type resolution and registry scaling.
- [infix] Optimized Type Registry memory management: Internal hash table buckets are now heap-allocated and freed during rehashes, preventing memory "leaks" within the registry's arena.

## [v1.0.6] - 2026-01-22

Most of this version's work went into threading stability, ABI correctness, and security within the JIT engine.

### Changed

  - [[infix]] The JIT memory allocator on Linux now uses `memfd_create` (on kernels 3.17+) to create anonymous file descriptors for dual-mapped W^X memory. This avoids creating visible temporary files in `/dev/shm` and improves hygiene and security. On FreeBSD, `SHM_ANON` is now used.
  - \[infix] On dual-mapped platforms (Linux/BSD), the Read-Write view of the JIT memory is now **unmapped immediately** after code generation. This closes a security window where an attacker with a heap read/write primitive could potentially modify executable code by finding the stale RW pointer.
  - \[infix] `infix_library_open` now uses `RTLD_LOCAL` instead of `RTLD_GLOBAL` on POSIX systems. This prevents symbols from loaded libraries from polluting the global namespace and causing conflicts with other plugins or the host application.

### Fixed

  - Fixed `CLONE` to correctly copy user-defined types (typedefs, structs) to new threads. Previously, child threads started with an empty registry, causing lookup failures for types defined in the parent.
  - Thread safety: Fixed a crash when callbacks are invoked from foreign threads. Affix now correctly injects the Perl interpreter context into the TLS before executing the callback.
  - Added stack overflow protection to the FFI trigger. Argument marshalling buffers larger than 2KB are now allocated on the heap (arena) instead of the stack, preventing crashes on Windows and other platforms with limited stack sizes.
  - Type resolution: Fixed a logic bug where `Pointer[SV]` types were incorrectly treated as generic pointers if `typedef`'d. They are now correctly unwrapped into Perl CODE refs or blessed objects.
  - Process exit: Disabled explicit library unloading (`dlclose`/`FreeLibrary`) during global destruction. This prevents segmentation faults when background threads from loaded libraries try to execute code that has been unmapped from memory during shutdown.
    I tried to just limit it to Go lang libs but it's just more trouble than it's worth until I resolve a few more things.
  - \[infix] Fixed stack corruption on macOS ARM64 (Apple Silicon). `long double` on this platform is 8 bytes (an alias for `double`), unlike standard AAPCS64 where it is 16 bytes. The JIT previously emitted 16-byte stores (`STR Qn`) for these types, overwriting adjacent stack memory.
  - \[infix] Fixed `long double` handling on macOS Intel (Darwin). Verified that Apple adheres to the System V ABI for this type: it requires 16-byte stack alignment and returns values on the x87 FPU stack (`ST(0)`).
  - \[infix] Fixed a generic System V ABI bug where 128-bit types (vectors, `__int128`) were not correctly aligned to 16 bytes on the stack relative to the return address, causing data corruption when mixed with odd numbers of 8-byte arguments.
  - \[infix] Enforced natural alignment for stack arguments in the AAPCS64 implementation. Previously, arguments were packed to 8-byte boundaries, which violated alignment requirements for 128-bit types.
  - \[infix] Fixed a critical deployment issue where the public `infix.h` header included an internal file (`common/compat_c23.h`). The header is now fully self-contained and defines `INFIX_NODISCARD` for attribute compatibility.
  - \[infix] Fixed 128-bit vector truncation on System V x64 (Linux/macOS). Reverse trampolines previously used 64-bit moves (`MOVSD`) for all SSE arguments, corrupting the upper half of vector arguments. They now correctly use `MOVUPS`.
  - \[infix] Fixed vector argument corruption on AArch64. The reverse trampoline generator now correctly identifies vector types and uses 128-bit stores (`STR Qn`) instead of falling back to 64-bit/32-bit stores or GPRs.
  - \[infix] Fixed floating-point corruption on Windows on ARM64. Reverse trampolines now force full 128-bit register saves for all floating-point arguments to ensure robust handling of volatile register states.
  - \[infix] Fixed a logic error in the System V reverse argument classifier where vectors were defaulting to `INTEGER` class, causing the trampoline to look in `RDI`/`RSI` instead of `XMM` registers.
  - \[infix] Fixed potential cache coherency issues on Windows x64. The library now unconditionally calls `FlushInstructionCache` after JIT compilation.
  - \[infix] Capped the maximum alignment in `infix_type_create_packed_struct` to 1MB to prevent integer wrap-around bugs in layout calculation.
  - \[infix] Fixed a buffer overread on macOS ARM64 where small signed integers were loaded using 32-bit `LDRSW`. Implemented `LDRSH` and `LDRSB`.
  - \[infix] Added native support for Apple's Hardened Runtime security policy.
    - The JIT engine now utilizes `MAP_JIT` when the `com.apple.security.cs.allow-jit` entitlement is detected.
    - Implemented thread-local permission toggling via `pthread_jit_write_protect_np` to maintain W^X compliance.

## [v1.0.5] - 2026-01-11

### Changed

  - Affix::Wrap allows you to define your own types just in case the headers fail to parse completely.

## [v1.0.4] - 2026-01-10

This should just be a documentation cleanup cycle.

## [v1.0.3] - 2026-01-07

Based on infix v0.1.3

### Added

  - Support for Variadic Functions (varargs):
    - Implemented dynamic JIT compilation for C functions with variable arguments (e.g., `printf`).
    - Added `variadic_cache` to cache trampolines for repeated calls, ensuring high performance.
    - Implemented runtime type inference: Perl integers promote to `sint64`, floats to `double`, and strings to `*char`.
  - Added `Affix::coerce($type, $value)` to explicitly hint types for variadic arguments. This allows passing structs by value or forcing specific integer widths where inference is insufficient.
  - Cookbook: I'm putting together chapters on a wide range of topics at https://github.com/sanko/Affix.pm/discussions/categories/recipes
  - `affix` and `wrap` functions now accept an address to bind to. This expects the library to be `undef` and jumps past the lib location and loading steps.
  - Added `File` and `PerlIO` types.
    - Allows passing Perl filehandles to C functions expecting standard C streams (`PerlIO*` => `Pointer[PerlIO]`).
    - Allows receiving `FILE*` from C and using them as standard Perl filehandles (`FILE*` => `Pointer[File]`).
  - A few new specialized pointer types:
    - `StringList`: Automatically marshals an array ref of strings to a null-terminated `char**` array (and back). This is useful in instances where `argv` or a similar list is expected.
    - `Buffer`: Allows passing a pre-allocated scalar as a mutable `char*` buffer to C (zero-copy write).
    - `SockAddr`: Safe marshalling of Perl packed socket addresses to `struct sockaddr*`.
  - Affix::Build: A polyglot shared library builder. Currently supports Ada, Assembly, C, C#, C++, Cobol, Crystal, Dlang, Eiffel, F#, Fortran, Futhark, Go, Haskell, Nim, OCaml, Odin, Pascal, Rust, Swift, Vlang, and Zig.
  - Affix::Wrap: An experimental tool to introspect C header files and generate Affix bindings and documentation.
    - Dual-Driver Architecture:
      - `Affix::Wrap::Driver::Clang`: Uses the system `clang` executable to parse the AST for high-fidelity extraction of types, macros, and comments.
      - `Affix::Wrap::Driver::Regex`: A zero-dependency fallback driver that parses headers using heuristics.


### Changed

  - `Array[Char]` function arguments now accept Perl strings directly, copying the string data into the temporary C array.
  - `Affix::errno()` now returns a dualvar containing both the numeric error code (`errno`/`GetLastError`) and the system error string (`strerror`/`FormatMessage`).

### Fixed

  - Correctly implemented array decay for function arguments on ARM and Win64. `Array[...]` types are now marshalled into temporary C arrays and passed as pointers, matching standard C behavior. Previously, they were incorrectly passed by value, causing stack corruption.
  - Fixed binary safety for `Array[Char/UChar]`. Reading these arrays now respects the explicit length rather than stopping at the first null byte.
  - The write-back mechanism no longer attempts to overwrite the read-only ArrayRef scalar with the pointer address.
  - `Pointer[SV]` is now handled properly as args, return values, and in callbacks. Reference counting is automatic to prevent premature garbage collection of passed scalars.
  - Shared libs written in Go spin up background threads (for GC and scheduling) that do not shut down cleanly when a shared library is unloaded. This often causes access violations on Windows during program exit. We attempt to work around this by detecting libs with the Go runtime and just... not unloading them.

## [v1.0.2] - 2025-12-14

### Changed

  - In an attempt to debug mystery failures in SDL3.pm, Affix.pm will warn and return `undef` instead of `croak`ing.
  - Improved error reporting: if the internal error message is empty, the numeric error code is now included in the warning.

### Fixed

  - [[infix]] Fixed a critical file descriptor leak on POSIX platforms (Linux/FreeBSD) where the file descriptor returned by `shm_open` was kept open for the lifetime of the trampoline, eventually hitting the process file descriptor limit (EMFILE). The descriptor is now closed immediately after mapping, as intended.
  - Fixed memory leaks that occurred when trampoline creation failed midway (cleaning up partial arenas, strings, and backend structures).

## [v1.0.1] - 2025-12-13

### Changed

  - Improved Union marshalling: Union members are now exposed as pins within the hash. This allows clean syntax (like `$u->{member} = 5`) without needing to dereference a reference, while maintaining C-memory aliasing.

### Fixed

  - Fixed `writeback_pointer_generic` to support writing back to scalar output parameters (pointers-to-pointers). This resolves issues where C functions returning handles via arguments would fail to populate the SV*/pin.

## [v1.0.0] - 2025-12-13

  - Stable? Stable. Stable enough.

## [v0.12.0] - 2025-12-12

### Changed

  - Affix is reborn! This is a complete rewrite
  - Replaced dyncall with a JIT and introspection engine I've called [infix](https://github.com/sanko/infix.git)

## [0.11] - 2023-03-30

### Added

  - Support for WChar
  - Rough, basic support for mangled symbols:
    - Itanium C++ ABI
    - Rust (legacy)
  - Expose dcNewCallVM( ... ) size variable

## [0.10] - 2023-03-11

### Changed

  - Support for ArrayRef[] with dynamic size
  - Support for empty Stuct[]
  - Coerce Enum[] types with sv2ptr(...)
  - Explicit undef values are turned into NULL in Pointer[], ArrayRef[], etc.
  - Provide default values in Struct[]
  - Ignore perl's PTRSIZE which might be different than the system's actual pointer size
  - Cleanup VM on Affix::END()
  - Simplify API around named subs
  - Support for WStr (wchar_t *, PWSTR, etc.)

## [0.09] - 2023-01-26

### Added

  - Structs may now contain a CodeRef
  - CodeRef, Any, etc. are now properly handled as aggregate members
  - Nesting CodeRefs used as callbacks work now
  - Bind to exported values with pin()
  - Expose aggregate by value and syscall support in Affix::Feature
  - Survive callbacks with unexpectedly empty return values
  - Delayed type resolution with InstanceOf

## [0.08] - 2022-12-19

### Fixed

  - Correct struct alignment for perls with quadmath and/or longdouble enabled

## [0.07] - 2022-12-17

### Changed

  - Pull upstream changes to dyncall 1.5 (unstable)

## [0.06] - 2022-12-16

### Changed

  - Allow calling convention to be changed in param lists
  - Fix quadmath tests (I hope)
  - Attempt to build with nmake on Win32 smokers that have gcc but not GNU make (how? why?)
  - Fix default struct padding when passing around by value

## [0.05] - 2022-12-14

### Changed

  - Expose offsetof( ... )
  - Pull upstream changes to dyncall 1.4 (stable)

## [0.04] - 2022-12-07

### Changed

  - Affix.pm is born

[Unreleased]: https://github.com/sanko/Affix.pm/compare/v1.0.9...HEAD
[v1.0.9]: https://github.com/sanko/Affix.pm/compare/v1.0.8...v1.0.9
[v1.0.8]: https://github.com/sanko/Affix.pm/compare/v1.0.7...v1.0.8
[v1.0.7]: https://github.com/sanko/Affix.pm/compare/v1.0.6...v1.0.7
[v1.0.6]: https://github.com/sanko/Affix.pm/compare/v1.0.5...v1.0.6
[v1.0.5]: https://github.com/sanko/Affix.pm/compare/v1.0.4...v1.0.5
[v1.0.4]: https://github.com/sanko/Affix.pm/compare/v1.0.3...v1.0.4
[v1.0.3]: https://github.com/sanko/Affix.pm/compare/v1.0.2...v1.0.3
[v1.0.2]: https://github.com/sanko/Affix.pm/compare/v1.0.1...v1.0.2
[v1.0.1]: https://github.com/sanko/Affix.pm/compare/v1.0.0...v1.0.1
[v1.0.0]: https://github.com/sanko/Affix.pm/compare/v0.12.0...v1.0.0
[v0.12.0]: https://github.com/sanko/Affix.pm/compare/0.11...v0.12.0
[0.11]: https://github.com/sanko/Affix.pm/compare/0.10...0.11
[0.10]: https://github.com/sanko/Affix.pm/compare/0.09...0.10
[0.09]: https://github.com/sanko/Affix.pm/compare/0.08...0.09
[0.08]: https://github.com/sanko/Affix.pm/compare/0.07...0.08
[0.07]: https://github.com/sanko/Affix.pm/compare/0.06...0.07
[0.06]: https://github.com/sanko/Affix.pm/compare/0.05...0.06
[0.05]: https://github.com/sanko/Affix.pm/compare/0.04...0.05
[0.04]: https://github.com/sanko/Affix.pm/releases/tag/0.04
