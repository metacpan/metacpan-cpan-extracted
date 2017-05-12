# NAME

Caroline - Yet another line editing library 

# SYNOPSIS

    use Caroline;
    use Term::Encoding qw(term_encoding);

    my $encoding = term_encoding();
    binmode *STDIN, ":encoding(${encoding})";
    binmode *STDOUT, ":encoding(${encoding})";

    my $c = Caroline->new;
    while (defined(my $line = $c->readline('> '))) {
        if ($line =~ /\S/) {
            print eval $line;
        }
    }

# DESCRIPTION

Caroline is yet another line editing library like [Term::ReadLine::Gnu](https://metacpan.org/pod/Term::ReadLine::Gnu).

This module supports

- History handling
- Complition
- Portable
- No C library dependency

# PROJECT GOALS

Provides portable line editing library for Perl5 community.

# METHODS

- my $caroline = Caroline->new();

    Create new Caroline instance.

    Options are:

    - history\_max\_len : Str

        Set the limitation for max history size.

    - completion\_callback : CodeRef

        You can write completion callback function like this:

            use Caroline;
            my $c = Caroline->new(
                completion_callback => sub {
                    my ($line) = @_;
                    if ($line eq 'h') {
                        return (
                            'hello',
                            'hello there'
                        );
                    } elsif ($line eq 'm') {
                        return (
                            '突然のmattn'
                        );
                    }
                    return;
                },
            );

- `my $line = $caroline->read($prompt);`

    Read line with `$prompt`.

    Trailing newline is removed. Returns undef on EOF.

- `$caroline->history_add($line)` 

    Add $line to the history.

- `$caroline->history()`

    Get the current history data in ` ArrayRef[Str] `.

- `$caroline->write_history_file($filename)`

    Write history data to the file.

- `$caroline->read_history_file($filename)`

    Read history data from history file.

# Multi byte character support

If you want to support multi byte characters, you need to set binmode to STDIN.
You can add the following code before call Caroline.

    use Term::Encoding qw(term_encoding);
    my $encoding = term_encoding();
    binmode *STDIN, ":encoding(${encoding})";

# About east Asian ambiguous width characters

Caroline detects east Asian ambiguous character width from environment variable using [Unicode::EastAsianWidth::Detect](https://metacpan.org/pod/Unicode::EastAsianWidth::Detect).

User need to set locale correctly. For more details, please read [Unicode::EastAsianWidth::Detect](https://metacpan.org/pod/Unicode::EastAsianWidth::Detect).

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# SEE ALSO

[https://github.com/antirez/linenoise/blob/master/linenoise.c](https://github.com/antirez/linenoise/blob/master/linenoise.c)

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

mattn
