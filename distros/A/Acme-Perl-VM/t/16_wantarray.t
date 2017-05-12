#!perl -w

use strict;
use Test::More tests => 18;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

my $x;
sub f{
    $x = wantarray;
}

run_block \&f;
is $x, undef;

scalar(run_block \&f);
is $x, "";

() = run_block \&f;
is $x, 1;


run_block { &f };
is $x, undef;

scalar(run_block { &f });
is $x, "";

() = run_block { &f };
is $x, 1;


run_block { do{ &f } };
is $x, undef;

scalar(run_block { do{ &f } });
is $x, "";

() = run_block { do{ &f } };
is $x, 1;

run_block { { &f } };
is $x, undef;

scalar(run_block { { &f } });
is $x, "";

() = run_block { { &f } };
is $x, 1;

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
