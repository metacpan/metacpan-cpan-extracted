[![Actions Status](https://github.com/kaz-utashiro/greple-pw/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-pw/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-pw.svg)](https://metacpan.org/release/App-Greple-pw)
# NAME

pw - Module to get password from file

# SYNOPSIS

greple -Mpw pattern file

# VERSION

0.01

# DESCRIPTION

This module searches id and password information those written in text
file, and displays them interactively.  Passwords are not shown on
display by default, but you can copy them into clipboard by specifying
item mark.

PGP encrypted file can be handled by **greple** standard feature.
Command "**gpg**" is invoked for files with "_.gpg_" suffix by
default.  Option **--pgp** is also available, then you can type
passphrase only once for searching from multiple files.  Consult
**--if** option if you are using other encryption style.

Terminal scroll buffer and screen is cleared when command exits, and
content of clipboard is replaced by prepared string, so that important
information does not remain on the terminal.

Id and password is collected from text using some keywords like
"user", "account", "password", "pin" and so on.  To see actual data,
use **pw\_status** function described below.

Some bank use random number matrix as a countermeasure for tapping.
If the module successfully guessed the matrix area, it blackout the
table and remember them.

      | A B C D E F G H I J
    --+--------------------
    0 | Y W 0 B 8 P 4 C Z H
    1 | M 0 6 I K U C 8 6 Z
    2 | 7 N R E Y 1 9 3 G 5
    3 | 7 F A X 9 B D Y O A
    4 | S D 2 2 Q V J 5 4 T

Enter the field position to get the cell items like:

    > E3 I0 C4

and you will get the answer:

    9 Z 2

Case is ignored and white space is not necessary, so you can type like
this as well:

    > e3i0c4

# INTERFACE

- **pw\_print**

    Data print function.  This function is set for **--print** option of
    **greple** by default, and user doesn't have to care about it.

- **pw\_epilogue**

    Epilogue function.  This function is set for **--end** option of
    **greple** by default, and user doesn't have to care about it.

- **pw\_option**

    Several parameters can be set by **pw\_option** function.  If you do not
    want to clear screen after command execution, call **pw\_option** like:

        greple -Mpw::pw_option(clear_screen=0)

    or:

        greple -Mpw --begin pw_option(clear_screen=0)

    with appropriate quotation.

    Currently following options are available:

        clear_clipboard
        clear_string
        clear_screen
        clear_buffer
        goto_home
        browser
        timeout
        parse_matrix
        parse_id
        parse_pw
        id_keys
        id_chars
        id_color
        id_label_color
        pw_keys
        pw_chars
        pw_color
        pw_label_color
        pw_blackout
        debug

    Password is not blacked out when **pw\_blackout** is 0.  If it is 1, all
    password characters are replaced by 'x'.  If it is greater than 1,
    password is replaced by sequence of 'x' indicated by that number.

    **id\_keys** and **pw\_keys** are list, and list members are separated by
    whitespaces.  When the value start with '**+**' mark, it is appended to
    current list.

- **pw\_status**

    Print option status.  Next command displays defaults.

        greple -Mpw::pw_status= dummy /dev/null

# SEE ALSO

[App::Greple](https://metacpan.org/pod/App%3A%3AGreple), [App::Greple::pw](https://metacpan.org/pod/App%3A%3AGreple%3A%3Apw)

[https://github.com/kaz-utashiro/greple-pw](https://github.com/kaz-utashiro/greple-pw)

# AUTHOR

Kazumasa Utashiro

# LICENSE

Copyright (C) 2017-2025 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
