package AI::Genetic::Pro::Chromosome;

use warnings;
use strict;
use List::Util qw(shuffle first);
use List::MoreUtils qw(first_index);
use Tie::Array::Packed;
#use Math::Random qw(random_uniform_integer);
#=======================================================================
sub new {
	my ($class, $data, $type, $package, $length) = @_;

	my @genes;	
	tie @genes, $package if $package;
	
	if($type eq q/bitvector/){
		#@genes = random_uniform_integer(scalar @$data, 0, 1); 			# this is fastest, but uses more memory
		@genes = map { rand > 0.5 ? 1 : 0 } 0..$length;					# this is faster
		#@genes =  split(q//, unpack("b*", rand 99999), $#$data + 1);	# slow
	}elsif($type eq q/combination/){ 
		#@genes = shuffle 0..$#{$data->[0]}; 
		@genes = shuffle 0..$length; 
	}elsif($type eq q/rangevector/){
  		@genes = map { $_->[1] + int rand($_->[2] - $_->[1] + 1) } @$data[0..$length];
	}else{ 
		@genes = map { 1 + int(rand( $#{ $data->[$_] })) } 0..$length; 
	}

	return bless \@genes, $class;
}
#=======================================================================
sub new_from_data {
	my ($class, $data, $type, $package, $values, $fix_range) = @_;

	die qq/\nToo many elements in the injected chromosome of type "$type": @$values\n/ if $#$values > $#$data;

	my @genes;	
	tie @genes, $package if $package;
	
	if($type eq q/bitvector/){ 
		die qq/\nInproper value in the injected chromosome of type "$type": @$values\n/ 
			if first { not defined $_ or ($_ != 0 and $_ != 1) } @$values;
		@genes = @$values; 
	}elsif($type eq q/combination/){
		die qq/\nToo few elements in the injected chromosome of type "$type": @$values\n/ 
			if $#$values != $#{$data->[0]};
		for my $idx(0..$#$values){
			my $id = first_index { $_ eq $values->[$idx] } @{$data->[0]};	# pomijamy poczatkowy undef
			die qq/\nInproper element in the injected chromosome of type "$type": @$values\n/ if $id == -1;
			push @genes, $id;
		}
	}elsif($type eq q/rangevector/){
		for my $idx(0..$#$values){
			if(defined $values->[$idx]){
				my $min = $data->[$idx]->[1] - $fix_range->[$idx];
				my $max = $data->[$idx]->[2] - $fix_range->[$idx];
				die qq/\nValue out of scope in the injected chromosome of type "$type": @$values\n/ 
					if $values->[$idx] > $max or $values->[$idx] < $min;
				push @genes, $values->[$idx] + $fix_range->[$idx];
			}else{ push @genes, 0; }
		}
	}else{
		for my $idx(0..$#$values){
			my $id = first_index { 
				not defined $values->[$idx] and not defined $_ or 
				defined $_ and defined $values->[$idx] and $_ eq $values->[$idx] 
					} @{$data->[$idx]};	# pomijamy poczatkowy undef
			die qq/\nInproper element in the injected chromosome of type "$type": @$values\n/ if $id == -1;
			push @genes, $id;
		}
	}
	
	return bless \@genes, $class;
}

sub clone
{
	my ($self) = @_;
	my $genes = tied(@{$self})->make_clone;
	return bless($genes);
}

#=======================================================================
1;
