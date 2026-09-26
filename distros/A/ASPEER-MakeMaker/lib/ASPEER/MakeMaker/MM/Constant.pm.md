# ASPEER::MakeMaker::MM::Constant

## Name

ASPEER::MakeMaker::MM::Constant - exported constants and Makefile macro data

## Synopsis

```perl
use ASPEER::MakeMaker::MM::Constant qw(
    $ASPEER_MAKEMAKER_PM
    $TEMPLATE_POSTAMBLE_FN
    $UPDATE_SOURCE_UTIL_FN
    $UPDATE_SOURCE_IMPORT_FN
    $UPDATE_SOURCE_CONSTANT_FN
    $ASPEER_MAKEMAKER_PM_ARGV
);
```

```perl
use ASPEER::MakeMaker::MM::Constant qw(:all);
```

## Description

`ASPEER::MakeMaker::MM::Constant` defines constants used by the
MakeMaker hook layer and generated postamble targets.

The constants are stored in `%Constant`, exported as scalar package variables,
and copied into the Makefile macro table by
`ASPEER::MakeMaker::MM::Import::const_config`.

## Constants

### MM_PREFIX

Private prefix used when constructing this extension's Makefile macro names.
It is consumed by the hook implementation and is not emitted as the generic
Makefile macro `MM_PREFIX`. When omitted, the importing class name is
uppercased and `::` is replaced with `_`.

### ASPEER_MAKEMAKER_PM

The module name used by generated make targets when dispatching back into this
helper distribution.

Default:

```perl
ASPEER::MakeMaker
```

### TEMPLATE_POSTAMBLE_FN

Path to the bundled postamble template:

```text
lib/ASPEER/MakeMaker/MM/postamble.inc
```

### UPDATE_SOURCE_UTIL_FN

Path to this distribution's source `MM/Util.pm`. The `util_sync` target can use
this as the source file for utility synchronization.

### UPDATE_SOURCE_IMPORT_FN

Path to this distribution's source `MM/Import.pm`. The `util_sync` target can
use this as the source file for import helper synchronization.

### UPDATE_SOURCE_CONSTANT_FN

Path to this distribution's source `MM/Constant.pm`.

### ASPEER_MAKEMAKER_PM_ARGV

A comma-separated Makefile macro expression that expands to the fixed argument
block passed into generated target methods.

The argument order matches `ASPEER::MakeMaker::MM::Util::arg`:

- `$(NAME)`
- `$(NAME_SYM)`
- `$(DISTNAME)`
- `$(DISTVNAME)`
- `$(VERSION)`
- `$(VERSION_SYM)`
- `$(VERSION_FROM)`
- `$(LICENSE)`
- `$(AUTHOR)`
- `$(TO_INST_PM)`
- `$(EXE_FILES)`
- `$(DIST_DEFAULT_TARGET)`
- `$(SUFFIX)`
- `$(ABSTRACT_FROM)`

## Local Overrides

After defining built-in defaults, the module applies optional local overrides.
The override files must evaluate to a hash reference.

The files are loaded in this order:

1. A `.local` file beside `MM/Constant.pm`.
2. `~/.ASPEER::MakeMaker::MM::Constant.local`.

Later values override earlier values.

## Export Behavior

All constants are exported by default as scalar variables. They are also
available through the `:all` export tag. Loading the module does not alter the
caller's `$_` value.

## See Also

- `ASPEER::MakeMaker`
- `ASPEER::MakeMaker::MM::Import`
- `ASPEER::MakeMaker::MM::Util`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
