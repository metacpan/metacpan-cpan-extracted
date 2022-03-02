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
    <p><img width="50%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/screen-2.png">
</div>

# OPTIONS

- **--answer**=_word_

    Set answer word.

- **--count**=_number_

    Set try count.

- **--random**

    Generate random answer every time.

- **--compat**

    Generate compatible answer with the original game.

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
