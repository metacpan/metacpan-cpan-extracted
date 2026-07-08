use Role::Tiny();
use Test2::V0;
ok(!Role::Tiny::does_role("a", "xyz"), "string");
ok(!Role::Tiny::does_role(1, "xyz"), "n1");
ok(!Role::Tiny::does_role(0, "xyz"), "n0");
ok(!Role::Tiny::does_role({}, "xyz"), "hr");
ok(!Role::Tiny::does_role(bless({}, "abc"), "xyz"), "blessed");


done_testing;
