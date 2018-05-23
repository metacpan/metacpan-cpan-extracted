#!/usr/bin/env perl
use strict;
use warnings;
use rlib '../../lib';

use Test::More;
note( "Testing B::DeparseTree B::DeparseTree::Node" );

BEGIN {
use_ok( 'B::DeparseTree::Node' );
}

package B::DeparseTree::NodeTest;
sub new($) {
    my ($class) = @_;
    bless {}, $class;
}
sub combine2str($$$) {
    my ($self, $sep, $texts) = @_;
    join($sep, @$texts);
}

my $deparse = __PACKAGE__->new();
my $node = B::DeparseTree::Node->new('op', $deparse, ['X'], 'test', {});
Test::More::cmp_ok $node->{'text'}, 'eq', 'X';

Test::More::note ( "parens_test() testing" );

my $obj = {parens => 1};
my $got = B::DeparseTree::Node::parens_test($obj, 9, 9);
Test::More::cmp_ok $got, '==', 1, 'parens_test() equal precedence parens => 1';

$obj = {'parens' => 0};
foreach my $tup ([8,1], [9,1]) {
    my ($prec, $expect) = @$tup;
    my $true_value = B::DeparseTree::Node::parens_test($obj, 9, $prec);
    Test::More::ok $true_value, "parens_test() parens=>0, $prec <= 9";
}
my $false_value = B::DeparseTree::Node::parens_test($obj, 9, 10);
Test::More::ok !$false_value, 'parens_test() parens=>0, 10 < 9';

foreach my $cx (keys %B::DeparseTree::Node::UNARY_PRECEDENCES) {
    $got = B::DeparseTree::Node::parens_test($obj, $cx, $cx);
    my $false_value = B::DeparseTree::Node::parens_test($obj, $cx, $cx);
    Test::More::ok !$false_value, 'parens_test() UNARY_PRECEDENCES';
}


Test::More::done_testing();
