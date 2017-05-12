#!perl -w

use strict;
use Test::More tests => 18;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

sub Foo::f{ 42 }
sub Foo::g{
    my(undef, $value) = @_;
    $value++;
    return $value;
}
sub Foo::h{
    @_
}

my $x;

$x = run_block{
    Foo->f();
};
is $x, 42;

$x = [run_block{ Foo->f() }];
is_deeply $x, [42];

$x = [run_block{ Foo->f(); Foo->f() }];
is_deeply $x, [42];

$x = run_block{
    Foo->g(42);
};
is $x, 43;

$x = run_block{
    Foo->g(10);
};
is $x, 11;

$x = run_block{
    Foo->g(1, 10, 100);
};
is $x, 2;

for my $i(1 .. 3){
    is_deeply [run_block{ Foo->g($i) }], [$i+1], "($i)";
}

is_deeply [run_block{        Foo->h(10, 20, 30) }], ['Foo', 10, 20, 30];
is_deeply [run_block{ scalar Foo->h(10, 20, 30) }], [4];
is_deeply [scalar run_block{ Foo->h(10, 20, 30) }], [4];


is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
