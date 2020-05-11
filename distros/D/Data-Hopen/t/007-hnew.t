#!perl
# t/007-hnew.t: test hnew()
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Data::Hopen';
}

my $e = hnew Entity => 'foo';
isa_ok($e, 'Data::Hopen::G::Entity');
is($e->name, 'foo', 'Name was set by constructor');

$e = hnew 'G::Entity' => 'bar';
isa_ok($e, 'Data::Hopen::G::Entity');
is($e->name, 'bar', 'Name was set by constructor');

done_testing();
