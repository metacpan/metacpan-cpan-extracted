# ASPEER::MakeMaker

`ASPEER::MakeMaker` is the parent distribution for sharing
`ExtUtils::MakeMaker` customizations across ASPEER MakeMaker plugins.

The module is designed to be loaded from a `Makefile.PL`. On import it can
wrap selected `ExtUtils::MakeMaker` sections, add project-specific Makefile
macros, and append a reusable postamble containing common make targets.

## GitHub Attestations

The release workflow generates [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
for distribution archives. Install the [GitHub CLI](https://cli.github.com/)
with `gh attestation` support and authenticate with `gh auth login`.

Download `ASPEER-MakeMaker-VERSION.tar.gz` from a GitHub release, MetaCPAN,
or a CPAN mirror, replace `VERSION`, and verify it with:

```sh
gh attestation verify ASPEER-MakeMaker-VERSION.tar.gz --repo aspeer/pm-ASPEER-MakeMaker
```

A successful verification confirms that the archive checksum matches an
attestation from this repository. The workflow publishes the same archive to
GitHub Releases and CPAN. Older releases and GitHub's automatically generated
source-code archives are not covered.

## Purpose

This distribution centralizes build-time conventions that would otherwise be
copied between plugin distributions. In particular it provides:

- MakeMaker import hooks for selected Makefile generation sections.
- A `const_config` extension that publishes shared constants as Makefile
  macros.
- A `postamble` extension that appends common make targets from a template.
- A `post_initialize` extension that controls the install map and records the
  Git revision beside `VERSION_FROM`.
- A retained `util_sync` target and method for copying the shared utility files
  into an older or standalone distribution when required.
- Shared logging, file, argument-parsing, and Perl runtime construction helpers.

## Basic Usage

In a consuming `Makefile.PL`, load the module before calling `WriteMakefile`:

```perl
use ASPEER::MakeMaker;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME         => 'Some::Module',
    VERSION_FROM => 'lib/Some/Module.pm',
);
```

With no import arguments, `ASPEER::MakeMaker` enables the `const_config`,
`depend`, `postamble`, and `post_initialize` hooks. A caller may also request
additional sections explicitly:

```perl
use ASPEER::MakeMaker qw(const_config postamble);
```

The generated postamble dispatches make targets back into the module through a
MakeMaker-generated command using the global `PERLRUN` value. Local include
paths are quoted for the platform shell. The target method receives a fixed
MakeMaker argument block first, followed by any target-specific arguments.

The Makefile retains any existing dependencies and also depends on
`VERSION_FROM`. License metadata is enriched when both `LICENSE` and `AUTHOR`
are supplied, but neither field is mandatory.

During post-initialization, documentation and temporary source files are
removed from the install map. If Git and `VERSION_FROM` are available, a
matching `.sha` provenance file is updated only when its content changes and is
installed beside the module or script. Executable filenames are always kept as
declared in `EXE_FILES`.

## Plugin Inheritance

A plugin inherits the public entry point and MakeMaker namespace, imports the
shared utility functions, and supplies its own constants and target methods:

```perl
package ASPEER::MakeMaker::Example;
use ASPEER::MakeMaker ();
use ASPEER::MakeMaker::Example::MM ();
use vars qw(@ISA);
@ISA=qw(ASPEER::MakeMaker);
```

```perl
package ASPEER::MakeMaker::Example::MM;
use ASPEER::MakeMaker::MM ();
use ASPEER::MakeMaker::MM::Util;
use vars qw(@ISA);
@ISA=qw(ASPEER::MakeMaker::MM);
```

The shared import layer reads the importing plugin's `MM::Constant` package and
postamble template. This gives each plugin its own Makefile macro prefix and
targets while retaining the common lifecycle hooks and additive `PERLRUN`
behavior.

## Generated Targets

The parent's bundled postamble defines `util_sync`. That target calls the
module's `util_sync` method twice:

- once for `Util.pm`
- once for `Import.pm`

After each copy, the target rewrites occurrences of `ASPEER::MakeMaker`
in the destination file to the consuming distribution's `$(NAME)`.

The destination is derived from the consuming distribution's `TO_INST_PM`
install map. Current child plugins inherit these modules directly and do not
run `util_sync`; the target remains available for a future vendoring or
standalone maintenance use case.

## Local Overrides

`ASPEER::MakeMaker::MM::Constant` loads default constants from the module and
then applies optional local overrides from:

- a `.local` file next to `Constant.pm`
- `~/.ASPEER::MakeMaker::MM::Constant.local`

Each override file is expected to evaluate to a hash reference.

## Documentation Map

The module-level sidecar documents describe the individual pieces:

- `lib/ASPEER/MakeMaker.pm.md`
- `lib/ASPEER/MakeMaker/MM/Import.pm.md`
- `lib/ASPEER/MakeMaker/MM.pm.md`
- `lib/ASPEER/MakeMaker/MM/Util.pm.md`
- `lib/ASPEER/MakeMaker/MM/Constant.pm.md`

## Notes

This module modifies `ExtUtils::MakeMaker` behavior by replacing selected
`ExtUtils::MM::*` methods at import time. It should therefore be loaded as part
of Makefile generation, not as a general runtime dependency.

The distribution requires Perl 5.8 or later.
