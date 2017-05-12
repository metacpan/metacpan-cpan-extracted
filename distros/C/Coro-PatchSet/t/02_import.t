use Test::More;
use Coro::PatchSet 'handle';

ok(!exists $INC{'Coro/PatchSet/Socket.pm'}, 'socket patch not loaded');
ok(!exists $INC{'Coro/PatchSet/LWP.pm'}, 'lwp patch not loaded');
ok(exists $INC{'Coro/PatchSet/Handle.pm'}, 'handle patch loaded');

done_testing;
