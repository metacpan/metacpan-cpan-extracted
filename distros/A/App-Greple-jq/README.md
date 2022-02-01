[![Actions Status](https://github.com/kaz-utashiro/greple-jq/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-jq/actions)
# NAME

greple -Mjq - greple module for jq frontend

# SYNOPSIS

greple -Mjq --glob JSON-DATA --IN label pattern

# DESCRIPTION

This is an experimental module for [App::Greple](https://metacpan.org/pod/App::Greple) command to provide
interface for [jq(1)](http://man.he.net/man1/jq) command.

You can search object `.commit.author.name` includes `Marvin` like this:

    greple -Mjq --IN .commit.author.name Marvin

Search first `name` field including `Marvin` under `.commit`:

    greple -Mjq --IN .commit..name Marvin

Search any `author.name` field including `Marvin`:

    greple -Mjq --IN author.name Marvin

Please be aware that this is just a text matching tool for indented
result of [jq(1)](http://man.he.net/man1/jq) command.  So, for example, `.commit.author`
includes everything under it and it maches `committer` field name.
Use [jq(1)](http://man.he.net/man1/jq) filter for more complex and precise operation.

# CAUTION

[greple(1)](http://man.he.net/man1/greple) commands read entire input before processing.  So it
should not be used for large amount of data or inifinite stream.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::jq
    or
    $ curl -sL http://cpanmin.us | perl - App::Greple::jq

# OPTIONS

- **--IN** _label_ _pattern_

    Search _pattern_ included in _label_ field.

    Chacater `%` can be used as a wildcard in _label_ string.  So
    `%name` matches labels end with `name`, and `name%` matches labels
    start with `name`.

    If the label is simple string like `name`, it matches any level of
    JSON data.

    If the label string contains period (`.`), it is considered as a
    nested labels.  Name `.name` maches only `name` label at the top
    level.  Name `process.name` maches only `name` entry of some
    `process` hash.

    If labels are separated by two or more dots (`..`), they don't have
    to have direct relationship.

# LABEL SYNTAX

- **.file**

    `file` at the top level.

- **.file.path**

    `path` under `.file`.

- **.file..path**

    `path` in descendants of `.file`.

- **path**

    `path` at any level.

- **file.path**

    `file.path` at any level.

- **file..path**

    Some `path` in descendatns of some `file`.

- **%path**

    Any labels end with `path`.

- **path%**

    Any labels start with `path`.

- **%path%**

    Any labels include `path`.

# EXAMPLES

Search from any `name` labels.

    greple -Mjq --glob procmon.json --IN name _mina

Search from `.process.name` label.

    greple -Mjq --glob procmon.json --IN .process.name _mina

Object `.process.name` contains `_mina` and `.event` contains
`FORK`.

    greple -Mjq --glob procmon.json --IN .process.name _mina --IN .event FORK

Object `ancestors` contains `339` and `.event` contains `FORK`.

    greple -Mjq --glob procmon.json --IN ancestors 339 --IN event FORK

Object `*pid` labels contains 803.

    greple -Mjq --glob procmon.json --IN %pid 803

Object any <path> contains `_mira` under `.file` and `.event` contains `WRITE`.

    greple -Mjq --glob filemon.json --IN .file..path _mina --IN .event WRITE

# TIPS

Use `--all` option to show entire data.

Use `--nocolor` option or set `NO_COLOR=1` to disable colored
output.

Use `--blockend=` option to cancel showing block separator.

Use `-o` option to show only matched part.

Sine this module implements original search funciton, [greple(1)](http://man.he.net/man1/greple)
**-i** does not take effect.  Set modifier in regex like
`(?i)pattern` if you want case-insensitive match.

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App::Greple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
