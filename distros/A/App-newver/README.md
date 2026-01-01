# newver
**newver** is a Perl program for scanning software webpages for new software
versions and reports them.

## Building
**newver** can be ran on both Unix-like and Windows systems.

**newver** depends on the following:
* `perl` (>= `5.16`)
* `HTML::TreeBuilder`
* `LWP`
* `LWP::Protocol::https`
* `Parallel::ForkManager`
* `URI`

Once the aforemntioned dependencies are installed, the following commands can
be ran to build and install **newver**:
```bash
make
make test
make install
```
Consult the documentation for `ExtUtils::MakeMaker` for information on
configuring the build process.

## Usage
For more complete documentation on the usage of **newver**, please consult the
**newver** manual.
```bash
man newver
perldoc ./bin/newver
```

**newver** reads configuration from an INI file given to it as a
command-line argument. The INI file contains a list of programs and various
parameters to use when fetching web pages and scanning for new versions. Below
is an example scan file:
```ini
# Example scan file
# Lines starting with '#' are read as comments and ignored
[noss]
    Version = 2.00
    Page = https://www.cpan.org/authors/id/S/SA/SAMYOUNG/
    # Look for <a> hrefs that match the following
    Match = WWW-Noss-@VERSION@.tar.gz

[perl]
    # Look for current version in Makefile.PL matching the regex
    VersionScan = Makefile.PL -- MIN_PERL_VERSION => '@VERSION@'
    Page = https://github.com/repology/libversion/tags
    Match = @VERSION@.tar.gz

[libversion]
    Version = 3.0.3
    Page = https://github.com/repology/libversion/tags
    Match = @VERSION@.tar.gz

```

## Author
**newver** was written by Samuel Young <samyoung12788@gmail.com>.

This project's source can be found in its
[Codeberg page](https://codeberg.org/1-1sam/newver). Comments and pull requests
are welcome.

## Copyright
Copyright (C) 2025, Samuel Young.

This program is free software; you can redistribute it and/or modify it under
the terms of the Artistic License 2.0.
