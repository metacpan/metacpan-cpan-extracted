use strict;
use Test::More 0.98;

use_ok $_ for qw(
    App::Greple::wordle
    App::Greple::wordle::word_all
    App::Greple::wordle::word_hidden
    App::Greple::wordle::game
);

done_testing;
