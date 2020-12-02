[![Build Status](https://travis-ci.org/kaz-utashiro/optex-msdoc.svg?branch=master)](https://travis-ci.org/kaz-utashiro/optex-msdoc)
# NAME

msdoc - module to replace MS document by its text contents

# VERSION

Version 0.05

# SYNOPSIS

optex command -Mmsdoc

# NOTICE

There is more general successor version of this module.
Use [https://github.com/kaz-utashiro/optex-textconv](https://github.com/kaz-utashiro/optex-textconv).

# DESCRIPTION

This module replaces argument which terminate with _.docx_, _pptx_
or _xlsx_ files by node representing its text information.  File
itself is not altered.

For example, you can check the text difference between MS word files
like this:

    $ optex diff -Mmsdoc OLD.docx NEW.docx

If you have symbolic link named **diff** to **optex**, and following
setting in your `~/.optex.d/diff.rc`:

    option default --msdoc
    option --msdoc -Mmsdoc $<move>

Next command simply produces the same result.

    $ diff OLD.docx NEW.docx

Text data is extracted by **greple** command with **-Mmsdoc** module,
and above command is almost equivalent to below bash command using
process substitution.

    $ diff <(greple -Mmsdoc --dump OLD.docx) \
           <(greple -Mmsdoc --dump NEW.docx)

# ENVIRONMENT

This version experimentally support other converter program.  If the
environment variable **OPTEX\_MSDOC\_CONVERTER** is set, it is used
instead of **greple**.  Choose one from **greple**, **pandoc** or
**tika**.

# SEE ALSO

[https://github.com/kaz-utashiro/optex-msdoc](https://github.com/kaz-utashiro/optex-msdoc)

It is possible to use other data conversion program, like [pandoc](https://metacpan.org/pod/pandoc) or
["Apache Tika"](#apache-tika).  Feel to free to modify this module.  I'm reluctant to
use them, because they work quite leisurely.

[https://github.com/kaz-utashiro/optex-textconv](https://github.com/kaz-utashiro/optex-textconv)

# LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

Kazumasa Utashiro
