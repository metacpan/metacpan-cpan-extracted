# NAME

App::OATH - Simple OATH authenticator

# DESCRIPTION

Simple command line OATH authenticator written in Perl.

# SYNOPSIS

Implements the Open Authentication (OATH) time-based one time password (TOTP)
two factor authentication standard as a simple command line programme.

Allows storage of multiple tokens, which are kept encrypted on disk.

Google Authenticator is a popular example of this standard, and this project
can be used with the same tokens.

# USAGE

usage: oath --add string --file filename --help --init --list --newpass --search string 

options:

\--add string

    add a new password to the database, the format can be one of the following

        text: identifier:secret
        url:  otpauth://totp/alice@google.com?secret=JBSWY3DPEHPK3PXP

\--file filename

    filename for database, default ~/.oath.json

\--help

    show this help

\--init

    initialise the database, file must not exist

\--list

    list keys in database

\--newpass

    resave database with a new password

\--search string

    search database for keys matching string

# SECURITY

Tokens are encrypted on disk, the identifiers are not encrypted and can be read in plaintext
from the file.

This is intended to secure against casual reading of the file, but as always, if you have specific security requirements
you should do your own research with regard to relevant attack vectors and use an appropriate solution.

# METHODS

You most likely won't ever want to call these directly, you should use the included command line programme instead.

- _new()_

    Instantiate a new object

- _usage()_

    Display usage and exit

- _set\_raw()_

    Show the raw OATH code rather than decoding

- _set\_rawqr()_

    Show the raw OATH code as a QR code rather than decoding

- _set\_search()_

    Set the search parameter

- _get\_search()_

    Get the search parameter

- _init()_

    Initialise a new file

- _add\_entry()_

    Add an entry to the file

- _list\_keys()_

    Display a list of keys in the current file

- _get\_counter()_

    Get the current time based counter

- _display\_codes()_

    Display a list of codes

- _make\_qr( $srting )_

    Format the given string as a QR code

- _oath\_auth()_

    Perform the authentication calculations

- _set\_filename()_

    Set the filename

- _get\_filename()_

    Get the filename

- _load\_data()_

    Load in data from file

- _save\_data()_

    Save data to file

- _encrypt\_data()_

    Encrypt the data

- _decrypt\_data()_

    Decrypt the data

- _get\_plaintext()_

    Get the plaintext version of the data

- _get\_encrypted()_

    Get the encrypted version of the data

- _set\_newpass()_

    Signal that we would like to set a new password

- _drop\_password()_

    Drop the password

- _get\_password()_

    Get the current password (from user or cache)

- _get\_lockfilename()_

    Return a filename for the lock file, typically this is filename appended with .lock

- _drop\_lock()_

    Drop the lock (unlock)

- _get\_lock()_

    Get a lock, return 1 on success or 0 on failure

# DEPENDENCIES

    Convert::Base32
    Digest::HMAC_SHA1
    English
    Fcntl
    File::HomeDir
    JSON
    POSIX
    Term::ReadPassword
    Term::ReadPassword::Win32

# AUTHORS

Marc Bradshaw <marc@marcbradshaw.net>

# COPYRIGHT

Copyright 2015

This library is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.
