[![Actions Status](https://github.com/kaz-utashiro/greple-update/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-update/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-update.svg)](https://metacpan.org/release/App-Greple-update)
# NAME

update - Greple module to update file content

# SYNOPSIS

greple -Mupdate

Options:

    --update       replace file content
    --with-backup  make backup files

    --diff         produce diff output
    -U#            specify unified diff context length

    --discard      simply discard the output

# VERSION

Version 1.03

# DESCRIPTION

This **greple** module substitute the target file content by command
output.  For example, next command replace all words in the file to
uppercase.

    greple -Mupdate '\w+' --cm 'sub{uc}' --update file

Above is a very simple example but you can implement arbitrarily
complex function in conjunction with other various **greple** options.

You can check how the file will be edited by **--diff** option.

    greple -Mupdate '\w+' --cm 'sub{uc}' --diff file

Command **sdif** or **cdif** would be useful to see the difference
visually.

    greple -Mupdate '\w+' --cm 'sub{uc}' --diff file | cdif

This module has been spun off from [App::Greple::subst](https://metacpan.org/pod/App%3A%3AGreple%3A%3Asubst) module.
Consult it for more practical use case.

# OPTIONS

- **--update**
- **--update::update**

    Update the target file by command output.  Entire file content is
    produced and any color effects are canceled.  Without this option,
    **greple** behaves as normal operation, that means only matched lines
    are printed.

    File is not touched as far as its content does not change.

    The file is also not updated if the output is empty.  This is to
    prevent the contents of the file from being erased if none of the
    match strings are included.  If you want to intentionally empty a
    file, you need to think of another way.

- **--with-backup**\[=_suffix_\]

    Backup original file with `.bak` suffix.  If optional parameter is
    given, it is used as a suffix string.  If the file exists, `.bak_1`,
    `.bak_2` ... are used.

- **--discard**
- **--update::discard**

    Simply discard the command output without updating file.

- **--diff**
- **--update::diff**

    Option **-diff** produce diff output of original and converted text.
    Option **-U#** can be used to specify context length.

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

Copyright 2022-2024 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
