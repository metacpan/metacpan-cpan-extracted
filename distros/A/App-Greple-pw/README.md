[![Actions Status](https://github.com/kaz-utashiro/greple-pw/workflows/test/badge.svg)](https://github.com/kaz-utashiro/greple-pw/actions) [![MetaCPAN Release](https://badge.fury.io/pl/App-Greple-pw.svg)](https://metacpan.org/release/App-Greple-pw)
# NAME

pw - Interactive password and ID information extractor for greple

# SYNOPSIS

    # Basic usage
    greple -Mpw pattern file

    # Search in encrypted files
    greple -Mpw password ~/secure/*.gpg

    # Configure options
    greple -Mpw --no-clear-screen --chrome password data.txt
    greple -Mpw --config timeout=600 --config debug=1 password file.txt

# VERSION

Version 1.02

# DESCRIPTION

The **pw** module is a **greple** extension that provides secure, interactive
handling of sensitive information such as passwords, user IDs, and account
details found in text files. It is designed with security in mind, ensuring
that sensitive data doesn't remain visible on screen or in terminal history.

## Key Features

- **Interactive password handling**

    Passwords are masked by default and can be safely copied to clipboard
    without displaying the actual content on screen.

- **Secure cleanup**

    Terminal scroll buffer and screen are automatically cleared when the
    command exits, and clipboard content is replaced with a harmless string
    to prevent sensitive information from persisting.

- **Encrypted file support**

    Seamlessly works with PGP encrypted files using **greple**'s standard
    features. Files with "_.gpg_" extension are automatically decrypted,
    and the **--pgp** option allows entering the passphrase once for
    multiple files.

- **Intelligent pattern recognition**

    Automatically detects ID and password information using configurable
    keywords like "user", "account", "password", "pin", etc. Custom
    keywords can be configured to match your specific data format.

- **Browser integration**

    Includes browser automation features for automatically filling web
    forms with extracted credentials.

Some banks use random number matrices as a countermeasure for tapping.
If the module successfully guesses the matrix area, it blacks out the
table and remembers them.

      | A B C D E F G H I J
    --+--------------------
    0 | Y W 0 B 8 P 4 C Z H
    1 | M 0 6 I K U C 8 6 Z
    2 | 7 N R E Y 1 9 3 G 5
    3 | 7 F A X 9 B D Y O A
    4 | S D 2 2 Q V J 5 4 T

Enter the field positions to get the cell items like:

    > E3 I0 C4

and you will get the answer:

    9 Z 2

Case is ignored and white space is not necessary, so you can type like
this as well:

    > e3i0c4

# INTERFACE

- **config**

    Module parameters can be configured using the **config** interface from
    [Getopt::EX::Config](https://metacpan.org/pod/Getopt%3A%3AEX%3A%3AConfig).  There are three ways to configure parameters:

    - Module configuration syntax

        Use the **::config=** syntax directly with the module:

            greple -Mpw::config=clear_screen=0

    - Command-line config option

        Use the **--config** option to set parameters:

            greple -Mpw --config clear_screen=0 --

        Multiple parameters can be set:

            greple -Mpw --config clear_screen=0 --config debug=1 --

    - Direct command-line options

        Many parameters have direct command-line equivalents:

            greple -Mpw --no-clear-screen --debug --browser=safari --

    Currently following configuration options are available:

        clear_clipboard
        clear_string
        clear_screen
        clear_buffer
        goto_home
        browser
        timeout
        debug
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

### Parameter Details

- **Option naming**

    Configuration parameters use underscores (`clear_screen`, `id_keys`), while 
    command-line options use hyphens (`--clear-screen`, `--id-keys`).

- **Boolean parameters**

    Parameters like **clear\_screen**, **debug** can be set to 0/1. Command-line 
    options support negation with `--no-` prefix (e.g., `--no-clear-screen`).

- **List parameters**

    **id\_keys** and **pw\_keys** are lists of keywords separated by spaces:

        --config id_keys="USER ACCOUNT LOGIN EMAIL"
        --config pw_keys="PASS PASSWORD PIN SECRET"

- **Password display control**

    **pw\_blackout** controls password display:
    0=show passwords, 1=mask with 'x', >1=fixed length mask.

- **PwBlock integration**

    Parameters **parse\_matrix**, **parse\_id**, **parse\_pw**, **id\_\***, and **pw\_\*** 
    are passed to the PwBlock module for pattern recognition and display control.

- **pw\_status**

    Print current configuration status. Next command displays current settings:

        greple -Mpw::pw_status= dummy /dev/null

    This shows which parameters are set to non-default values and which are using defaults.

# BROWSER INTEGRATION

The pw module includes browser integration features for automated input.
Browser options are available:

- **--browser**=_name_

    Set the browser for automation (chrome, safari, etc.):

        greple -Mpw --browser=chrome

- **--chrome**, **--safari**

    Shortcut options for specific browsers:

        greple -Mpw --chrome     # equivalent to --browser=chrome
        greple -Mpw --safari     # equivalent to --browser=safari

During interactive mode, you can use the `input` command to send
data to browser forms automatically.

# EXAMPLES

- Search for passwords in encrypted files

        greple -Mpw password ~/secure/*.gpg

- Use with specific browser and no screen clearing

        greple -Mpw --chrome --no-clear-screen password data.txt

- Configure custom keywords and timeout

        greple -Mpw --config id_keys="LOGIN EMAIL USER" --config timeout=600 password file.txt

- Check current configuration

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
