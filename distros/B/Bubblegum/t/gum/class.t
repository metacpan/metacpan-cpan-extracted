BEGIN {
    @ARGV = qw(føø bar bāz);
}

use gum -class;
use Test::More;

is_deeply \@ARGV, [qw(føø bar bāz)],
    'utf8::all effects observed';

ok $INC{'Bubblegum/Class.pm'},
    'Bubblegum::Class loaded';

done_testing;
