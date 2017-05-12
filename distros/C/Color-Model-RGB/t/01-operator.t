#!perl -T
use strict;
use warnings;
use Test::More 'no_plan';

use Color::Model::RGB qw(:all);

note("--- Operator overload (inherited)\n");
set_format('%02x%02x%02x',1);

my $col0 = -(W);
ok( ($col0->r == -1.0 && $col0->g == -1.0 && $col0->b == -1.0), "negate" );

my $col1 = R + G + B;
ok($col1->hexstr() eq 'ffffff', "addition");

my $col2 = $col1 - rgb(0.5,0.5,0.5);
ok($col2->hexstr() eq '808080', "subtract");

my $col3 = -$col2;
ok($col3->stringify('[%.2f,%.2f,%.2f]',0) eq '[-0.50,-0.50,-0.50]', "negate");

my $col4 = $col2 * 1.5; # 808080 * 1.5
ok($col4->hexstr() eq 'c0c0c0', "multiply");

SKIP: {
	eval { require Math::MatrixReal };
	skip "Math::MatrixReal is not installed", 2 if $@;

	note(" - calculate rgb * matrix");
	my $pi = atan2(1,1) * 4;
	my $s  = 2*$pi/3; # turn 2pi * (1/3)
	my ($sin,$cos) = (sin($s), cos($s));

	my $n0 = sqrt(1/3); # same as W->norm->length;
	my $nn = 1/3;

	my $p  = $nn*(1-$cos);
	my $q  = $n0*$sin;

	my $matrix = Math::MatrixReal->new_from_rows([
		[ $p+$cos, $p-$q,   $p+$q,  ],
		[ $p+$q,   $p+$cos, $p-$q,  ],
		[ $p-$q,   $p+$q,   $p+$cos,],
	]);

	my $rgb = rgb(1.0, 0.75, 0.5);	#ffc080
	$rgb *= $matrix;
	ok ($rgb->hexstr eq 'c080ff', " multiply by Math::MatrixReal - 120dig turn ($rgb)");
	$rgb *= $matrix;
	ok ($rgb->hexstr eq '80ffc0', " multiply by Math::MatrixReal - more 120dig turn ($rgb)");
}

my $col5 = $col4 / 3;
ok($col5->hexstr() eq '404040', "scalar divide");

ok("$col3,$col4,$col5" eq "000000,c0c0c0,404040", "stringify");


