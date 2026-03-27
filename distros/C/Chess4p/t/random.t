# -*- mode: cperl -*-

use v5.36;

use Test::More;

use utf8;

use Config;

plan skip_all => 'Only 64 bit systems are supported.'  unless $Config{ptrsize} && $Config{ptrsize} == 8;

unless ( $ENV{RELEASE_TESTING} ) {
    plan( skip_all => "Randomised tests not required for installation" );
}


require Chess4p;


# *** Conventional start position
my $fen = 'rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1';

my $random_seed = srand();

for (0..100) {
    my $board = Chess4p::Board->fromFen($fen);
    my $more = 1;
    my @debug_state = ();
    my $max_depth = 200;
    push (@debug_state, $board->_debug_state());
    # push a series of random moves (while possible)
    # store states on the way
    while ($more) {
        $more = $board->_push_random_move();
        push (@debug_state, $board->_debug_state()) if $more;
        $more &&= (@debug_state < $max_depth);
    }
    # check states while popping down again
    while (@debug_state) {
        my $state = pop @debug_state;
        is($state, $board->_debug_state(), "popped state == pushed state, using random seed: $random_seed");
        $board->pop_move();
     }

}



done_testing;
