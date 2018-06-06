#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../../lib';

use B qw(main_root);

use Test::More;
note( "Testing B::DeparseTree::PPfns" );

BEGIN {
use_ok( 'B::DeparseTree::PPfns' );
}

my $self = {parens=>0};

ok !B::DeparseTree::PPfns::func_needs_parens($self, '(abc', 0.5, 5);
ok !B::DeparseTree::PPfns::func_needs_parens($self, '(abc', 5, 0);
ok B::DeparseTree::PPfns::func_needs_parens($self, 'abc', 5, 0);


$self = {parens=>1};
ok B::DeparseTree::PPfns::func_needs_parens($self, '(abc', 0.5, 5);

Test::More::done_testing();
