# NAME

ASPEER::MakeMaker::Markdown::Pod - keep Perl documentation in Markdown and ship it as POD

# GITHUB ATTESTATIONS

The release workflow generates [GitHub artifact attestations](https://docs.github.com/en/actions/concepts/security/artifact-attestations)
for distribution archives. Install the [GitHub CLI](https://cli.github.com/)
with `gh attestation` support and authenticate with `gh auth login`.

Download `ASPEER-MakeMaker-Markdown-Pod-VERSION.tar.gz` from a GitHub release,
MetaCPAN, or a CPAN mirror, replace `VERSION`, and verify it with:

```sh
gh attestation verify ASPEER-MakeMaker-Markdown-Pod-VERSION.tar.gz --repo aspeer/pm-ASPEER-MakeMaker-Markdown-Pod
```

A successful verification confirms that the archive checksum matches an
attestation from this repository. The workflow publishes the same archive to
GitHub Releases and CPAN. Older releases and GitHub's automatically generated
source-code archives are not covered.

# SYNOPSIS

With `ExtUtils::MakeMaker`:

```bash
perl -MASPEER::MakeMaker::Markdown::Pod Makefile.PL
make doc
```

The `markpod` command is installed by `Markdown::Pod::Embed`:

```bash
markpod --inplace lib/My/Module.pm
markpod --extract-markdown lib/My/Module.pm > lib/My/Module.pm.md
markpod --extract-pod lib/My/Module.pm
```

For processing without MakeMaker, use the engine directly:

```perl
use Markdown::Pod::Embed;

my $markpod = Markdown::Pod::Embed->new({
    dialect  => 'GitHub',
    nobackup => 1,
});

my $changed = $markpod->markpod_process_and_update('lib/My/Module.pm');
```

The MakeMaker import hook adds `doc` and `readme` targets to the generated
Makefile. It also retains the project's established MakeMaker configuration,
dependency, metadata, provenance, and install-map behavior.

The same complete integration can be enabled optionally inside `Makefile.PL`:

```perl
use ExtUtils::MakeMaker;

eval {
    require ASPEER::MakeMaker::Markdown::Pod;
    ASPEER::MakeMaker::Markdown::Pod->import();
    1;
};

WriteMakefile(
    NAME         => 'Example',
    VERSION_FROM => 'lib/Example.pm',
);
```

The import must run before `WriteMakefile`. If the module cannot be loaded, the
silent `eval` leaves the ordinary MakeMaker configuration in place.

# DESCRIPTION

`ASPEER::MakeMaker::Markdown::Pod` lets a distribution keep documentation in Markdown while
still embedding generated POD in Perl modules and scripts. The Markdown source
can live in a sidecar file such as `lib/My/Module.pm.md`, or inside a POD block
marked with `=begin markdown` and `=end markdown`.

When a file is processed, `Markdown::Pod::Embed` converts the Markdown to POD
and writes a merged documentation block back to the Perl file.
The merged block keeps the original Markdown and appends the generated POD, so
the Markdown remains editable while tools such as `perldoc`, `pod2man`,
`ABSTRACT_FROM`, and CPAN indexers can consume normal POD.

# MARKDOWN SOURCE PRECEDENCE

The processor uses a simple precedence rule:

1. A same-path sidecar file ending in `.md` wins.
2. Otherwise, embedded Markdown in a POD block is used.
3. Otherwise, existing plain POD is left unchanged.

For example, `lib/My/Module.pm.md` is the source for
`lib/My/Module.pm`. For a script, `bin/tool.pl.md` is the source for
`bin/tool.pl`.

# MAKE TARGETS

The MakeMaker integration is deliberately separate from Markdown processing:

- `ASPEER::MakeMaker::Markdown::Pod` inherits the common lifecycle behavior
  from `ASPEER::MakeMaker`.
- `ASPEER::MakeMaker::MM::Import` installs and implements the MakeMaker
  lifecycle hooks.
- `ASPEER::MakeMaker::Markdown::Pod::MM` defines and runs the `doc` and `readme` targets.
- `Markdown::Pod::Embed` selects Markdown, converts it to POD, and updates the
  Perl source.

The integration is loaded automatically when `ASPEER::MakeMaker::Markdown::Pod` is
imported by `Makefile.PL`. It preserves local library paths and the active
MakeMaker extensions in the generated global `PERLRUN` command.

`make doc`
: Recursively converts DocBook article XML beneath `doc/` to sibling Markdown
  files, independently of `MANIFEST`. It then processes Markdown sidecars listed
  in `MANIFEST` and merges them into matching `.pm`, `.pl`, or executable targets.
  Markdown files under `t/` are ignored so test fixtures are not rewritten.

`make readme`
: Builds `README` from an existing `README.md`. When neither README file exists,
  it first creates a regular `README.md` from sidecar or embedded Markdown in
  the `VERSION_FROM` file. An existing plain `README` without `README.md` is
  left unchanged, and no file is created when `VERSION_FROM` has no Markdown.

Status output is written to STDERR. Normal output is intentionally compact:

```text
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: starting merge
markpod: lib/My/Module.pm.md -> lib/My/Module.pm: finished, updated pod
```

# DOGFOODING

This distribution uses its own sidecar workflow. The important modules and the
public integration classes have adjacent Markdown files:

```text
lib/ASPEER/MakeMaker/Markdown/Pod.pm.md
lib/ASPEER/MakeMaker/Markdown/Pod/MM.pm.md
lib/ASPEER/MakeMaker/Markdown/Pod/Constant.pm.md
lib/ASPEER/MakeMaker/Markdown/Pod/MM/Constant.pm.md
README.md
```

Running `make doc` regenerates embedded POD in the modules from those files.
Running `make readme` regenerates `README`.

# DEPENDENCIES

The conversion implementation is supplied by `Markdown::Pod::Embed`. The
`ASPEER::MakeMaker::Markdown::Pod` class retains the processing methods as a compatibility
facade, while new conversion-only code can use `Markdown::Pod::Embed` directly.
The MakeMaker lifecycle and utility implementation is supplied by
`ASPEER::MakeMaker`; this distribution does not vendor copies of its
`MM::Import` or `MM::Util` modules.

README generation uses `pandoc`. If `pandoc` is not available, README generation
will fail and the README-specific test is skipped.

# AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au>

# LICENSE AND COPYRIGHT

This file is part of ASPEER::MakeMaker::Markdown::Pod.

This software is copyright (c) 2026 by Andrew Speer
<andrew.speer@isolutions.com.au>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

Full license text is available at:

<http://dev.perl.org/licenses/>
