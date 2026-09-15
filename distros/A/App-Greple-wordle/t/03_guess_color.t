use v5.14;
use warnings;
use Test::More 0.98;

use lib 'lib';
use Getopt::EX::Colormap qw(colorize);
use App::Greple::wordle::game;

my %color = (
    G => '555/#6aaa64',
    Y => '555/#c9b458',
    K => '555/#787c7e',
);

# build expected string from a word and its G/Y/K result
sub expect {
    my($word, $result) = @_;
    my @c = $result =~ /./g;
    my $i = 0;
    join '', map { colorize($color{$c[$i++]}, uc $_) } $word =~ /./g;
}

my $game = App::Greple::wordle::game->new(answer => 'cigar');

is_deeply [ $game->guess_color('rebus') ], [ expect('rebus', 'YKKKK') ],
    'letter in the answer is yellow, others are gray';

is_deeply [ $game->guess_color('crack') ], [ expect('crack', 'GYYYK') ],
    'right position is green, repeated letter is yellow';

is_deeply [ $game->guess_color('cigar') ], [ expect('cigar', 'GGGGG') ],
    'correct answer is all green';

is_deeply [ $game->guess_color('rebus', 'cigar') ],
    [ expect('rebus', 'YKKKK'), expect('cigar', 'GGGGG') ],
    'multiple words';

is_deeply [ $game->guess_color('REBUS') ], [ expect('REBUS', 'YKKKK') ],
    'upper case word';

# keymap and word list are shown in upper case
sub plain { (my $s = shift) =~ s/\e\[[\d;]*[mK]//g; $s }
$game->try('rebus');
is plain($game->keymap), join('', 'A' .. 'Z'), 'keymap is upper case';
is_deeply [ map { plain($_) } $game->hint_color('cigar', 'rebus') ],
    [ 'CIGAR', 'REBUS' ], 'hint words are upper case';

done_testing;
