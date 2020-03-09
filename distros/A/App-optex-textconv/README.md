[![Build Status](https://travis-ci.com/kaz-utashiro/optex-textconv.svg?branch=master)](https://travis-ci.com/kaz-utashiro/optex-textconv)
# NAME

textconv - optex module to replace document file by its text contents

# VERSION

Version 0.08

# SYNOPSIS

optex command -Mtextconv

optex command -Mtc (alias module)

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

# INSTALL

## CPANM

    $ cpanm App::optex::textconv
    or
    $ curl -sL http://cpanmin.us | perl - App::optex::textconv

## GIT

Those are sample configurations using [App::optex::textconv](https://metacpan.org/pod/App::optex::textconv) in git
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

# SEE ALSO

[https://github.com/kaz-utashiro/optex](https://github.com/kaz-utashiro/optex)

[https://github.com/kaz-utashiro/optex-textconv](https://github.com/kaz-utashiro/optex-textconv)

[https://qiita.com/kaz-utashiro/items/23fd825bd325240592c2](https://qiita.com/kaz-utashiro/items/23fd825bd325240592c2)

# LICENSE

Copyright (C) Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
