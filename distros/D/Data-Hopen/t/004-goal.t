#!perl
# 004-goal.t: test Data::Hopen::G::Goal
use rlib 'lib';
use HopenTest;

BEGIN {
    use_ok 'Data::Hopen::G::Goal';
}

my $e = Data::Hopen::G::Goal->new(name=>'foo');
isa_ok($e, 'Data::Hopen::G::Goal');
is($e->name, 'foo', 'Name was set by constructor');
$e->name('bar');
is($e->name, 'bar', 'Name was set by accessor');

done_testing();
