[![Actions Status](https://github.com/kaz-utashiro/greple-update/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/greple-update/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-update.svg)](https://metacpan.org/release/App-Greple-update)
# NAME

update - Greple module to update file content

# SYNOPSIS

greple -Mupdate

Options:

    --update       replace file content
    --with-backup  make backup files

    --diff         produce diff output
    -U#, --diff-context=#  unified diff context length
    --diff-command=#       diff command

    --discard      simply discard the output

# VERSION

Version 1.05

# DESCRIPTION

This **greple** module replaces the content of the target file with the
output of the command.  For example, the next command changes all words
in the file to uppercase.

    greple -Mupdate '\w+' --cs uc --update file

This is a very simple example, but you can implement arbitrarily
complex functions in conjunction with other **greple** options.

You can check how the file will be edited with the **--diff** option.

    greple -Mupdate '\w+' --cs uc --diff file

Command **sdif** or **cdif** would be useful to see the difference
visually.

    greple -Mupdate '\w+' --cs uc --diff file | cdif

To pass only the matched parts through an external command and write
the result back, use it with [App::Greple::tee](https://metacpan.org/pod/App%3A%3AGreple%3A%3Atee).  Give **-Mupdate**
before **-Mtee**, because the arguments of **-Mtee** up to `--` are the
command, and **--update** after the `--`:

    greple -Mupdate -Mtee tr a-z A-Z -- --update '\w+' file

Calling a function, as in `-Mtee '&ansicolumn'`, requires
[Command::Run](https://metacpan.org/pod/Command%3A%3ARun) 1.05 or later.

This module has been spun off from the [App::Greple::subst](https://metacpan.org/pod/App%3A%3AGreple%3A%3Asubst) module.
Consult it for more practical use cases.

# OPTIONS

There are two kinds of options for this module, such as `--diff` and
`--update::diff`.  This is to avoid option name conflicts when used
in combination with other modules.  If you are using this module from
another module and want to use the `--diff` option in it, call as
`--update::diff`.

- **--update**
- **--update::update**

    Update the target file with the command output.  The entire file
    content is produced and any color effects are canceled.  Without this
    option, **greple** behaves as usual, that is, only matched lines are
    printed.

    The file is not touched as long as its content does not change.

    The file is also not updated if the output is empty.  This is to
    prevent the contents of the file from being erased if none of the
    match strings are included.  If you want to intentionally empty a
    file, you need to think of another way.

- **--with-backup**\[=_suffix_\]

    Back up the original file with the `.bak` suffix.  If the optional
    parameter is given, it is used as the suffix.  If the backup file
    exists, `.bak_1`, `.bak_2` ... are used.

    Give the suffix with `=`.  An argument that follows the option is
    taken as the suffix, so in `--with-backup file` the name of the file
    is lost.  Put another option after it or use
    `-Mupdate::config(with_backup)` in that case.

- **--discard**
- **--update::discard**

    Simply discard the command output without updating the file.  This option
    can be used when the output of the command is not needed and only side
    effects are expected.

- **--diff**
- **--update::diff**

    Produce a diff of the original and the converted text.

- **-U**_n_, **--diff-context**=_n_

    Context length of the unified diff produced by **--diff**.

- **--diff-command**=_command_

    Diff command used by **--diff**.  Default is `diff -u`.  If the context
    length is given, `diff -U`_n_ is used instead.

# CONFIGURATION

Module parameters can be set with [Getopt::EX::Config](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AConfig) using the
following syntax:

    greple -Mupdate::config(with_backup) ...
    greple -Mupdate::config(with_backup=.orig) ...
    greple -Mupdate::config(diff_context=3) ...

Options given on the command line override them.  Available
parameters are:

    with_backup    back up the file, as --with-backup
    diff_context   context length of diff, as --diff-context
    diff_command   diff command, as --diff-command (default: diff -u)
    update_suffix  backup suffix (default: none)
    remember       compare with the content that was read, not with
                   the file, in --diff (default: 1)

# LIMITATIONS

Files are always written in UTF-8.  A file read with **--icode** in
another encoding, such as Shift-JIS, is converted to UTF-8, and
**--ocode** has no effect on the file.

Binary data read with `--icode=binary` is not preserved: bytes
outside of ASCII are changed when the file is written.  A file that is
not valid UTF-8 is skipped unless **--icode** is given.

Greple's **--of** option does not take effect with **--update**: the
file is written without the filter.

Standard input has no file to go back to: with **--update**, the result
is written to a file named `-`.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::update

## GITHUB

    $ cpanm https://github.com/kaz-utashiro/greple-update.git

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[App::Greple::update](https://metacpan.org/pod/App%3A%3AGreple%3A%3Aupdate), [https://github.com/kaz-utashiro/greple-update](https://github.com/kaz-utashiro/greple-update)

[App::Greple::subst](https://metacpan.org/pod/App%3A%3AGreple%3A%3Asubst), [https://github.com/kaz-utashiro/greple-subst](https://github.com/kaz-utashiro/greple-subst)

[App::sdif](https://metacpan.org/pod/App%3A%3Asdif), [App::cdif](https://metacpan.org/pod/App%3A%3Acdif)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022-2026 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
