use strict;
use File::Basename;
use File::Which;
use Test::More;

unless (which 'pgn-extract') {
  plan skip_all => "`pgn-extract` required for the unit test";
} else {
  use Chess::PGN::Extract;
}

my @games = read_games ( dirname (__FILE__) . '/data/game.pgn' );
is_deeply (
  \@games,
  [ { Event     => "Lucky Man vs. Kasparov",
      Site      => "Microcosm III",
      Date      => "????.??.??",
      Round     => 1,
      White     => "Tsuitenai, Yoichi",
      Black     => "Garry K. Kasparov",
      Result    => "1-0",
      WhiteElo  => "0",
      BlackElo  => "2851",
      ECO       => "B06",
      EventDate => "????.??.??",
      Moves     => [qw| e2-e4 g7-g6 |],
    },
  ],
  "Decode PGN"
);

@games = read_games ( dirname (__FILE__) . '/data/invalid_char.pgn' );
is_deeply (
  \@games,
  [ { Event     => "Lucky Man vs. Kasparov",
      Site      => "Microcosm III",
      Date      => "????.??.??",
      Round     => 1,
      White     => "Tsuitenai, Yoichi",
      Black     => "Garry K. Kasparov",
      Result    => "1-0",
      WhiteElo  => "0",
      BlackElo  => "2851",
      ECO       => "B06",
      EventDate => "????.??.??",
      Moves     => [qw| e2-e4 g7-g6 |],
    },
  ],
  "Invalid characters are removed"
);

@games = read_games ( dirname (__FILE__) . '/data/not.pgn' );
is (@games, 0, "Invalid PGNs are skipped");

done_testing;
