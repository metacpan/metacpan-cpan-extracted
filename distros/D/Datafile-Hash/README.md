# Datafile::Hash - README

**Datafile::Hash** is a lightweight pure-Perl module for reading and writing key-value and INI-style configuration files with sections.

Key features:
- No external dependencies
- Safe atomic writes (temp file + rename)
- Consistent return values and error handling
- Verbose messaging support
- UTF-8 encoding
- Support for flat key-value files and INI-style files with nested sections

[![Perl](https://img.shields.io/badge/perl-5.014%2B-brightgreen)](https://www.perl.org/)
[![License](https://img.shields.io/badge/license-Perl-orange)](https://dev.perl.org/licenses/)

## Installation

    perl Makefile.PL
    make
    make test
    make install

## Synopsis

    use Datafile::Hash qw(readhash writehash);

    my %config;

    readhash('config.ini', \%config, {
        delimiter => '=',      # triggers INI mode
        group     => 2,        # nested hashes (default)
    });

    # $config{database}{host} = 'localhost'

    writehash('config.ini', \%config, {
        backup  => 1,
        comment => ['Auto-generated', scalar localtime],
    });

## Functions

- **readhash($file, $hash_ref, \%opts)**
  Returns `($entry_count, \@messages, \%groups_seen)`
  - `\%groups_seen` is only populated in INI mode

- **writehash($file, $hash_ref, \%opts)**
  Returns `($entry_count, \@messages)`

## Key Options

- delimiter       => '='     (default)
  '=' or ':' → INI mode with sections and quoting
  Anything else → flat key-value mode
- group           => 2       (default)
  0 = flat hash (ignore sections)
  1 = dotted keys (section.sub.key)
  2 = nested hashes (recommended)
- key_fields      => 1       (flat mode only)
- skip_empty      => 1
- skip_headers    => 0       (skip leading banner lines)
- comment_char    => '#'
- search          => undef
- verbose         => 0
- backup          => 0 | 1   (writehash)
- comment         => undef   (writehash: top comments)
- prot            => 0660    (writehash)

## INI Mode Features

- [section.subsection] headers
- Quoted values with escaped quotes (\")
- Automatic quoting on write when needed

## License

This module is free software.
You can redistribute it and/or modify it under the same terms as Perl itself.

See the official Perl licensing terms: https://dev.perl.org/licenses/
