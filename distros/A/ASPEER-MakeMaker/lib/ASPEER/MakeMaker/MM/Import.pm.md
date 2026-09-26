# ASPEER::MakeMaker::MM::Import

## Name

ASPEER::MakeMaker::MM::Import - MakeMaker hook installer and active section implementations

## Synopsis

```perl
use ASPEER::MakeMaker;
```

```perl
use ASPEER::MakeMaker qw(const_config postamble);
```

Usually this module is not used directly. It is loaded by
`ASPEER::MakeMaker::import`.

## Description

`ASPEER::MakeMaker::MM::Import` installs and implements the current
`ExtUtils::MakeMaker` hooks for this distribution.

It only performs hook installation while running under a `Makefile.PL` process.
If imported outside that context, it returns without modifying `ExtUtils::MM`.

The module always considers `const_config`, `depend`, `postamble`, and
`post_initialize`, and also honors any additional section names passed by the
caller. For each section, it saves the original MakeMaker implementation and
then replaces `ExtUtils::MM::$section` with a wrapper.

If a method named `<importing class>::MM::<section>` exists, the wrapper calls
that method. Otherwise it calls the section method implemented in this module.

## Import Behavior

```perl
ASPEER::MakeMaker::MM::Import->import(@sections);
```

The import process:

1. Returns immediately if this class has already been loaded.
2. Returns immediately unless the current process name matches `Makefile.PL`.
3. Builds a list of active `ExtUtils::MM::*` classes from `@ExtUtils::MM::ISA`.
4. Saves the original implementation for each requested section.
5. Replaces the matching `ExtUtils::MM::*` symbol with a wrapper.

The original method is stored in the hook object's internal hash and is called
by the replacement section methods before augmenting the result.

The importing class and requested section names are also recorded in activation
order. Generated `PERLRUN` commands use this registry so chained extensions are
reloaded once each and in the same order.

## Section Methods

### const_config

```perl
ASPEER::MakeMaker::MM::Import::const_config($hook, $mm, @args);
```

Calls the original MakeMaker `const_config`, then copies constants from
`ASPEER::MakeMaker::MM::Constant` into the Makefile macro table.
`MM_PREFIX` is private hook configuration and is not emitted as a Makefile
macro.

It publishes supplied license metadata:

- copies `LICENSE` and the first `AUTHOR` into the macro table when supplied
- uses `Software::LicenseUtils` to resolve the license when both are supplied
- writes the resulting URL into `META_MERGE.resources.license`

Neither `LICENSE` nor `AUTHOR` is required by this helper.

The method then installs a global `PERLRUN` command which preserves loaded
MakeMaker extensions and local include paths. Include arguments are quoted
through the active MakeMaker implementation. It also stores `DIST_DEFAULT` in
the `DIST_DEFAULT_TARGET` macro.

### depend

```perl
ASPEER::MakeMaker::MM::Import::depend($hook, $mm, @args);
```

Calls the original MakeMaker `depend` section. When `VERSION_FROM` is set, it
appends the following dependency unless it is already present:

```make
Makefile : $(VERSION_FROM)
```

### postamble

```perl
ASPEER::MakeMaker::MM::Import::postamble($hook, $mm, @args);
```

Calls the original MakeMaker `postamble`, then appends the template named by
`TEMPLATE_POSTAMBLE_FN` in the importing class's `MM::Constant` package.

The module uses `MM_PREFIX` from the importing class's `MM::Constant` package
when naming its command macro. If it is absent, the class name is uppercased
and `::` is replaced with `_`. MakeMaker's `oneliner` method generates the
platform-specific Perl command. The command deliberately uses the global
`PERLRUN` macro so the same extension environment is available to generated
targets, then explicitly reloads the dispatch module belonging to this prefix.
This keeps the target callable when a subsequently loaded extension replaces
the shared `PERLRUN` value.

The parent class's bundled template is:

```text
lib/ASPEER/MakeMaker/MM/postamble.inc
```

### post_initialize

```perl
ASPEER::MakeMaker::MM::Import::post_initialize($hook, $mm, @args);
```

Calls the original MakeMaker `post_initialize` section, then:

- installs `LICENSE` when it exists
- excludes `.md`, `.xml`, `.pod`, `.bak`, `.tmp`, `.new`, `.old`, `.ref`,
  `.0`, and `.1` sources from the install map
- records the current short Git revision beside `VERSION_FROM` when Git and
  the source file are available
- avoids rewriting an unchanged Git revision file
- installs the revision file beside its module or executable

Executable names remain exactly as declared in `EXE_FILES`; the helper does not
remove `.pl` or `.sh` extensions.

## Usage Conventions

Callers should normally use `ASPEER::MakeMaker`, not this module
directly.

Because the module modifies `ExtUtils::MM` symbol table entries, it should be
used only during Makefile generation.

## Diagnostics

The module emits formatted status messages through
`ASPEER::MakeMaker::MM::Util::msg`. It dies if no `ExtUtils::MM`
inheritance chain can be found, if a supplied license string cannot be resolved
unambiguously, or if a Git-revision sidecar cannot be opened.

## See Also

- `ASPEER::MakeMaker`
- `ASPEER::MakeMaker::MM`
- `ASPEER::MakeMaker::MM::Constant`
- `ASPEER::MakeMaker::MM::Util`
- `ExtUtils::MakeMaker`

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Andrew Speer. It may be distributed
under the same terms as Perl itself.
