[![Build Status](https://travis-ci.com/kaz-utashiro/optex-xform.svg?branch=master)](https://travis-ci.com/kaz-utashiro/optex-xform)
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

    Transform multibyte Non-ASCII chracters into singlebyte sequene, and
    recover.

# EXAMPLE

    $ jot 100 | egrep --color=always .+ | optex -Mxform --xform-ansi column -x

# SEE ALSO

[Text::VisualPrintf::Transform](https://metacpan.org/pod/Text::VisualPrintf::Transform)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
