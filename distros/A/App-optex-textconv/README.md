[![Actions Status](https://github.com/kaz-utashiro/optex-textconv/workflows/test/badge.svg)](https://github.com/kaz-utashiro/optex-textconv/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-optex-textconv.svg)](https://metacpan.org/release/App-optex-textconv)
# NAME

textconv - optex module to replace document file by its text contents

# VERSION

Version 0.12

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

## FILE FORMATS

- msdoc

    Microsoft office format files in XML (.docx, .pptx, .xlsx, .docm,
    .pptm, .xlsm).
    See [App::optex::textconv::msdoc](https://metacpan.org/pod/App::optex::textconv::msdoc).

- pdf

    Use [pdftotext(1)](http://man.he.net/man1/pdftotext) command to covert PDF format.
    See [App::optex::textconv::pdf](https://metacpan.org/pod/App::optex::textconv::pdf).

- jpeg

    JPEG files is converted to their exif information (.jpeg, .jpg).

- http

    Name start with `http://` or `https://` is converted to text data
    translated by [w3c(1)](http://man.he.net/man1/w3c) command.

- pandoc

    Use [pandoc](https://pandoc.org/) command to translate Microsoft
    office document in XML format.
    See [App::optex::textconv::pandoc](https://metacpan.org/pod/App::optex::textconv::pandoc).

- tika

    Use [Pache Tika](https://tika.apache.org/) command to translate
    Microsoft office document in XML and non-XML format.
    See [App::optex::textconv::tika](https://metacpan.org/pod/App::optex::textconv::tika).

# MICROSOFT DOCUMENTS

Microsoft office document in XML format (.docx, .pptx, .xlsx) is
converted to plain text by original code implemented in
[App::optex::textconv::msdoc](https://metacpan.org/pod/App::optex::textconv::msdoc) module.  Algorithm used in this module
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

Copyright 2019-2021 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
