# NAME

CLI::Popt - Parse CLI parameters via [popt(3)](http://man.he.net/man3/popt)

# SYNOPSIS

    my $popt = CLI::Popt->new(
        [

            # A simple boolean:
            {
                long_name => 'verbose',
            },

            # Customize the boolean’s truthy value:
            {
                long_name => 'gotta-be-me',
                type => 'val',
                val => 42,
            },
        ],
        name => $0,     # default; shown just for demonstration
    );

    my ($opts_hr, @leftovers) = $popt->parse(@ARGV);

# DESCRIPTION

[Getopt::Long](https://metacpan.org/pod/Getopt%3A%3ALong) is nice, but its inability to auto-generate help & usage
text requires you to duplicate data between your code and your script’s
documentation.

[popt(3)](http://man.he.net/man3/popt) remedies that problem. This module makes that solution available
to Perl.

# CHARACTER ENCODING

All strings into & out of this library are byte strings. Please
decode/encode according to your application’s needs.

# METHODS

## $obj = _CLASS_->new( \\@OPTIONS, %EXTRA )

Instantiates _CLASS_.

Each @OPTIONS member is a reference to a hash that describes an option
that the returned $obj will `parse()` out:

- `long_name` (required)
- `type` - optional; one of: `none` (default), `string`,
`argv` (i.e., an array of strings), `short`, `int`, `long`, `longlong`,
`float`, or `double`
- `short_name` - optional
- `flags` - optional arrayref of `onedash`, `doc_hidden`,
`optional`, `show_default`, `random`, and/or `toggle`.

    Numeric options may also include `or`, `and`, or `xor`, and optionally
    `not`.

    NB: not all flags make sense together; e.g., `or` conflicts with `xor`.

    See [popt(3)](http://man.he.net/man3/popt) for more information.

- `descrip`, and `arg_descrip` - optional, as described in
[popt(3)](http://man.he.net/man3/popt).

%EXTRA is:

- `name` - defaults to Perl’s `$0`. Give empty string
to leave this unset.

## ($opts\_hr, @leftovers) = _OBJ_->parse(@ARGV)

Parses a list of strings understood to be parameters to script
invocation. Returns a hash reference of the parsed options (keyed
on each option’s `long_name`) as well as a list of “leftover” @ARGV members
that didn’t go into one of the parsed options.

If @ARGV doesn’t match _OBJ_’s stored options specification (e.g.,
[popt(3)](http://man.he.net/man3/popt) fails the parse), an appropriate exception of type
[CLI::Popt::X::Base](https://metacpan.org/pod/CLI%3A%3APopt%3A%3AX%3A%3ABase) is thrown.

## $str = _OBJ_->get\_help()

Returns the help text.

## $str = _OBJ_->get\_usage()

Returns the usage text.

# LICENSE & COPYRIGHT

Copyright 2022 by Gasper Software Consulting. All rights reserved.

This library is licensed under the same terms as Perl itself.
See [perlartistic](https://metacpan.org/pod/perlartistic).
