use v5.14;
use warnings;
use Test::More 0.98;

use lib 'lib';
use App::Greple::wordle;
use App::Greple::wordle::NYT;
use App::Greple::wordle::ORIGINAL;

# initialize() keeps its state in the module, so run each case in a
# child process.  The answer is picked from the yellow pattern "[answer]".
sub answer_for {
    my @opt = @_;
    my $pid = open(my $from_child, '-|') // die "fork: $!";
    if ($pid == 0) {
	# stay non-interactive even when the test is run from a terminal
	open STDIN, '<', '/dev/null' or die "/dev/null: $!";
	my @argv = @opt;
	App::Greple::wordle::initialize('wordle', \@argv);
	my($answer) = map { /^\[([a-z]+)\]$/ ? $1 : () } @argv;
	print $answer // '';
	exit 0;
    }
    my $answer = do { local $/; <$from_child> };
    close $from_child;
    $answer;
}

# the answer of 2022-03-30 was changed by New York Times
my $nyt  = $App::Greple::wordle::NYT::HIDDEN[284];
my $orig = $App::Greple::wordle::ORIGINAL::HIDDEN[284];
isnt $nyt, $orig, 'datasets differ at index 284';

is answer_for('--series=0', '--index=284'), $nyt, 'default dataset is NYT';
is answer_for('--data=ORIGINAL', '--series=0', '--index=284'), $orig,
    'ORIGINAL dataset can be selected';

done_testing;
