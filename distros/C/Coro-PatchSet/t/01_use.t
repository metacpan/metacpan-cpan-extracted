use Test::More;
use_ok('Coro::PatchSet');

ok(exists $INC{'Coro/PatchSet/Socket.pm'}, 'socket patch loaded');
ok(exists $INC{'Coro/PatchSet/Handle.pm'}, 'handle patch loaded');

done_testing;
