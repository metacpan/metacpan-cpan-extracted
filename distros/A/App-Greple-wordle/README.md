[![Actions Status](https://github.com/kaz-utashiro/greple-wordle/actions/workflows/test.yml/badge.svg?branch=main)](https://github.com/kaz-utashiro/greple-wordle/actions?workflow=test) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-wordle.svg)](https://metacpan.org/release/App-Greple-wordle)
# NAME

App::Greple::wordle - wordle module for greple

# SYNOPSIS

greple -Mwordle

# DESCRIPTION

App::Greple::wordle is a greple module that implements the Wordle game.
Answer correctness is checked by regular expression.

This module supports multiple word datasets. Use the **--data** option to
choose different word datasets such as the original Wordle word list
or the New York Times Wordle word list.

Rules are almost the same as the original game, but answers are different.
Use the **--compat** option to get answers compatible with the original game.

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/screen-5.png">
</div>

# OPTIONS

- **--data**=_dataset_

    Choose the word dataset.  Default is `ORIGINAL`.

    Available datasets:

    - `ORIGINAL`

        The original word list from the initial Wordle game. This is the
        default dataset and contains the classic Wordle word list.

    - `NYT`

        The New York Times Wordle word list, which includes words used by NYT
        Wordle. This dataset is updated and may contain different words than
        the original.

    Dataset modules are dynamically loaded from `App::Greple::wordle::`
    namespace with uppercase dataset name.

- **--series**=#,  **-s**#
- **--compat**

    Choose a different answer series.  Default is 1.  Series zero is the same as
    the original game and option **--compat** is a shortcut for
    **--series=0**.  If it is not zero, the answer set is shuffled by
    pseudo-random numbers using the series number as an initial seed.

- **--index**=#, **-n**#

    Specify the answer index. The default index is calculated from days since
    2021/06/19.  If the value is negative, you can get yesterday's
    question by specifying -1.

    If the specified index exceeds the available answer list, a random
    answer will be selected from the dataset with a warning message.

    Answer for option **-s0n0** with `ORIGINAL` dataset is `cigar`.

- **--**\[**no-**\]**result**

    Show result when successful.  Default is true.

- **--random**

    Generate a random index every time.

- **--trial**=#, **-x**=#

    Set the trial count.  Default is 6.

# COMMANDS

A five-letter word is processed as an answer.  Other input is taken
as a command.

- **h**, **hint**

    List possible words.

- **u**, **uniq**

    List possible words made of unique characters.

- **=**_chars_

    If starting with equal (`=`), list words that include all _chars_.

- **!**_chars_

    If starting with exclamation mark (`!`), list words that do not
    include any of _chars_.

- _regex_

    Any other string including a non-alphabetical character will be taken as a
    regular expression to filter words.

- **!!**

    Recall the word list produced by the last command execution.

These commands can be connected in series.  For example, the following command
shows possible words starting with letter `z`.

    hint ^z

The next example shows all words that do not include any letter of `audio` and
`rents`, and are made of unique characters.

    !audio !rents u

# EXAMPLE

## Basic gameplay

    1: solid                    # try word "solid"
    2: panic                    # try word "panic"
    3: hint                     # show hint
    3: !solid !panic =eft uniq  # search word exclude(solidpanic) include(eft)
    3: wheft                    # try word "wheft"
    4: hint                     # show hint
    4: datum                    # try word "datum"
    5: tardy                    # try word "tardy"

## Using different datasets

    greple -Mwordle --data=NYT            # Use NYT Wordle word list
    greple -Mwordle --data=ORIGINAL       # Use original word list (default)
    greple -Mwordle --data=NYT -n0        # First word in NYT dataset (cigar)

<div>
    <p><img width="750" src="https://raw.githubusercontent.com/kaz-utashiro/greple-wordle/main/images/hint-1.png">
</div>

# BUGS

A character in the wrong position is always colored yellow, even if it
appears in green elsewhere.

# INSTALL

## CPANMINUS

    $ cpanm App::Greple::wordle

# SEE ALSO

[App::Greple::wordle](https://metacpan.org/pod/App%3A%3AGreple%3A%3Awordle), [https://github.com/kaz-utashiro/greple-wordle](https://github.com/kaz-utashiro/greple-wordle)

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [https://github.com/kaz-utashiro/greple](https://github.com/kaz-utashiro/greple)

[https://qiita.com/kaz-utashiro/items/ba6696187f2ce902aa39](https://qiita.com/kaz-utashiro/items/ba6696187f2ce902aa39)

[https://github.com/alex1770/wordle](https://github.com/alex1770/wordle)

[https://wordfinder.yourdictionary.com/wordle/answers/](https://wordfinder.yourdictionary.com/wordle/answers/)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2022-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
