#!perl -w

use strict;
use Test::More tests => 10;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

apvm_extern 'Test::More';

run_block{
    my $a = 0;

    $a ||= 10;

    is $a, 10;

    $a ||= 100;

    is $a, 10;

    $a &&= 0;

    is $a, 0;

    $a &&= 100;

    is $a, 0;
};


is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
