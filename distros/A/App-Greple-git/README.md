[![Actions Status](https://github.com/kaz-utashiro/greple-git/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-git/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-git.svg)](https://metacpan.org/release/App-Greple-git)
# NAME

git - Greple git module

# SYNOPSIS

    greple -Mgit ...

# DESCRIPTION

App::Greple::git is a greple module to support git command

# OPTIONS

- **--color-blame-line**, **--color-blame**
- **--color-blame-label**

    Read [git-blame(1)](http://man.he.net/man1/git-blame) output and apply unique color for each commit
    id.  Option **--color-blame** and **--color-blame-line** colorize whole
    line, while **--color-blame-label** does only labels.

    Set `$HOME/.gitconfig` like this:

        [pager]
            blame = greple -Mgit --color-blame-line | env LESSANSIENDCHARS=mK less -cR

    <div>
            <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-git/main/images/git-blame-small.jpg">
    </div>

    <div>
            <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-git/main/images/git-blame-label-small.jpg">
    </div>

- **--color-header-by-author**

    Colorize the commit header in a different color based on the author field.

- **--color-header-by-field** _field_

    Generic version of log header colorization.  Take a case-insensitive
    field name as a parameter.  **--color-header-by-author** is defined as
    follows:

        option --color-header-by-author --color-header-by-field Author

- **--only-git-files**

    Only files under git control from a given file are processed, all
    other files are ignored.  This option is intended to be used in
    combination with **--glob** or other options that allow many files to
    be processed at once.  To target all files under git control, use the
    **--git** option in the **-Mdig** module.

# ENVIRONMENT

- **LESS**
- **LESSANSIENDCHARS**

    Since **greple** produces ANSI Erase Line terminal sequence, it is
    convenient to set **less** command understand them.

        LESS=-cR
        LESSANSIENDCHARS=mK

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::git

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

[App::sdif](https://metacpan.org/pod/App%3A%3Asdif): git diff support

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021-2023 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
