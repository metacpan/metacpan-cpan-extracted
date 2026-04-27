use strict;
use warnings;
use Test::More;

use constant {
    F_GET_SEALS   => 1034,
    F_SEAL_SHRINK => 0x0002,
    F_SEAL_GROW   => 0x0004,
};

use Data::Log::Shared;

my $l = Data::Log::Shared->new_memfd("seal", 4096);
ok $l, "log created";

open(my $fh, '<&=', $l->memfd) or die;
my $seals = fcntl($fh, F_GET_SEALS, 0);
ok $seals & F_SEAL_SHRINK, "F_SEAL_SHRINK set";
ok $seals & F_SEAL_GROW,   "F_SEAL_GROW set";

ok !truncate($fh, 0), "truncate on sealed memfd fails";

$l->append("hello");
is $l->entry_count, 1, "ops still work after sealing";

done_testing;
