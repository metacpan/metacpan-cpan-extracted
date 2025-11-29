[![Actions Status](https://github.com/kaz-utashiro/optex-xform/actions/workflows/test.yml/badge.svg?branch=master)](https://github.com/kaz-utashiro/optex-xform/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-optex-xform.svg)](https://metacpan.org/release/App-optex-xform)
# NAME

xform - data transform filter module for optex

# SYNOPSIS

    optex -Mxform

# DESCRIPTION

**xform** is a filter module for **optex** command which transform STDIN
into different form to make it convenient to manipulate, and recover
to the original form after the process.

Transformed data have to be appear in exactly same order as original
data.

# OPTION

- **--xform-ansi**

    Transform ANSI terminal sequence into printable string, and recover.

- **--xform-utf8**

    Transform multibyte Non-ASCII chracters into single-byte sequene, and
    recover.

- **--xform-bin**

    Transform non-printable binary characters into printable string, and
    recover.

- **--xform-visible**=_0|1|2_

    Specify the character set used for transformation. This option overrides
    the default `visible` parameter of `Text::Conceal`.

    - **0**

        Use both printable and non-printable characters.

    - **1**

        Use printable characters first, then non-printable characters if needed.

    - **2**

        Use only printable characters (default).

    This option can be combined with any xform mode (ansi, utf8, bin, generic).

# EXAMPLE

    $ jot 100 | egrep --color=always .+ | optex column -Mxform --xform-ansi -x

Use `--xform-visible` to control character set used for transformation:

    $ optex -Mxform --xform-visible=2 --xform-ansi cat colored.txt

    $ optex -Mxform --xform-visible=1 --xform-utf8 command

# SEE ALSO

[App::optex::xform](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Axform), [https://github.com/kaz-utashiro/optex-xform](https://github.com/kaz-utashiro/optex-xform),

[App::optex](https://metacpan.org/pod/App%3A%3Aoptex), [https://github.com/kaz-utashiro/optex](https://github.com/kaz-utashiro/optex),
[https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6](https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6)

[Text::Conceal](https://metacpan.org/pod/Text%3A%3AConceal)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
