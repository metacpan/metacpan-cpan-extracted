[![Actions Status](https://github.com/kaz-utashiro/greple-wordle/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-wordle/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-wordle.svg)](https://metacpan.org/release/App-Greple-wordle)
# NAME

App::Greple::wordle - wordle module for greple

# SYNOPSIS

greple -Mwordle

# DESCRIPTION

App::Greple::wordle is a greple module which implements wordle game.
Correctness is checked by regular expression.

Rule is almost same as the original game but answer is different.  Use
**--compat** option to get compatible answer.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/screen-5.png">
</div>

# OPTIONS

- **--series**=#,  **-s**#
- **--compat**

    Choose different series of answer.  Default 1.  Series zero is same as
    the original game and option **--compat** is a short cut for
    **--series=0**.  If it is not zero, original answer word set is
    shuffled by pseudo random numbers using series number as an initial
    seed.

- **--index**=#, **-n**#

    Specify index. Default index is calculated from days from 2021/06/19.
    If the value is negative and you can get yesterday's question by
    giving -1.

    Answer for option **-s0n0** is `cigar`.

- **--**\[**no-**\]**result**

    Show result when succeeded.  Default true.

- **--random**

    Generate random index every time.

- **--try**=#, **-x**=#

    Set try count.  Default 6.

# COMMANDS

Five letter word is processed as an answer.  Some other input is taken
as a command.

- **h**, **hint**

    List possible words.

- **u**, **uniq**

    List possible words made of unique characters.

- **=**_chars_

    If start with slash, list words which include all of _chars_.

- **!**_chars_

    If start with exclamation mark, list words which does not include any
    of _chars_.

- _regex_

    Any other string include non-alphabetical character is taken as a
    regular expression to filter words.

- **!!**

    Get word list produced by the last command execution.

These commands can be connected in series.  For example, next command
show possible words start with letter `z`.

    hint ^z

Next shows all words which does not incude any letter of `audio` and
`rents`, and made of unique characters.

    !audio !rents u

# EXAMPLE

    1: solid                    # try word "solid"
    2: panic                    # try word "panic"
    3: hint                     # show hint
    3: !solid !panic =eft uniq  # search word exclude(solidpanic) include(eft)
    3: wheft                    # try word "wheft"
    4: hint                     # show hint
    4: datum                    # try word "datum"
    5: tardy                    # try word "tardy"

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/hint-1.png">
</div>

# BUGS

Wrong position character is colored yellow always, even if it is
colored green in other position.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::wordle
    or
    $ curl -sL http://cpanmin.us | perl - App::Greple::wordle

# SEE ALSO

[App::Greple::wordle](https://metacpan.org/pod/App%3A%3AGreple%3A%3Awordle), [https://github.com/kaz-utashiro/greple-wordle](https://github.com/kaz-utashiro/greple-wordle)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://qiita.com/kaz-utashiro/items/ba6696187f2ce902aa39](https://qiita.com/kaz-utashiro/items/ba6696187f2ce902aa39)

[https://github.com/alex1770/wordle](https://github.com/alex1770/wordle)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
