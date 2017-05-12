use strict;
use constant HAS_THREADS => eval{ require threads; threads->create(sub{return 1})->join };
use Test::More HAS_THREADS ? ('no_plan') : (skip_all => 'for threaded perls only');
use Time::HiRes qw/sleep/;

{
    package Jopa;
    use parent qw/Class::Accessor::Inherited::XS/;
}

Jopa->mk_inherited_accessors('foo');
my $Jopa=bless{}, 'Jopa';

is($Jopa->foo(77), 77);

my @threads = map +threads->create(sub {
    my $val = $_;
    sleep 0.1;

    for (1..10_000) {
        die if $Jopa->foo($val) != $val;
    }
}), qw/17 42 87 99/;

sleep 0.099;
for (1..10_000) {
    my $val = $_;
    undef *{Jopa::foo};
    Jopa->mk_inherited_accessors(['foo', 'bzzzz']);
    die if $Jopa->foo($val) != $val;
}

$_->join for splice @threads;

ok 1;
