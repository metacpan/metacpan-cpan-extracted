# NAME

Acme::Cow::Interpreter - Cow programming language interpreter

# SYNOPSIS

    use Acme::Cow::Interpreter;

    my $cow = Acme::Cow::Interpreter -> new();
    $cow -> parse_file($file);
    $cow -> execute();

# ABSTRACT

This module implements an interpreter for the Cow programming language.

# DESCRIPTION

This module implements an interpreter for the Cow programming language. The
Cow programming language is a so-called esoteric programming language, with
only 12 commands.

# METHODS

- new()

    Return a new Cow interpreter.

- init()

    Initialize an object instance. Clears the memory and register and sets the
    memory pointer to zero. Also, the internally stored program source is
    cleared.

- copy()

    Copy (clone) an Acme::Cow::Interpreter object.

- parse\_string( STRING )

    Parses the given string and stores the resulting list of codes in the
    object.  The return value is the object itself.

- parse\_file( FILENAME )

    Parses the contents of the given file and stores the resulting list of codes
    in the object. The return value is the object itself.

- dump\_mem()

    Returns a nicely formatted string showing the current memory state.

- dump\_obj()

    Returns a text version of object structure.

- execute()

    Executes the source code. The return value is the object itself.

# NOTES

## The Cow Language

The Cow language has 12 instruction. The commands and their corresponding
code numbers are:

- moo (0)

    This command is connected to the **MOO** command. When encountered during
    normal execution, it searches the program code in reverse looking for a
    matching **MOO** command and begins executing again starting from the found
    **MOO** command. When searching, it skips the command that is immediately
    before it (see **MOO**).

- mOo (1)

    Moves current memory position back one block.

- moO (2)

    Moves current memory position forward one block.

- mOO (3)

    Execute value in current memory block as if it were an instruction. The
    command executed is based on the instruction code value (for example, if the
    current memory block contains a 2, then the **moO** command is executed). An
    invalid command exits the running program. Value 3 is invalid as it would
    cause an infinite loop.

- Moo (4)

    If current memory block has a 0 in it, read a single ASCII character from
    the standard input and store it in the current memory block. If the current
    memory block is not 0, then print the ASCII character that corresponds to
    the value in the current memory block to the standard output.

- MOo (5)

    Decrement current memory block value by 1.

- MoO (6)

    Increment current memory block value by 1.

- MOO (7)

    If current memory block value is 0, skip next command and resume execution
    after the next matching **moo** command. If current memory block value is not
    0, then continue with next command. Note that the fact that it skips the
    command immediately following it has interesting ramifications for where the
    matching **moo** command really is. For example, the following will match the
    second and not the first **moo**: **OOO** **MOO** **moo** **moo**

- OOO (8)

    Set current memory block value to 0.

- MMM (9)

    If no current value in register, copy current memory block value. If there
    is a value in the register, then paste that value into the current memory
    block and clear the register.

- OOM (10)

    Print value of current memory block to the standard output as an integer.

- oom (11)

    Read an integer from the standard input and put it into the current memory
    block.

# TODO

Add more tests. The module is far from being tested thoroughly.

# BUGS

There are currently no known bugs.

Please report any bugs or feature requests via
[https://github.com/pjacklam/p5-Acme-Cow-Interpreter/issues](https://github.com/pjacklam/p5-Acme-Cow-Interpreter/issues).

Old bug reports and feature requests can be found at
[http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Cow-Interpreter](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Cow-Interpreter).

# SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Acme::Cow::Interpreter

You can also look for information at:

- GitHub

    [http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Cow-Interpreter](http://rt.cpan.org/NoAuth/Bugs.html?Dist=Acme-Cow-Interpreter)

- MetaCPAN

    [https://metacpan.org/release/Acme-Cow-Interpreter](https://metacpan.org/release/Acme-Cow-Interpreter)

- CPAN Ratings

    [http://cpanratings.perl.org/d/Acme-Cow-Interpreter](http://cpanratings.perl.org/d/Acme-Cow-Interpreter)

- CPAN Testers PASS Matrix

    [http://pass.cpantesters.org/distro/A/Acme-Cow-Interpreter.html](http://pass.cpantesters.org/distro/A/Acme-Cow-Interpreter.html)

- CPAN Testers Reports

    [http://www.cpantesters.org/distro/A/Acme-Cow-Interpreter.html](http://www.cpantesters.org/distro/A/Acme-Cow-Interpreter.html)

- CPAN Testers Matrix

    [http://matrix.cpantesters.org/?dist=Acme-Cow-Interpreter](http://matrix.cpantesters.org/?dist=Acme-Cow-Interpreter)

# REFERENCES

- [http://bigzaphod.github.io/COW/](http://bigzaphod.github.io/COW/)

# AUTHOR

Peter John Acklam &lt;pjacklam@gmail.com&lt;gt>

# COPYRIGHT & LICENSE

Copyright 2007-2020 Peter John Acklam.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.0 or,
at your option, any later version of Perl 5 you may have available.
