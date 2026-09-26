# ASPEER::MakeMaker

## Name

ASPEER::MakeMaker - parent entry point and shared make-target methods for MakeMaker plugins

## Synopsis

```perl
use ASPEER::MakeMaker;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Some::Module',
    VERSION_FROM => 'lib/Some/Module.pm',
);
```

```perl
use ASPEER::MakeMaker qw(const_config postamble);
```

## Description

`ASPEER::MakeMaker` is the public parent entry point for the distribution. It
sets version metadata, imports shared utility functions from
`ASPEER::MakeMaker::MM::Util`, and forwards import handling to
`ASPEER::MakeMaker::MM::Import`.

When imported without arguments, it requests the `const_config` and `postamble`
MakeMaker sections. The hook installer also enables `depend` and
`post_initialize`, which provide the standard dependency, install-map, and
Git-provenance behavior. Import handling is lazy-loaded and then delegated to
`ASPEER::MakeMaker::MM::Import`.

Child plugins inherit this class and provide a matching `<plugin>::MM` class
and `<plugin>::MM::Constant` package. The shared import layer then dispatches
the plugin's own targets while retaining the common lifecycle behavior. The
module also contains methods intended to be invoked by generated make targets.

## Methods

### import

```perl
use ASPEER::MakeMaker;
use ASPEER::MakeMaker qw(const_config postamble);
```

Enables MakeMaker section hooks. If no sections are supplied, `const_config`
and `postamble` are requested; `depend` and `post_initialize` are installed by
the hook manager as common defaults.

The implementation loads `ASPEER::MakeMaker::MM::Import` and forwards to
its `import` method.

### dump_param

```perl
ASPEER::MakeMaker->dump_param(@makemaker_args, @args);
```

Debugging method. It parses the MakeMaker-style argument list with `arg` and
prints the resulting hash using `Dumper`.

### util_sync

```perl
ASPEER::MakeMaker->util_sync(
    @makemaker_args,
    $source_file,
);
```

Copies one of this distribution's helper files into a consuming
distribution. The method expects the fixed MakeMaker argument block first,
followed by the source file path. The destination is not passed directly.
Instead, `util_sync` derives it from the parsed `TO_INST_PM` MakeMaker value.

The destination lookup uses the source basename and selects an installed module
path ending in:

```text
MM/<source basename>
```

For example, a source named `Util.pm` is matched against a target path ending
in `MM/Util.pm`.

The method validates that:

- a source argument is present
- `TO_INST_PM` can be parsed into `TO_INST_PM_AR`
- the destination can be found in `TO_INST_PM_AR`
- the source exists, is a regular file, and is readable
- the destination directory exists
- the source and destination are not the same path or same file

It reads the source and replaces the helper package name with the consuming
distribution's `NAME`. When `VERSION_FROM` names an available source file, its
declared `$VERSION` is parsed using MakeMaker and applied to the copied helper.
The MakeMaker `VERSION` value is used as a fallback. The result is written
through a temporary file in the destination directory; source mode and
timestamps are preserved before the temporary file is renamed into place.

Current behavior allows overwriting an existing destination file. Current
ASPEER child plugins inherit the shared modules directly; this method is
retained for possible future vendoring or standalone synchronization.

## Usage Conventions

Load this module from `Makefile.PL` before MakeMaker generates the Makefile.
It is build-time infrastructure and is not intended to be part of normal module
runtime behavior.

Target methods should accept the fixed MakeMaker argument block first and use
`ASPEER::MakeMaker::MM::Util::arg` to separate MakeMaker fields from
target-specific arguments.

The module supports Perl 5.8 and later.

## See Also

- `ASPEER::MakeMaker::MM`
- `ASPEER::MakeMaker::MM::Import`
- `ASPEER::MakeMaker::MM::Util`
- `ASPEER::MakeMaker::MM::Constant`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
