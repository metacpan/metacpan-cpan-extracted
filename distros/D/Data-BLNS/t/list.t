use warnings;
use strict;

use Test::More;

use Data::BLNS;

my @list = get_naughty_strings();

ok @list > 0 => 'Non-empty list';

my $n = 0;
for my $next_str (@list) {
    if (!$n) {
        ok !length($next_str) => "Empty element $n";
    }
    else {
        ok length($next_str) => "Non-empty element $n";
    }
    $n++;
}


done_testing();

