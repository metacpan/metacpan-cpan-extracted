BEGIN {
    @ARGV = qw(føø bar bāz);
}

use gum -role;
use Test::More;

is_deeply \@ARGV, [qw(føø bar bāz)],
    'utf8::all effects observed';

ok $INC{'Bubblegum/Role.pm'},
    'Bubblegum::Role loaded';

done_testing;
