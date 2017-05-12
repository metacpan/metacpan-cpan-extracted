#!perl -w

use strict;
use Test::More tests => 20;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

sub f{ 42 }
sub g{
    my($value) = @_;
    $value++;
    return $value;
}
sub h{
    @_;
}

sub inc{
    $_[0]++;
}

my $x;

$x = run_block{
    f();
};
is $x, 42;

$x = [run_block{ f() }];
is_deeply $x, [42];

$x = [run_block{ f(); f() }];
is_deeply $x, [42];

$x = run_block{
    g(42);
};
is $x, 43;

$x = run_block{
    g(10);
};
is $x, 11;

$x = run_block{
    g(1, 10, 100);
};
is $x, 2;

for my $i(1 .. 3){
    is_deeply [run_block{ g($i) }], [$i+1], "($i)";
}

is_deeply [run_block{        h(10, 20, 30) }], [10, 20, 30];
is_deeply [run_block{ scalar h(10, 20, 30) }], [3];
is_deeply [scalar run_block{ h(10, 20, 30) }], [3];

is run_block{
    my $i = 10;
    inc($i);
    return $i;
}, 11;

is run_block{
    my $i = 10;
    inc($i);
    inc($i);
    return $i;
}, 12;

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
