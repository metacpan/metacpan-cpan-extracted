use Test::More;

for my $module (qw(
   Coro::PrioChannel
)) {
   use_ok($module);
}

done_testing();
