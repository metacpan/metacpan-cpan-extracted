# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
$^W++;
use strict;
use Test;
use Data::Dumper;

BEGIN {
	$|++;
	plan tests => 47,
	todo => [ ]
}

use Data::BitMask;

$Data::Dumper::Sortkeys = 1;
$Data::Dumper::Sortkeys = 1;

# Create empty
{
	my $b1 = Data::BitMask->new();
	ok( scalar($b1->get_constants()), 0 );

	ok( &hash_dump($b1->explain_mask(0)),
			&hash_dump( {} ) );

	eval { $b1->explain_mask(1) };
	ok( $@ =~ /^Unable to break down mask 1 completely.  Found 0\./ );

	eval { $b1->explain_const(0) };
	ok( $@ =~ /^Unable to lookup 0\./ );

	my(@consts) = (
		A  => 1,
		B  => 2,
		AB => 3,
		BA => 3,
		C  => 4,
		AC => 5,
		CA => 5,
		BC => 6,
		CB => 6,
		ABC => 7,
		ACB => 7,
		BAC => 7,
		BCA => 7,
		CAB => 7,
		CBA => 7,
		D => 8,
	);

	$b1->add_constants(
		@consts
	);

	ok( Data::Dumper->Dump([[$b1->get_constants()]]),
			Data::Dumper->Dump([\@consts]) );

	ok( $b1->build_mask('A|B'), 3);
	ok( $b1->build_mask('A |B'), 3);
	ok( $b1->build_mask('A| B'), 3);
	ok( $b1->build_mask('A B'), 3);
	ok( $b1->build_mask('A   B'), 3);
	ok( $b1->build_mask('A |   B'), 3);
	ok( $b1->build_mask('5'), 5);
	ok( $b1->build_mask('-5'), 4294967291);
	ok( $b1->build_mask('A|2'), 3);
	ok( $b1->build_mask('1 |B'), 3);
	ok( $b1->build_mask('A| 2'), 3);
	ok( $b1->build_mask('1 B'), 3);
	ok( $b1->build_mask('A   2'), 3);
	ok( $b1->build_mask('1 |   B'), 3);
	ok( $b1->build_mask('A|5'), 5);
	ok( $b1->build_mask('A|6'), 7);
	ok( $b1->build_mask('A|-4'), 4294967293);

	ok( $b1->build_mask([qw(A B)]), 3);
	ok( $b1->build_mask({A=>1, B=>1}), 3);
	ok( $b1->build_mask({A=>1, B=>1, C=>0}), 3);
	ok( $b1->build_mask({A=>1, 2=>1, C=>0}), 3);
	ok( $b1->build_mask({A=>1, B=>1, 84=>0}), 3);
	ok( $b1->build_mask({A=>1, B=>1, 84=>1}), 87);

	ok( $b1->build_mask({AB=>1}), 3);
	ok( $b1->build_mask({AB=>1, B=>0}), 1);
	ok( $b1->build_mask({AB=>1, 2=>0}), 1);

	ok( $b1->build_mask({Ab=>1}), 3);

	eval { $b1->build_mask({ABb=>1}) };
	ok( $@ =~ /^Unable to find constant \'ABB\'/);

	ok( $b1->explain_const(7), 'ABC');
	ok( &hash_dump($b1->explain_mask(7)),  &hash_dump({ABC => 1}) );
	ok( &hash_dump($b1->explain_mask(3)),  &hash_dump({AB => 1}) );
	ok( &hash_dump($b1->explain_mask(15)), &hash_dump({ABC => 1, D => 1}) );
	ok( &hash_dump($b1->break_mask(3)),    &hash_dump({A => 1, B => 1, AB => 1, BA => 1}) );
	ok( &hash_dump($b1->explain_mask(11)), &hash_dump({AB => 1, D => 1}) );
	ok( &hash_dump($b1->break_mask(11)),   &hash_dump({A => 1, B => 1, AB => 1, BA => 1, D => 1}) );

	eval { $b1->break_mask(21) };
	ok( $@ =~ /^Unable to break down mask 21 completely.  Found 5\./);

	eval { $b1->explain_mask(21) };
	ok( $@ =~ /^Unable to break down mask 21 completely.  Found 5\./);


	my $b2 = Data::BitMask->new(($b1->get_constants())[0..17]);
	ok( &hash_dump($b2->explain_mask(7)),  &hash_dump({AB => 1, AC => 1, BC => 1}) );

	my $b3 = Data::BitMask->new('A' => 1, 'b' => 2, 'Ab' => 3, 'c' => 4, [qw(bc full_match 1)] => 6);

	ok( $b3->build_mask('A|B'), 3 );

	ok( &hash_dump($b3->break_mask(3)),   &hash_dump({A => 1, b => 1, Ab => 1}) );
	ok( &hash_dump($b3->explain_mask(3)), &hash_dump({Ab => 1}) );
	ok( &hash_dump($b3->explain_mask(7)), &hash_dump({Ab => 1, c => 1}) );
}



sub hash_dump {
	return Data::Dumper->Dump([[sort keys %{$_[0]}], [map {$_[0]->{$_}} sort keys %{$_[0]}]]);
}