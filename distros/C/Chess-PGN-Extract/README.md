# NAME

Chess::PGN::Extract - Parse PGN files by using \`pgn-extract\`

# SYNOPSIS

    use Chess::PGN::Extract;

    # Slurp all games in a PGN file
    my @games = read_games ("filename.pgn");

# DESCRIPTION

**Chess::PGN::Extract** provides a function to extract chess records from
Portable Game Notation (PGN) files.

**Chess::PGN::Extract** internally depends on
[JSON-enhanced pgn-extract](https://bitbucket.org/mnacamura/pgn-extract),
a command line tool to manipulate PGN files. So, please put the `pgn-extract`
in your `PATH` for using this module.

If you want to deal with a huge PGN file with which slurping is expensive,
consider to use [Chess::PGN::Extract::Stream](https://metacpan.org/pod/Chess::PGN::Extract::Stream), which provides a file stream
class to read games iteratively.

# FUNCTIONS

- **read\_games ($pgn\_file)**

    Read all games contained in the `$pgn_file` at once and return an `ARRAY` of
    them.

    Perl expression of one game will be something like this:

        { Event     => "LAPUTA: Castle in the Sky",
          Site      => "Tiger Moth",
          Date      => "1986.08.02",
          Round     => 1,
          White     => "Captain Dola",
          Black     => "Jicchan",
          Result    => "1-0",
          Moves     => ["e2-e4", "g7-g6"],
        }

    **NOTE**

    In a typical PGN file, moves are recorded in standard algebraic notation
    (SAN):

        1. e4 g6
        ...

    `pgn-extract` converts it to long algebraic notation (LAN), and so does this
    module:

        my ($game) = read_games ($pgn_file);
        $game->{Moves} #=> ["e2-e4", "g7-g6", ...]

    For details about PGN, SAN, and LAN, see, _e.g._,
    [http://en.wikipedia.org/wiki/Portable\_Game\_Notation](http://en.wikipedia.org/wiki/Portable_Game_Notation) and
    [http://en.wikipedia.org/wiki/Chess\_notation](http://en.wikipedia.org/wiki/Chess_notation).

# SEE ALSO

[Chess::PGN::Extract::Stream](https://metacpan.org/pod/Chess::PGN::Extract::Stream), [Chess::PGN::Parse](https://metacpan.org/pod/Chess::PGN::Parse)

# BUGS

Please report any bugs to
[https://bitbucket.org/mnacamura/chess-pgn-extract/issues](https://bitbucket.org/mnacamura/chess-pgn-extract/issues).

# AUTHOR

Mitsuhiro Nakamura <m.nacamura@gmail.com>

Many thanks to David J. Barnes for his original development of
[pgn-extract](http://www.cs.kent.ac.uk/people/staff/djb/pgn-extract/) and
basicer at Bitbucket for
[his work on JSON enhancement](https://bitbucket.org/basicer/pgn-extract/).

# LICENSE

Copyright (C) 2014 Mitsuhiro Nakamura.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
