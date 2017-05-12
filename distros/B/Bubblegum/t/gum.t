BEGIN {
    @ARGV = qw(føø bar bāz);
}

use gum;
use Test::More;

is_deeply \@ARGV, [qw(føø bar bāz)],
    'utf8::all effects observed';

ok $INC{'Bubblegum.pm'},
    'Bubblegum loaded';

done_testing;
