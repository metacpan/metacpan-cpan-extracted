# ASPEER::MakeMaker::MM

## Name

ASPEER::MakeMaker::MM - namespace module for MakeMaker helper support

## Synopsis

```perl
use ASPEER::MakeMaker::MM;
```

This module is normally loaded indirectly by `ASPEER::MakeMaker` and
`ASPEER::MakeMaker::MM::Import`.

## Description

`ASPEER::MakeMaker::MM` currently acts as a namespace and dependency
anchor for the MakeMaker helper implementation. It loads:

- `ASPEER::MakeMaker::MM::Util`
- `ASPEER::MakeMaker::MM::Constant`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.

The active MakeMaker section wrappers and replacement methods are implemented
in `ASPEER::MakeMaker::MM::Import`.

## Methods

### const_config0

```perl
ASPEER::MakeMaker::MM::const_config0($hook, $mm, @args);
```

Legacy or parked implementation of a `const_config` wrapper. It calls the
saved original MakeMaker section, copies constants into the Makefile macro
table, and updates `PERLRUN`.

The active implementation is currently
`ASPEER::MakeMaker::MM::Import::const_config`.

### postamble0

```perl
ASPEER::MakeMaker::MM::postamble0($hook, $mm, @args);
```

Legacy or parked implementation of a `postamble` wrapper. It calls the saved
original MakeMaker section and appends the configured postamble template.

The active implementation is currently
`ASPEER::MakeMaker::MM::Import::postamble`.

## Usage Conventions

Do not call this module's methods directly from a `Makefile.PL`. Use the
top-level entry point:

```perl
use ASPEER::MakeMaker;
```

New active MakeMaker hook behavior should generally be documented against
`ASPEER::MakeMaker::MM::Import`, since that module installs and provides
the current hook implementations.

## See Also

- `ASPEER::MakeMaker`
- `ASPEER::MakeMaker::MM::Import`
- `ASPEER::MakeMaker::MM::Util`
- `ASPEER::MakeMaker::MM::Constant`
