use Test::More tests => 6;

require_ok( 'AI::ConfusionMatrix' );
use AI::ConfusionMatrix;

my $hash = {
    1978 => {
        1978 => 5,
        1974 => 1,
    },
    2005 => {
        1978 => 1,
        2005 => 3,
        2002 => 1
    },
    2003 => {
        2005 => 2,
        2003 => 7,
    }
};


my %cmData = getConfusionMatrix($hash);
is($cmData{stats}{2003}{tp}, 7, 'Test parsing true positives');
is($cmData{stats}{2005}{sensitivity}, 60, 'Test parsing sensitivity');
is($cmData{totals}{tp}, 15, 'Test parsing total true positives');
is($cmData{totals}{2003}, 7, 'Test parsing total');
is_deeply($cmData{columns}, [1974, 1978, 2002, 2003, 2005], 'Test parsing columns');

