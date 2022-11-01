package Data::Combination;


=head1 NAME

Data::Combination - Hash and Array element combination generator

=head1 SYNOPIS

	use Data::Combination;
	
	#Generate combination of array with two 'fields'
	my $result=Data::Combination::combinations([[1,2,3], [qw(a b c)])
	
	# $result is an array ref of all combinations of the two fields
	[
		[1,a],
		[1,b],
		[1,c],

		[2,a],
		[2,b],
		[2,c],

		[3,a],
		[3,b],
		[3,c]
	]

	#Generate combination of hash with two 'fields'
	my $result=Data::Combination::combinations(key1=>[1,2,3], key2=>[qw(a b c)])

	# $result is an array ref of all combinations of the two fields
	[
		{key1=>1,key2=>a},
		{key1=>2,key2=>a},
		{key1=>3,key2=>a},
		
		{key1=>1,key2=>b},
		{key1=>2,key2=>b},
		{key1=>3,key2=>b},

		{key1=>1,key2=>c},
		{key1=>2,key2=>c},
		{key1=>3,key2=>c},
	]

=head1 DESCRIPTION

C<Data::Combinations> generates hashes or arrays by making combinations of
values for keys with array values.


=head1 EXAMPLES

Array examples:

	===
	input:
	["a","b","c"]

	output:
	[
		["a","b","c"]
	]
	
	===
	input:
	[["a","b","c"]]

	output:
	[
		["a"],
		["b"],
		["c"]
	]

	===
	input:
	[["a","b"], [1,2]];

	output:
	[
		[a, 1],
		[a, 2],
		[b, 1],
		[b, 2]
	]

	===
	input:
	["a", "b", ["x","y"], {key=>"val"}]

	output:
	[
		["a","b","x", {key=>"val"}],
		["a","b","y", {key=>"val"}]
	]

Hash examples:

	===
	input:
	{k1=>"a",k2=>"b",k3=>"c"}

	outputs:
	[
		{k1=>"a",k2=>"b",k3=>"c"}
	]
	
	===
	input:
	{k1=>["a","b","c"]}

	output:
	[
		{k1=>"a"},
		{k2=>"b"},
		{k3=>"c"}
	]

	===
	input:
	{k1=>["a","b"], k2=>[1,2]}

	output:
	[
		{k1=>"a", k2=>1},
		{k1=>"b", k2=>2},
		{k1=>"a", k2=>1},
		{k1=>"b", k2=>2}
	]

	===
	input:
	[
		{k1=>"a", k2=>"b", k3=>["x","y"], k4=>{key=>"val"}}
	]

	output:
	[
		{k1=>"a",k2=>"b",k3=>"x", k4=>{key=>"val"}},
		{k1=>"a",k2=>"b",k3=>"y", k4=>{key=>"val"}}
	]


=head1 API

The module currently has a single function, which isn't exported. To use it it
must be addressed by its full name

=head2 combinations

	my $result=Data::Combinations::combinations $ref;

Generates the combinations of 'fields' in C<$ref>. A 'field' is either a hash
element or array element which contains a reference to an array. If a field
contains another scalar type, it is wrapped into an array of a single element.

If C<$ref> is a hash, the keys are preserved in the outputs, with the values
for each key used for combination. 

If C<$ref> is an array, the indexes are preserved in the outputs, with the
values for each index used for combination. 

Return value is a reference to an array of the created combinations. 


=head1 SEE ALSO

There are other permutation modules. But they only work with flat lists?

L<Algorithm::Permute>

L<Math::Permute::Lists>

L<Math::Combinatorics>

=head1 AUTHOR

Ruben Westerberg, E<lt>drclaw@mac.comE<gt>

=head1 REPOSITORTY and BUGS

Please report any bugs via git hub: L<http://github.com/drclaw1394/perl-data-combination>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2022 by Ruben Westerberg

This library is free software; you can redistribute it
and/or modify it under the same terms as Perl or the MIT
license.

=head1 DISCLAIMER OF WARRANTIES

THIS PACKAGE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS
OR IMPLIED WARRANTIES, INCLUDING, WITHOUT LIMITATION, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE.


=cut

use strict;
use warnings;

our $VERSION = '0.1.0';

use Carp qw<carp>;


#Internal subs
#==============
sub hash_combo {
	my ($mixer, $list)=@_;
	my @counter;	#The current value of the column
	my @keys;	#The field name key for the column
	my @vals;	#array of arrays of value for the keys at the same index

	for (keys %$mixer){
		if(ref($mixer->{$_}) eq "ARRAY"){
			push @vals, $mixer->{$_};	#Push values directly
		}
		else{

			push @vals, [$mixer->{$_}];	#Make an array and then push
		}
		push @counter, 0;			#setup the counter at 0
		push @keys, $_;				#remember the key
	}

	my @output;					#Return 
	my $carry=0;					#Counter carry
	until($carry){
		$counter[0]++; 				#Tick the counter at lsb

		#Process carry
		for my $c_index(0..$#counter){
			$counter[$c_index]+=$carry;	#Add the carry
			$carry=0;			#reset carry

			if($counter[$c_index] >= $vals[$c_index]->@*){
				$counter[$c_index]=0;
				$carry=1;
			}
			last unless $carry; #exit loop when no carry
		}

		#Generate a new hash with the combination fields
		my %hash;
		for my $c_index(0..$#counter){
			$hash{$keys[$c_index]}=$vals[$c_index][$counter[$c_index]];
		}
		push @output, \%hash;
	}
	\@output;	
}

sub array_combo {
	my ($mixer, $list)=@_;
	my @counter;	#The current value of the column
	my @keys;	#The field name key for the column
	my @vals;	#array of arrays of value for the keys at the same index

	for (0..$mixer->@*-1){
		if(ref($mixer->[$_]) eq "ARRAY"){
			push @vals, $mixer->[$_];	#Push values directly
		}
		else{

			push @vals, [$mixer->[$_]];	#Make an array and then push
		}
		push @counter, 0;			#setup the counter at 0
		push @keys, $_;				#remember the key
	}

	my @output;					#Return 
	my $carry=0;					#Counter carry
	until($carry){
		$counter[0]++; 				#Tick the counter at lsb

		#Process carry
		for my $c_index(0..$#counter){
			$counter[$c_index]+=$carry;	#Add the carry
			$carry=0;			#reset carry

			if($counter[$c_index] >= $vals[$c_index]->@*){
				$counter[$c_index]=0;
				$carry=1;
			}
			last unless $carry; #exit loop when no carry
		}

		#Generate a new hash with the combination fields
		my @array;
		for my $c_index(0..$#counter){
			$array[$keys[$c_index]]=$vals[$c_index][$counter[$c_index]];
		}
		push @output, \@array;
	}
	\@output;	
}

#Public subs
sub combinations {
	my $ref=ref($_[0]);
	if($ref eq "HASH"){
		&hash_combo;
	}
	elsif($ref eq "ARRAY"){
		&array_combo;
	}
	else {
		carp "Only hash and array reference is allowed";
	}
}
1;
__END__
