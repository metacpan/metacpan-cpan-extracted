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

- **--series**=_number_,  **-s**_number_
- **--compat**

    Choose different series of answer.  Default 1.  Series zero is same as
    the original game and option **--compat** is a short cut for
    **--series=0**.  If it is not zero, original answer word set is
    shuffled by pseudo random numbers using series number as an initial
    seed.

- **--**\[**no-**\]**result**

    Show result when succeeded.  Default true.

- **--index**=_number_, **-n**_number_

    Specify index. Default index is calculated from days from 2021/06/19.
    If the value is negative and you can get yesterday's question by
    giving -1.

- **--random**

    Generate random index every time.

- **--try**=_number_

    Set try count.  Default 6.

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
