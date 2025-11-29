# NAME

rpn - optex module for Reverse Polish Notation calculation

# SYNOPSIS

    optex -Mrpn command ...

# DESCRIPTION

**rpn** is a module for the **optex** command that detects arguments
that look like Reverse Polish Notation (RPN) expressions and replaces
them with their calculated results.

By default, all arguments are processed automatically when the module
is loaded.

# OPTIONS

Options can be set via `-Mrpn::config(...)` or `--option` before
`--`.

- **--all**, **--no-all**

    Enable or disable automatic processing of all arguments.  Default is
    enabled.  Use `--no-all` to disable and process only arguments
    specified by `--rpn`.

- **--verbose**

    Print diagnostic messages.

- **--rpn** _expression_

    Convert a single RPN expression.  Use colon (`:`) instead of comma
    as the term separator because comma is used as a parameter delimiter
    in the module call syntax.

        optex -Mrpn --no-all -- echo --rpn 3600:5* hello
        # outputs: 18000 hello

# EXPRESSIONS

An RPN expression requires at least two terms separated by commas (or
colons when using `--rpn`).  A single term like `RAND` will not be
converted, but `RAND,0+` will produce a random number.

## OPERATORS

The following operators are supported (case-insensitive):

- Arithmetic

    `+` (ADD), `-` (SUB), `*` (MUL), `/` (DIV), `%` (MOD),
    `++` (INCR), `--` (DECR), `POW`, `SQRT`

- Trigonometric

    `SIN`, `COS`, `TAN`

- Logarithmic

    `LOG`, `EXP`

- Numeric

    `ABS`, `INT`

- Bitwise/Logical

    `&` (AND), `|` (OR), `!` (NOT), `XOR`, `~`

- Comparison

    `<` (LT), `<=` (LE), `=`/`==` (EQ),
    `>` (GT), `>=` (GE), `!=` (NE)

- Conditional

    `IF`

- Stack

    `DUP`, `EXCH`, `POP`

- Other

    `MIN`, `MAX`, `TIME`, `RAND`, `LRAND`

See [Math::RPN](https://metacpan.org/pod/Math%3A%3ARPN) for detailed descriptions of these operators.

# EXAMPLES

Convert 5 hours to seconds (3600 \* 5 = 18000):

    $ optex -Mrpn echo 3600,5*
    18000

Prevent macOS from sleeping for 5 hours:

    $ optex -Mrpn caffeinate -d -t 3600,5*

Process multiple expressions:

    $ optex -Mrpn echo 1,2+ 10,3*
    3 30

Generate a random number:

    $ optex -Mrpn echo RAND,0+
    0.316809834520431

# INSTALLATION

## CPANMINUS

    cpanm App::optex::rpn

# SEE ALSO

[App::optex](https://metacpan.org/pod/App%3A%3Aoptex), [https://github.com/kaz-utashiro/optex](https://github.com/kaz-utashiro/optex)

[App::optex::rpn](https://metacpan.org/pod/App%3A%3Aoptex%3A%3Arpn), [https://github.com/kaz-utashiro/optex-rpn](https://github.com/kaz-utashiro/optex-rpn)

[Math::RPN](https://metacpan.org/pod/Math%3A%3ARPN)

[https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6](https://qiita.com/kaz-utashiro/items/2df8c7fbd2fcb880cee6)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright 2021-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
