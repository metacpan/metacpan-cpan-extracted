[![Actions Status](https://github.com/kaz-utashiro/greple-wordle/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-wordle/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-wordle.svg)](https://metacpan.org/release/App-Greple-wordle)
# NAME

App::Greple::wordle - wordle module for greple

# SYNOPSIS

greple -Mwordle

# DESCRIPTION

App::Greple::wordle is a greple module which implements wordle game.
Correctness is checked by regular expression.

Rule is almost same as original wordle but answer is different.  Set
environment `WORDLE_COMPAT=1` to get compatible answer.

<div>
    <p><img width="50%" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/screen.png">
</div>

# BUGS

Wrong position character is colored yellow always, even if it is
colored green in other position.

# ENVIRONMENT

- WORDLE\_ANSWER

    Set answer word.

- WORDLE\_RANDOM

    Generate random answer every time.

- WORDLE\_COMPAT

    Generate compatible answer with the original game.

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
