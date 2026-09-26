# NAME

ASPEER::MakeMaker::Markdown::Pod - MakeMaker integration for Markdown-maintained POD

# SYNOPSIS

In `Makefile.PL`:

```perl
use ExtUtils::MakeMaker;
use ASPEER::MakeMaker::Markdown::Pod;

WriteMakefile(
    NAME         => 'Example',
    VERSION_FROM => 'lib/Example.pm',
);
```

This adds `doc` and `readme` targets to the generated Makefile.

For optional integration, load and import the module before `WriteMakefile`:

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

If the optional module cannot be loaded, MakeMaker continues without the
additional lifecycle hooks and documentation targets. The equivalent explicit
command-line activation is:

```text
perl -MASPEER::MakeMaker::Markdown::Pod Makefile.PL
```

# DESCRIPTION

`ASPEER::MakeMaker::Markdown::Pod` integrates documentation maintenance and the project's
established distribution conventions with `ExtUtils::MakeMaker`. Importing it
from `Makefile.PL` installs the MakeMaker lifecycle hooks used to configure the
generated Makefile, package metadata and install map, Git-SHA provenance, and
documentation targets. The generated global `PERLRUN` preserves
the active local library paths and MakeMaker extensions.

The responsibilities are deliberately separated:

- `ASPEER::MakeMaker::Markdown::Pod` inherits the common MakeMaker behavior
  from `ASPEER::MakeMaker`.
- `ASPEER::MakeMaker::MM::Import` installs and implements the MakeMaker
  lifecycle hooks.
- `ASPEER::MakeMaker::Markdown::Pod::MM` generates and executes the `doc` and `readme`
  targets.
- `Docbook::Convert::Pandoc` discovers DocBook articles beneath `doc/` and
  converts them to sibling Markdown files.
- `Markdown::Pod::Embed` selects Markdown, converts it to POD, and updates Perl
  source files.

The `doc` target discovers DocBook articles beneath `doc/` independently of
`MANIFEST`, converts them to sibling Markdown files, and then processes Markdown
sidecars listed in `MANIFEST` for matching Perl modules, scripts, and declared
executable files. `readme` renders the best available README Markdown source as
plain text.

# PROCESSOR COMPATIBILITY

For compatibility with earlier releases, this package inherits the processing
methods supplied by `Markdown::Pod::Embed`. New code that only converts or
updates Markdown/POD should use `Markdown::Pod::Embed` directly; it does not
need MakeMaker and does not install MakeMaker hooks.

# ERRORS

MakeMaker hook errors and target failures are fatal. Importing this module from
a program other than `Makefile.PL` does not alter `ExtUtils::MakeMaker`.

# SEE ALSO

`ASPEER::MakeMaker`, `ASPEER::MakeMaker::Markdown::Pod::MM`,
`ASPEER::MakeMaker::MM::Import`,
`Markdown::Pod::Embed`, `ExtUtils::MakeMaker`

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
