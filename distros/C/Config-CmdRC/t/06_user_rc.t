use strict;
use warnings;
use Test::More;

BEGIN {
    @ARGV = ('--rc' => 'share/dir1/.akirc');
}

use Config::CmdRC 'share/.foorc';

is RC->{bar}, undef;
is RC->{aki}, 1;

done_testing;
