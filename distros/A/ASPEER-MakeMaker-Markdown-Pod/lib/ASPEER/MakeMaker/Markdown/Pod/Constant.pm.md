# NAME

ASPEER::MakeMaker::Markdown::Pod::Constant - constants for ASPEER::MakeMaker::Markdown::Pod

# SYNOPSIS

```perl
use ASPEER::MakeMaker::Markdown::Pod::Constant;

my $default_dialect = $OPTION_HR->{dialect};
my $pandoc          = $PANDOC_EXE;
my $cmd             = $PANDOC_CMD_MD2TEXT_CR->($pandoc, '-');
```

# DESCRIPTION

`ASPEER::MakeMaker::Markdown::Pod::Constant` defines exported constants used by the core
processor and command-line tool.

The constants are stored in `%Constant`, exported as package variables, and can
be overridden by local configuration files loaded at compile time.

# CONSTANTS

`$OPTION_HR`
: Default processor options. The current default Markdown dialect is `GitHub`.

`$PANDOC_EXE`
: Path to `pandoc` discovered from `PATH`, or an empty string when `pandoc` is
  not available.

`$PANDOC_CMD_MD2TEXT_CR`
: Code reference that builds the `pandoc` command used to render Markdown to
  plain text for README generation.

# FUNCTIONS

## bin_find

```perl
my $path = ASPEER::MakeMaker::Markdown::Pod::Constant::bin_find(qw(pandoc pandoc.exe));
```

Searches `PATH` for the first executable-like file matching one of the supplied
names and returns a canonical path. If no candidate is found, it returns an
empty string.

# LOCAL OVERRIDES

Local constants can be overridden by files loaded from:

```text
lib/ASPEER/MakeMaker/Markdown/Pod/Constant.pm.local
~/.ASPEER::MakeMaker::Markdown::Pod::Constant.local
```

Those files are expected to return a hash reference suitable for merging into
`%Constant`.

# SEE ALSO

`ASPEER::MakeMaker::Markdown::Pod`

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
