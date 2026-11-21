#!/usr/bin/perl

use v5.26;
use warnings;

use feature qw( signatures );
no warnings qw( experimental::signatures );

use Test2::V0;

use lib 't/lib';
use TestAppcsvtool;

use App::csvtool;
use App::csvtool::Expr;

# Bunch of tests poking at the internals of the expression generator
# This is a bit fragile because it relies on internals
sub test_expr_code ( $name, $expr, $want_code ) {
   my $n = App::csvtool::Expr::_Parser->new->from_string( $expr );
   my $got_code = App::csvtool::Expr->perl_code_for( $n );

   is( $got_code, $want_code, "Compiled code for $name" );
}

test_expr_code constant => "123.45", '123.45';
test_expr_code field    => "F[1]", '$row->[0]'; # 1-based indexing
test_expr_code add      => "12 + 34", '(12 + 34)';
test_expr_code mul      => "12 * 34", '(12 * 34)';
test_expr_code paren    => "(456)", '456';
test_expr_code prec_1   => "12 + 34 * 56", '(12 + (34 * 56))';
test_expr_code prec_2   => "12 * 34 + 56", '((12 * 34) + 56)';
test_expr_code prec_3   => "(12 + 34) * 56", '((12 + 34) * 56)';
test_expr_code and      => "11 && 22", '(11 && 22)';
test_expr_code or       => "11 || 22", '(11 || 22)';
test_expr_code prec_3   => "F[1] > 0 && F[2] < 0", '(($row->[0] > 0) && ($row->[1] < 0))';

done_testing;
