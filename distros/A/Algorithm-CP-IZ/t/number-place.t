use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('Algorithm::CP::IZ') };

{
    my $input = [
	[5, 3, 0, 0, 7, 0, 0, 0, 0],
	[6, 0, 0, 1, 9, 5, 0, 0, 0],
	[0, 9, 8, 0, 0, 0, 0, 6, 0],
	[8, 0, 0, 0, 6, 0, 0, 0, 3],
	[4, 0, 0, 8, 0, 3, 0, 0, 1],
	[7, 0, 0, 0, 2, 0, 0, 0, 6],
	[0, 6, 0, 0, 0, 0, 2, 8, 0],
	[0, 0, 0, 4, 1, 9, 0, 0, 5],
	[0, 0, 0, 0, 8, 0, 0, 7, 9],
	];

    my $iz = Algorithm::CP::IZ->new();
    my $vars = [];
    my $all_vars = [];

    for my $r (0..8) {
	my $row = [];
	for my $c (0..8) {
	    my $v;
	    if ($input->[$r]->[$c] == 0) {
		$v = $iz->create_int(1, 9);
	    }
	    else {
		$v = $iz->create_int($input->[$r]->[$c], $input->[$r]->[$c]);
	    }
	    push(@$row, $v);
	    push(@$all_vars, $v);
	}
	push(@$vars, $row);
    }

    for my $i (0..8) {
	# each column
	$iz->AllNeq([map { $vars->[$_]->[$i] } (0..8) ]);

	# each row
	$iz->AllNeq($vars->[$i]);
    }

    # small blocks
    for my $i (0..2) {
	for my $j (0..2) {
	    my $block = [];
	    for my $r ($i*3..$i*3+2) {
		for my $c ($j*3..$j*3+2) {
		    push(@$block, $vars->[$r]->[$c]);
		}
	    }
	    $iz->AllNeq($block);
	}
    }

    my $r = $iz->search($all_vars);
    is($r, 1);

    print STDERR "\n";
    for my $r (0..8) {
	print STDERR "-" x 20, "\n" if ($r % 3 == 0);
	for my $c (0..8) {
	    my $v = $vars->[$r]->[$c];
	    print STDERR "|" if ($c % 3 == 0);
	    print STDERR $v->min, " ";
	}
	print STDERR "\n";
    }
}
