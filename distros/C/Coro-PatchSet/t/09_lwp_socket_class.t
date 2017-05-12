use strict;
use Test::More;

eval {
	require Coro::LWP;
	require Coro::PatchSet::LWP;
};
if ($@) {
	plan skip_all => 'LWP not installed';
}

isa_ok('Net::HTTP', 'Coro::LWP::Socket');

done_testing;
