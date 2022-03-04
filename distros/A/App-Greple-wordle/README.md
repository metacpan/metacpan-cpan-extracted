[![Actions Status](https://github.com/kaz-utashiro/greple-wordle/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-wordle/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-wordle.svg)](https://metacpan.org/release/App-Greple-wordle)
# NAME

App::Greple::wordle - wordle module for greple

# SYNOPSIS

greple -Mwordle

# DESCRIPTION

App::Greple::wordle is a greple module which implements wordle game.
Correctness is checked by regular expression.

Rule is almost same as original wordle but answer is different.  Use
**--compat** option to get compatible answer.

<div>
    <p><img width="75%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/screen-4.png">
</div>

# OPTIONS

- **--compat**

    Generate compatible answer with the original game.  Otherwise, this
    game uses unique sequence using same answer word set as the original
    Wordle.

- **--**\[**no-**\]**result**

    Show result when succeeded.  Default true.

- **--index**=_number_

    Specify index. Index is calculated from days from 2021/06/19.  If the
    value is negative and you can get yesterday's question by giving -1.

- **--series**=_number_

    Choose different series of answers.  Default zero.

- **--random**

    Generate random index every time.

- **--count**=_number_

    Set try count.  Default 6.

- **--answer**=_word_

    Set answer word.  For debug purpose.

# BUGS

Wrong position character is colored yellow always, even if it is
colored green in other position.

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://github.com/alex1770/wordle](https://github.com/alex1770/wordle)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
