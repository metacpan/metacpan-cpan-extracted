[![Actions Status](https://github.com/kaz-utashiro/sdif-tools/workflows/test/badge.svg)](https://github.com/kaz-utashiro/sdif-tools/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-sdif.svg)](https://metacpan.org/release/App-sdif)
# NAME

App::sdif - sdif and family tools, cdif and watchdiff

# SYNOPSIS

sdif f1 f2

diff -c f1 f2 | cdif

git diff | sdif -n

watchdiff df

# DESCRIPTION

**sdif-tools** are composed by **sdif** and related tools including
**cdif** and **watchdiff**.

**sdif** prints diff output in side-by-side format.

**cdif** adds visual effect for diff output, comparing lines in
word-by-word, or character-by-character bases.

**watchdiff** calls specified command repeatedly, and print the output
with visual effect to emphasize modified part.

See individual manual of each command for detail.

# INSTALL

## CPANM

    $ cpanm App::sdif
    or
    $ curl -sL http://cpanmin.us | perl - App::sdif

## GIT

Those are sample configurations using **sdif** family in git
environment.  You need to install **mecab** command to use **--mecab**
option.

        ~/.gitconfig
                [pager]
                        log  = sdif | less
                        show = sdif | less
                        diff = sdif | less

        ~/.sdifrc
                option default -n --margin=4

        ~/.cdifrc
                option default --mecab

        ~/.profile
                export LESS="-cR"
                export LESSANSIENDCHARS="mK"

You can write everything in ~/.gitconfig:

        log  = sdif -n --margin=4 --mecab | env LESSANSIENDCHARS=mK less -cR
        show = sdif -n --margin=4 --mecab | env LESSANSIENDCHARS=mK less -cR
        diff = sdif -n --margin=4 --mecab | env LESSANSIENDCHARS=mK less -cR

# SEE ALSO

[sdif](https://metacpan.org/pod/sdif), [cdif](https://metacpan.org/pod/cdif), [watchdiff](https://metacpan.org/pod/watchdiff)

[Getopt::EX](https://metacpan.org/pod/Getopt::EX)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 1992- Kazumasa Utashiro.

These commands and libraries are free software; you can redistribute
it and/or modify it under the same terms as Perl itself.
