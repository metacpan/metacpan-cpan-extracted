BEGIN {
    @ARGV = qw(føø bar bāz);
}

use gum -singleton;
use Test::More;

is_deeply \@ARGV, [qw(føø bar bāz)],
    'utf8::all effects observed';

ok $INC{'Bubblegum/Singleton.pm'},
    'Bubblegum::Singleton loaded';

done_testing;
