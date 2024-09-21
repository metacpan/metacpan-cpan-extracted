# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'
$^W++;
use strict;
use Test;
use Data::Dumper;

BEGIN {
	$|++;
	plan tests => 137,
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


	#Verify build_mask_cache for ARRAY is case insensitive and order sensitive
	$b1->{build_mask_cache} = {};
	ok( scalar(keys %{$b1->{build_mask_cache}}), 0 );

	ok( $b1->build_mask([qw(A B)]), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 1 );

	ok( $b1->build_mask([qw(A B)]), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 1 );

	ok( $b1->build_mask([qw(a B)]), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 1 );

	ok( $b1->build_mask([qw(B A)]), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 2 );

	#Verify build_mask_cache for HASH is case insensitive, but due to order
	#sensitivity and HASH ordering behavior it may be case sensitive
	ok( $b1->build_mask({A => 1}), 1);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 3 );

	ok( $b1->build_mask({A => 1}), 1);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 3 );

	ok( $b1->build_mask({A => 0}), 0);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 4 );

	ok( $b1->build_mask({a => 1}), 1);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 4 );

	ok( $b1->build_mask({A => 1, B => 1}), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 5 );

	ok( $b1->build_mask({A => 1, b => 1}), 3);
	ok( sub { (scalar(keys %{$b1->{build_mask_cache}}) >= 5 ) && 
				(scalar(keys %{$b1->{build_mask_cache}}) <= 6 )
			} , 1 );

	delete $b1->{build_mask_cache}->{'HASH:A|1|B|1'};
	ok( sub { (scalar(keys %{$b1->{build_mask_cache}}) >= 4 ) && 
				(scalar(keys %{$b1->{build_mask_cache}}) <= 5 )
			} , 1 );

	delete $b1->{build_mask_cache}->{'HASH:B|1|A|1'};
	ok( scalar(keys %{$b1->{build_mask_cache}}), 4 );

	#Verify build_mask_cache for STRING is case insensitive, order sensitive, and space sensitive
	ok( $b1->build_mask('A|B'), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 5 );

	ok( $b1->build_mask('A|B'), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 5 );

	ok( $b1->build_mask('a|B'), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 5 );

	ok( $b1->build_mask('B|A'), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 6 );

	ok( $b1->build_mask('B |A'), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 7 );

	ok( $b1->build_mask('B| A'), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 8 );

	#Verify build_mask_cache for ARRAY is return value mutation safe
	my $foo = $b1->build_mask([qw(A B)]);
	ok( $foo, 3 );
	$foo = 4;
	ok( $foo, 4 );
	ok( $b1->build_mask([qw(A B)]), 3);

	#Verify build_mask_cache for ARRAY is actually used
	$b1->{build_mask_cache}->{'ARRAY:A|B'} = 42;
	ok( $b1->build_mask([qw(A B)]), 42);

	#Verify build_mask_cache for HASH is return value mutation safe
	my $foo = $b1->build_mask({A => 1});
	ok( $foo, 1 );
	$foo = 4;
	ok( $foo, 4 );
	ok( $b1->build_mask({A => 1}), 1);

	#Verify build_mask_cache for HASH is actually used
	$b1->{build_mask_cache}->{'HASH:A|1'} = 42;
	ok( $b1->build_mask({A => 1}), 42);

	#Verify build_mask_cache for STRING is return value mutation safe
	my $foo = $b1->build_mask('A|B');
	ok( $foo, 3 );
	$foo = 4;
	ok( $foo, 4 );
	ok( $b1->build_mask('A|B'), 3);

	#Verify build_mask_cache for STRING is actually used
	$b1->{build_mask_cache}->{'STRING:A|B'} = 42;
	ok( $b1->build_mask('A|B'), 42);

	#Verify add_constants resets build_mask_cache
	$b1->add_constants('BMC_Reset', 42);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 0 );

	ok( $b1->build_mask([qw(A B)]), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 1 );

	ok( $b1->build_mask({A => 1}), 1);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 2 );

	ok( $b1->build_mask('A|B'), 3);
	ok( scalar(keys %{$b1->{build_mask_cache}}), 3 );


	#Verify break_mask_cache works
	$b1->{break_mask_cache} = {};
	ok( scalar(keys %{$b1->{break_mask_cache}}), 0 );

	ok( &hash_dump($b1->break_mask(3)),    &hash_dump({A => 1, B => 1, AB => 1, BA => 1}) );
	ok( scalar(keys %{$b1->{break_mask_cache}}), 1 );

	ok( &hash_dump($b1->break_mask(3)),    &hash_dump({A => 1, B => 1, AB => 1, BA => 1}) );
	ok( scalar(keys %{$b1->{break_mask_cache}}), 1 );

	ok( &hash_dump($b1->break_mask(11)),   &hash_dump({A => 1, B => 1, AB => 1, BA => 1, D => 1}) );
	ok( scalar(keys %{$b1->{break_mask_cache}}), 2 );

	#Verify break_mask_cache is return value mutation safe
	my $foo = $b1->break_mask(3);
	ok( &hash_dump($foo), &hash_dump({A => 1, B => 1, AB => 1, BA => 1}) );
	$foo->{BMC} = 1;
	ok( &hash_dump($foo), &hash_dump({A => 1, B => 1, AB => 1, BA => 1, BMC => 1}) );
	ok( &hash_dump($b1->break_mask(3)), &hash_dump({A => 1, B => 1, AB => 1, BA => 1}) );

	#Verify break_mask_cache is return value mutation safe for first call
	my $foo = $b1->break_mask(5);
	ok( &hash_dump($foo), &hash_dump({A => 1, C => 1, AC => 1, CA => 1}) );
	$foo->{BMC} = 1;
	ok( &hash_dump($foo), &hash_dump({A => 1, C => 1, AC => 1, CA => 1, BMC => 1}) );
	ok( &hash_dump($b1->break_mask(5)), &hash_dump({A => 1, C => 1, AC => 1, CA => 1}) );

	#Verify break_mask_cache is actually used
	$b1->{break_mask_cache}->{3} = {BMC => 42};
	ok( &hash_dump($b1->break_mask(3)), &hash_dump({ BMC => 42 }));

	#Verify add_constants resets break_mask_cache
	$b1->add_constants('BRKMC_Reset', 42);
	ok( scalar(keys %{$b1->{break_mask_cache}}), 0 );

	ok( &hash_dump($b1->break_mask(3)),    &hash_dump({A => 1, B => 1, AB => 1, BA => 1}) );
	ok( scalar(keys %{$b1->{break_mask_cache}}), 1 );


	#Verify explain_mask_cache works
	$b1->{explain_mask_cache} = {};
	ok( scalar(keys %{$b1->{explain_mask_cache}}), 0 );

	ok( &hash_dump($b1->explain_mask(3)),    &hash_dump({AB => 1}) );
	ok( scalar(keys %{$b1->{explain_mask_cache}}), 0 );

	ok( &hash_dump($b1->explain_mask(11)),   &hash_dump({AB => 1, D => 1}) );
	ok( scalar(keys %{$b1->{explain_mask_cache}}), 1 );

	ok( &hash_dump($b1->explain_mask(11)),   &hash_dump({AB => 1, D => 1}) );
	ok( scalar(keys %{$b1->{explain_mask_cache}}), 1 );

	ok( &hash_dump($b1->explain_mask(15)),   &hash_dump({ABC => 1, D => 1}) );
	ok( scalar(keys %{$b1->{explain_mask_cache}}), 2 );

	#Verify explain_mask_cache is return value mutation safe
	my $foo = $b1->explain_mask(11);
	ok( &hash_dump($foo), &hash_dump({AB => 1, D => 1}) );
	$foo->{BMC} = 1;
	ok( &hash_dump($foo), &hash_dump({AB => 1, D => 1, BMC => 1}) );
	ok( &hash_dump($b1->explain_mask(11)), &hash_dump({AB => 1, D => 1}) );

	#Verify explain_mask_cache is return value mutation safe for first call
	my $foo = $b1->explain_mask(13);
	ok( &hash_dump($foo), &hash_dump({AC => 1, D => 1}) );
	$foo->{BMC} = 1;
	ok( &hash_dump($foo), &hash_dump({AC => 1, D => 1, BMC => 1}) );
	ok( &hash_dump($b1->explain_mask(13)), &hash_dump({AC => 1, D => 1}) );

	#Verify explain_mask_cache is actually used
	$b1->{explain_mask_cache}->{11} = {BMC => 42};
	ok( &hash_dump($b1->explain_mask(11)), &hash_dump({ BMC => 42 }));

	#Verify add_constants resets explain_mask_cache
	$b1->add_constants('EMC_Reset', 42);
	ok( scalar(keys %{$b1->{explain_mask_cache}}), 0 );

	ok( &hash_dump($b1->explain_mask(11)),   &hash_dump({AB => 1, D => 1}) );
	ok( scalar(keys %{$b1->{explain_mask_cache}}), 1 );

}



sub hash_dump {
	return Data::Dumper->Dump([[sort keys %{$_[0]}], [map {$_[0]->{$_}} sort keys %{$_[0]}]]);
}