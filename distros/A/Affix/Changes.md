# Changelog

All notable changes to Affix.pm will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

[Unreleased]: https://github.com/sanko/Affix.pm/compare/v1.0.1...HEAD
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
