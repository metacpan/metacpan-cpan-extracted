use t::Util;

eval <<"HERE";
package App::git::ship::perl::test;
use App::git::ship 'App::git::ship::perl';
has foo => sub {1};
HERE

ok !$@, 'compiled App::git::ship::perl::test' or diag $@;
my $ship = App::git::ship::perl::test->new;
isa_ok($ship, 'App::git::ship::perl');
isa_ok($ship, 'App::git::ship');
can_ok($ship, 'foo');

done_testing;
