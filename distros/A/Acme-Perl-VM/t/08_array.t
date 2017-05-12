#!perl -w

use strict;
use Test::More tests => 24;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

my $x = run_block{
    my @a;
};
is $x, 0;

$x = run_block{
    my @a = (10);
};
is $x, 1;

$x = run_block{
    my @a = (10, 20);
};
is $x, 2;

my @ary = run_block{
    my @a;
};
is_deeply \@ary, [];

@ary = run_block{
    my @a = (10, 20);
};
is_deeply \@ary, [10, 20];

$x = run_block{
    my @a = (10, 20, 30);
    return $a[1];
};
is $x, 20;

$x = run_block{
    my @a = (10);
    $a[0] += 10;
    return $a[0];
};
is $x, 20;

$x = run_block{
    my @a = (10);
    my $i = 0;
    return $a[$i];
};
is $x, 10;

$x = run_block{
    my @a = (10);
    my $i = 0;
    $a[$i] += 10;
    return $a[$i];
};
is $x, 20;

our @gary = qw(foo bar);

$x = run_block{
    @gary;
};
is $x, 2;

@ary = run_block{
    @gary;
};
is_deeply \@ary, \@gary;

$x = run_block{
    $gary[0] .= 'x';
    return $gary[0];
};
is $x,       'foox';
is $gary[0], 'foox';

$x = run_block{
    my $i = 1;
    $gary[$i] .= 'x';
    return $gary[$i];
};
is $x,       'barx';
is $gary[1], 'barx';

@ary = run_block{
    my @a = ();
    $a[1] = 10;
    return @a;
};
is_deeply \@ary, [undef, 10];

sub f{
    my @a;
    $a[0]++;
    return $a[0];
}

is run_block(\&f), 1;
is run_block(\&f), 1;

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
