use warnings;
use strict;
use Test::More;
use C::Utility qw/remove_quotes/;

is (remove_quotes ('"baba"'), 'baba');
is (remove_quotes ('"baba" "bubu"'), 'bababubu');
is (remove_quotes ('"baba\\" \\"bubu"'), 'baba\\" \\"bubu');
done_testing ();
