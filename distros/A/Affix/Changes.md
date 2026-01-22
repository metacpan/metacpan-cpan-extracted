
# Changelog

All notable changes to Affix.pm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[Unreleased]: https://github.com/sanko/Affix.pm/compare/v1.0.6...HEAD
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
