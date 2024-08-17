[![Actions Status](https://github.com/kaz-utashiro/optex-mask/actions/workflows/test.yml/badge.svg)](https://github.com/kaz-utashiro/optex-mask/actions)
# NAME

App::optex::mask - optex data masking module

# VERSION

Version 0.01

# SYNOPSIS

    optex -Mmask patterns -- command

# DESCRIPTION

App::optex::mask is an **optex** module for masking data given as
standard input to a command to be executed. It transforms strings
matching a specified pattern according to a set of rules before giving
them as input to a command, and restores the resulting content to the
original string.

Multiple conversion rules can be specified, but currently only `xml`
is supported.  This is for **deepl** translation interface, and
converts a string to an XML tag such as `<m id=999 />`.

The following example translates an English sentence into French.

    $ echo All men are created equal | deepl text --to FR "$(cat)"
    Tous les hommes sont créés égaux

If you want to leave part of a sentence untranslated, specify a
pattern that matches the string.

    $ echo All men are created equal | \
        optex -Mmask::set=debug men -- sh -c 'deepl text --to FR "$(cat)"'
    [1] All men are created equal
    [2] All <m id=1 /> are created equal
    [3] Tous les <m id=1 /> sont créés égaux
    [4] Tous les men sont créés égaux
    Tous les men sont créés égaux

# PARAMETERS

Parameters are given as options for `set` function at module startup.

For example, to enable the debugging option, specify the following. If
no value is specified, it defaults to 1 and can be omitted.

    optex -Mmask::set(debug=1)
    optex -Mmask::set(debug)

This could be written as follows.  This is somewhat easier to type
from the shell, since it does not use parentheses.

    optex -Mmask::set=debug=1
    optex -Mmask::set=debug

- **encode**
- **decode**

    Enable encoding and decoding.  You can check how it is encoded by
    disabling the `decode` option.

- **mode**

    The default is `xml`, which is the only supported at this time.

- **start**

    Specifies the initial value of the number used as id in xml tag.
    Default is 1.

- **debug**

    Enable debugging.

# INSTALL

## CPANM

    cpanm App::optex::mask

# SEE ALSO

- [App::optex](https://metacpan.org/pod/App%3A%3Aoptex)
- [App::Greple::xlate](https://metacpan.org/pod/App%3A%3AGreple%3A%3Axlate)
- [https://www.deepl.com](https://www.deepl.com)
- [https://github.com/DeepLcom/deepl-python](https://github.com/DeepLcom/deepl-python)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright ©︎ 2024 Kazumasa Utashiro

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
