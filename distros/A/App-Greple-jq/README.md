[![Actions Status](https://github.com/kaz-utashiro/greple-jq/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-jq/actions)
# NAME

greple -Mjq - greple module to search JSON data with jq

# SYNOPSIS

greple -Mjq --glob JSON-DATA --IN label pattern

# VERSION

Version 0.04

# DESCRIPTION

This is an experimental module for [App::Greple](https://metacpan.org/pod/App::Greple) to search JSON
formatted text using [jq(1)](http://man.he.net/man1/jq) as a backend.

Search top level json object which includes both `Marvin` and
`Zaphod` somewhare in its text representation.

    greple -Mjq 'Marvin Zaphod'

You can search object `.commit.author.name` includes `Marvin` like this:

    greple -Mjq --IN .commit.author.name Marvin

Search first `name` field including `Marvin` under `.commit`:

    greple -Mjq --IN .commit..name Marvin

Search any `author.name` field including `Marvin`:

    greple -Mjq --IN author.name Marvin

Search `name` is `Marvin` and `type` is `Robot` or `Android`:

    greple -Mjq --IN name Marvin --IN type 'Robot|Android'

Please be aware that this is just a text matching tool for indented
result of [jq(1)](http://man.he.net/man1/jq) command.  So, for example, `.commit.author`
includes everything under it and it maches `committer` field name.
Use [jq(1)](http://man.he.net/man1/jq) filter for more complex and precise operation.

# CAUTION

[greple(1)](http://man.he.net/man1/greple) commands read entire input before processing.  So it
should not be used for gigantic data or inifinite stream.

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

- **--NOT** _label_ _pattern_

    Specify negative condition.

- **--MUST** _label_ _pattern_

    Specify required condition.  If there is one or more required
    condition, all other positive rules move to optional.  They are not
    required but highliged if exist.

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

    greple -Mjq --IN name _mina

Search from `.process.name` label.

    greple -Mjq --IN .process.name _mina

Object `.process.name` contains `_mina` and `.event` contains
`EXEC`.

    greple -Mjq --IN .process.name _mina --IN .event EXEC

Object `ppid` is 803 and `.event` contains `FORK` or `EXEC`.

    greple -Mjq --IN ppid 803 --IN event 'FORK|EXEC'

Object `name` is `_mina` and `.event` contains `CREATE`.

    greple -Mjq --IN name _mina --IN event 'CREATE'

Object `ancestors` contains `1132` and `.event` contains `EXEC`
with `arguments` highlighted.

    greple -Mjq --IN ancestors 1132 --IN event EXEC --IN arguments .

Object `*pid` label contains 803.

    greple -Mjq --IN %pid 803

Object any <path> contains `_mira` under `.file` and `.event`
contains `WRITE`.

    greple -Mjq --IN .file..path _mina --IN .event WRITE

# TIPS

Use `--all` option to show entire data.

Use `--nocolor` option or set `NO_COLOR=1` to disable colored
output.

Use `-o` option to show only matched part.

Use `--blockend=` option to cancel showing block separator.

Sine this module implements original search funciton, [greple(1)](http://man.he.net/man1/greple)
**-i** does not take effect.  Set modifier in regex like
`(?i)pattern` if you want case-insensitive match.

Use `-Mjq::debug=` to see actual regex.

Use `--color=always` and set `LESSANSIENDCHARS=mK` if you want to
see the output using [less(1)](http://man.he.net/man1/less).  Put next line in your `~/.greplerc`
to enable colored output always.

    option default --color=always

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App::Greple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
