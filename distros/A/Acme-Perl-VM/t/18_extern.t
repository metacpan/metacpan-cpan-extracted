#!perl -w

use strict;
use Test::More tests => 10;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

apvm_extern \&ok, \&is;

run_block{
    ok 1, 'call an external subroutine';

    is 42, 42;
};

apvm_extern 'Test::More';

run_block{
    like 'foobar', qr/foo/;

    my @a = (1 .. 3);
    is_deeply \@a, [1, 2, 3];
};


is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
