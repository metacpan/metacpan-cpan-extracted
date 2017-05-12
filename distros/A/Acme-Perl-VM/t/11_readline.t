#!perl -w

use strict;
use Test::More tests => 11;

use Acme::Perl::VM;
use Acme::Perl::VM qw(:perl_h);

my $x = run_block{ <DATA> };
is $x, "foo\n";
$x = run_block{ <DATA> };
is $x, "bar\n";

is_deeply [run_block { <DATA> }], ["a\n", "b\n", "c\n"];
is_deeply [run_block { <DATA> }], [];

open my $in, '<', \'foo';
is scalar(run_block{ readline($in) }), 'foo';

is_deeply \@PL_stack,      [], '@PL_stack is empty';
is_deeply \@PL_markstack,  [], '@PL_markstack is empty';
is_deeply \@PL_scopestack, [], '@PL_scopestack is empty';
is_deeply \@PL_cxstack,    [], '@PL_cxstack is empty';
is_deeply \@PL_savestack,  [], '@PL_savestack is empty';
is_deeply \@PL_tmps,       [], '@PL_tmps is empty';
__DATA__
foo
bar
a
b
c
