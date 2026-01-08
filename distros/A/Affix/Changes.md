# Changelog

All notable changes to Affix.pm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[Unreleased]: https://github.com/sanko/Affix.pm/compare/v1.0.3...HEAD
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
