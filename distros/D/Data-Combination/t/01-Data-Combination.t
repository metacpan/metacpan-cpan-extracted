use strict;
use warnings;

use Test::More;

BEGIN { use_ok('Data::Combination') };

use Data::Combination;

{
	#Hash testing
	my $result=Data::Combination::combinations({key1=>[qw<1 2 3>], key2=>[qw<a b c>], key3=>"hello"});

	ok defined $result, "Have result";
	ok @$result==9, "Correct count";

	my @expected=(
		{
			'key1' => '1',
			'key2' => 'b',
			'key3' => 'hello',
		},
		{
			'key1' => '1',
			'key2' => 'c',
			'key3' => 'hello',
		},
		{
			'key1' => '1',
			'key2' => 'a',
			'key3' => 'hello',
		},

		{
			'key1' => '2',
			'key2' => 'a',
			'key3' => 'hello'
		},
		{
			'key1' => '2',
			'key2' => 'b',
			'key3' => 'hello'
		},
		{
			'key1' => '2',
			'key2' => 'c',
			'key3' => 'hello',
		},

		{
			'key1' => '3',
			'key2' => 'a',
			'key3' => 'hello'
		},
		{
			'key1' => '3',
			'key2' => 'b',
			'key3' => 'hello',
		},
		{
			'key1' => '3',
			'key2' => 'c',
			'key3' => 'hello',
		},
	);

	#use Data::Dumper;
	#print STDERR "RESULTS: ".Dumper $result;


	#splice results as we find them
	my $found=0;
	for my $e (0..$#expected){
		my $exp=$expected[$e];
		for my $r (0..$result->@*-1){
			my $res=$result->[$r];

			if($res->{key1}=$exp->{key1} and $res->{key2}=$exp->{key2} and $res->{key3}=$exp->{key3}){
				#splice @$result, $r, 1 
				$found++;
				last;
			}
		}
	}

	ok $found==@expected, "Expected values ok";
	ok $found==@$result, "Expected values ok";
}


{
	#Array testing
	my $result=Data::Combination::combinations([[1,2,3],[qw<a b c>],"hello"]);
	my @expected= (
		[
			1,
			'a',
			'hello'
		],
		[
			1,
			'b',
			'hello'
		],
		[
			1,
			'c',
			'hello'
		],
		[
			2,
			'a',
			'hello'
		],
		[
			2,
			'b',
			'hello'
		],
		[
			2,
			'c',
			'hello'
		],
		[
			3,
			'a',
			'hello'
		],
		[
			3,
			'b',
			'hello'
		],
		[
			3,
			'c',
			'hello'
		],
	);
	#use Data::Dumper;
	#print STDERR Dumper $result;
	my $found=0;
	for my $e (0..$#expected){
		my $exp=$expected[$e];
		for my $r (0..$result->@*-1){
			my $res=$result->[$r];

			if($res->[0]=$exp->[0] and $res->[1]=$exp->[1] and $res->[2]=$exp->[2]){
				#splice @$result, $r, 1 
				$found++;
				last;
			}
		}
	}
	ok $found==@expected, "Expected values ok";
	ok $found==@$result, "Expected values ok";
}

done_testing;


