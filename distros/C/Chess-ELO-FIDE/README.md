[![Actions Status](https://github.com/niceperl/chess-elo-fide/actions/workflows/test.yml/badge.svg)](https://github.com/niceperl/chess-elo-fide/actions)
# NAME

Chess::ELO::FIDE - Download and store FIDE ratings

# SYNOPSIS

    use Chess::ELO::FIDE;
    my $ratings = Chess::ELO::FIDE->new(
                    federation=> 'ESP',
                    sqlite    => 'elo.sqlite'
    );
    my $count = $ratings->load;
    print "Loaded $count players\n";

# DESCRIPTION

Chess::ELO::FIDE is a module to download and store FIDE ratings in a SQLite database.
It is intended to be used as a backend for chess applications.
There are 3 main phases:

- 1. Download the FIDE ratings file from the [FIDE website](https://ratings.fide.com/download/players_list.zip)
- 2. Unzip the file and load the ratings into a SQLite database
- 3. Store the last download date to avoid downloading the same file again

# LICENSE

Copyright (C) Miguel PRZ - NICEPERL

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

NICEPERL [https://metacpan.org/author/NICEPERL](https://metacpan.org/author/NICEPERL)
