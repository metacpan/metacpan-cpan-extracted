# NAME

git - Greple git module

# SYNOPSIS

    greple -Mgit ...

# DESCRIPTION

App::Greple::git is a greple module to handle git output.

# OPTIONS

- **--color-blame**

    Read [git-blame(1)](http://man.he.net/man1/git-blame) output and apply unique color for each
    commit ids.

    Set `$HOME/.gitconfig` like this:

        [pager]
            blame = greple -Mgit --color-blame | less -cR

    <div>
            <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-git/main/images/git-blame-small.png">
    </div>

# ENVIRONMENT

- **LESS**
- **LESSANSIENDCHARS**

    Since **greple** produces ANSI Erase Line terminal sequence, it is
    convenient to set **less** command understand them.

        LESS=-cR
        LESSANSIENDCHARS=mK

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021-2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
