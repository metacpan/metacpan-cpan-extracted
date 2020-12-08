[![Build Status](https://travis-ci.com/kaz-utashiro/optex-textconv.svg?branch=master)](https://travis-ci.com/kaz-utashiro/optex-textconv)
# NAME

textconv - optex module to replace document file by its text contents

# VERSION

Version 0.11

# SYNOPSIS

optex command -Mtextconv

optex command -Mtc (alias module)

optex command -Mtextconv::load=pandoc

# DESCRIPTION

This module replaces several sort of filenames by node representing
its text information.  File itself is not altered.

For example, you can check the text difference between MS word files
like this:

    $ optex diff -Mtextconv OLD.docx NEW.docx

If you have symbolic link named **diff** to **optex**, and following
setting in your `~/.optex.d/diff.rc`:

    option default --textconv
    option --textconv -Mtextconv $<move>

Next command simply produces the same result.

    $ diff OLD.docx NEW.docx

# MICROSOFT DOCUMENTS

Microsoft office document in XML format (.docx, .pptx, .xlsx) is
converted to plain text by original code implemented in
`App::optex::textconv::msdoc` module.  Algorithm used in this module
is extremely simple, and consequently runs fast.

Two module are included in this distribution to use other external
converter program, **pandoc** and **tika**, those implement much more
serious algorithm.  They can be invoked by calling **load** function
with module declaration like:

    optex -Mtextconv::load=pandoc

    optex -Mtextconv::load=tika

# INSTALL

## CPANM

    $ cpanm App::optex::textconv
    or
    $ curl -sL http://cpanmin.us | perl - App::optex::textconv

## GIT

These are sample configurations using [App::optex::textconv](https://metacpan.org/pod/App::optex::textconv) in git
environment.

        ~/.gitconfig
                [diff "msdoc"]
                        textconv = optex -Mtextconv cat
                [diff "pdf"]
                        textconv = optex -Mtextconv cat
                [diff "jpg"]
                        textconv = optex -Mtextconv cat

        ~/.config/git/attributes
                *.docx   diff=msdoc
                *.pptx   diff=msdoc
                *.xlmx   diff=msdoc
                *.pdf    diff=pdf
                *.jpg    diff=jpg

About other GIT related setting, see
[https://github.com/kaz-utashiro/sdif-tools](https://github.com/kaz-utashiro/sdif-tools).

# SEE ALSO

[https://github.com/kaz-utashiro/optex](https://github.com/kaz-utashiro/optex)

[https://github.com/kaz-utashiro/optex-textconv](https://github.com/kaz-utashiro/optex-textconv)

[https://qiita.com/kaz-utashiro/items/23fd825bd325240592c2](https://qiita.com/kaz-utashiro/items/23fd825bd325240592c2)

[https://github.com/kaz-utashiro/sdif-tools](https://github.com/kaz-utashiro/sdif-tools)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2019-2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
