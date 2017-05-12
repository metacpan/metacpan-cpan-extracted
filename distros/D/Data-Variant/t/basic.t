#!/usr/bin/env perl -T
# -*- perl -*-
use strict;
use warnings;
use Test::More tests => 9;
use Data::Variant;
use Switch;
use vars qw{&Num &Add &Mul};

ok( 1, 'Loaded okay');

ok( register_variant("Arith", 	
    "Num <NUM>", "Add Arith Arith", "Mul Arith Arith"), 'register_variant' );

our ($num1,$num2,$i);

$num1 = Num 40;
$num2 = Num 3;

ok( ((defined $num1) and (defined $num2)), 'Initialized numbers');

ok( match($num1,"Num",$i), 'Matches properly' );

is( evaluate($num1), 40, '$num1 is okay');
is( evaluate($num2), 3,  '$num2 is okay');

# A more complex structure
our ($term, $factor);

$factor = Add $num1, $num2;
$term = Mul $num1, $factor;
ok( ((defined $term) && (defined $factor)), 'Complex structures defined okay');

is( evaluate($term), 1720, 'Evaluation of complex structure okay');

# Test something that shouldn't work.
my($f1,$f2);
ok( not($num1->match("Add",$f1,$f2)), 'No false match');

#ok( not $f1 =  Num("Badness"), 'No false construction');


sub evaluate {
    my $expr = shift;
    my ($o1,$o2);
    switch($expr->match) {
	case (mkpat "Num", $o1) { return $o1 };
    }

    if ($expr->match("Add", $o1, $o2)) {
	return evaluate($o1) + evaluate ($o2);
    }
    
    set_match($expr);

    if ($expr->match("Mul",$o1,$o2)) {
	return evaluate($o1) * evaluate($o2);
    }

    return -1;
}

exit;
