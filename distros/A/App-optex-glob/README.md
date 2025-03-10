[![Actions Status](https://github.com/kaz-utashiro/optex-glob/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/optex-glob/actions)
# NAME

glob - optex filter to glob filenames

# SYNOPSIS

optex -Mglob \[ option \] pattern -- command

# DESCRIPTION

This module is used to select filenames given as arguments by pattern.

For example, the following will pass only files matching `*.c` from
`*/*` as arguments to `ls`.

    optex -Mglob '*.c' -- ls -l */*

Only existing file names will be selected.  Any arguments that do not
correspond to files will be passed through as is.  In this example,
the command name and options remain as they are because no
corresponding file exists.  Be aware that the existence of a
corresponding file for unexpected parameter could lead to confusing
results.

There are several unique options that are valid only for this module.

- **!**_pattern_
- **--exclude** _pattern_

    Option `--exclude` will mean the opposite.

        optex -Mglob --exclude '*.c' -- ls */*

    Preceding pattern with `!` will also exclude the pattern.

        optex -Mglob '!*.c' -- ls */*

    If the `--exclude` option is used with positive patterns, the exclude
    pattern takes precedence.  The following command selects files
    matching `*.c`, but excludes those begin with a capital letter.

        optex -Mglob --exclude '[A-Z]*' '*.c' -- ls */*

    This opiton can be used multiple times.

- **--regex**

    If the `--regex` option is given, patterns are evaluated as a regular
    expression instead of a glob pattern.

        optex -Mglob --regex '\.c$' -- ls */*

- **--path**

    With the `--path` option it matches against the entire path, not just
    the filename.

        optex -Mglob --path '^*_test/' -- ls */*

# CONSIDERATION

You should also consider using the extended globbing (extglob) feature
of [bash(1)](http://man.he.net/man1/bash) or similar. For example, you can use `!(*.EN).md`,
which would specify files matching `*.md` minus those matching
`*.EN.md`.

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2024-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
