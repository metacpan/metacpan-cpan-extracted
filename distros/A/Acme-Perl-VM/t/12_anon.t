#!perl -w

use strict;
use Test::More tests => 14;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

is_deeply run_block{ [ ] }, [ ];
is_deeply run_block{ [1] }, [1];
is_deeply run_block{ [1, 2, 3] }, [1, 2, 3];

is_deeply run_block{ +{} }, {};
is_deeply run_block{ +{foo => 1} }, {foo => 1};
is_deeply run_block{ +{foo => 1, bar => 2, foo => 3} }, {foo => 3, bar => 2};

sub f{
    return [1, 2, 3];
}
is_deeply run_block{ f() }, [1, 2, 3];

sub g{
    return { foo => 'bar' };
}
is_deeply run_block{ g() }, {foo => 'bar'};

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
