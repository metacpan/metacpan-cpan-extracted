use strict;
use warnings;
use Test::More;

use Config::CmdRC ();

eval {
    RC();
};
if (my $e = $@) {
    like $e, qr/^Undefined subroutine &[^:]+::RC called/;
}

done_testing;
