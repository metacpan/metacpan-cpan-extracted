use strict;
use File::Basename;
use File::Which;
use Test::More;

unless (which 'pgn-extract') {
  plan skip_all => "`pgn-extract` required for the unit test";
} else {
  use Chess::PGN::Extract::Stream;
}

my $pgn_file = dirname (__FILE__) . '/data/seven.pgn';
my $strm = new_ok ( 'Chess::PGN::Extract::Stream' => [$pgn_file] );
can_ok ( $strm, qw| pgn_file read_game read_games | );

my @games = $strm->read_game;
is ( @games, 1,
  "'read_game ()' returns only one game" );

@games = $strm->read_games (0.1);
is ( @games, 0,
  "In 'read_games (\$limit)', \$limit is coearced to be integer" );

my $n = 1 + int rand 5;
@games = $strm->read_games ($n);
is ( @games, $n,
  "'read_games (\$pos_num)' returns \$pos_num games" );

@games = $strm->read_games (0);
is ( @games, 0,
  "'read_games (0)' returns no game" );

@games = $strm->read_games (-1);
is ( @games, 6 - $n,
  "'read_games (\$negative_num)' returns all remaining games" );

$strm = Chess::PGN::Extract::Stream->new ($pgn_file);
@games = $strm->read_games;
is ( @games, 7,
  "'read_games (undef)' returns all remaining games" );

$strm = Chess::PGN::Extract::Stream->new ($pgn_file);
$strm->read_games;
is_deeply (
  [ $strm->read_games (1),
    $strm->read_games (0),
    $strm->read_games (-1),
    $strm->read_games (),
  ],
  [],
  "'read_games (\$limit)' returns nothing when eof reached"
);

done_testing;
