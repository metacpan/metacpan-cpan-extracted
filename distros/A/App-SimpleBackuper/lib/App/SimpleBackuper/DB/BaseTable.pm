package App::SimpleBackuper::DB::BaseTable;

use strict;
use warnings FATAL => qw( all );
use Carp;
use Data::Dumper;

sub new { bless [] => shift }

sub find_row {
	my $self = shift;
	my($from, $to) = $self->_find(@_);
	die "Found more then one" if $to > $from;
	return undef if $from > $to;
	return $self->unpack( $self->[ $from ] );
}

sub find_all {
	my($self) = shift;
	my($from, $to) = $self->_find(@_);
	#warn "$self->_find(@_): from=$from, to=$to";
	#warn "self=[@$self]";
	my @result = map { $self->unpack( $self->[ $_ ] ) } $from .. $to;
	return \@result;
}

=pod Binary search
Parameters:
	 0	- search query us hashref with fields & values.
	 	Packed record must begins on this fields.
		All fields must be a fixed width when packed.
Result:
	[0]	- index of begin of range of matches;
	[1]	- index of end of range of matches;
	For empty array result always is 0, -1.
	If nothing found, you can insert new value with queried fields values to index of begin of range of matches and it not broke sorting
=cut
sub _find {
	my($self, $data) = @_;
	
	return 0, -1 if ! @$self;
	
	$data = $self->pack($data) if ref($data);
	
	my($from, $to, $min_from, $min_to, $max_from, $max_to) = (undef, undef, 0, 0, $#$self, $#$self);
	while(! defined $from or ! defined $to) {
		
		my $mid_from = int($min_from + ($max_from - $min_from) / 2);
		my $mid_to = int($min_to + ($max_to - $min_to) / 2);
		
		my $cmp;
		if(! defined $from) {
			$cmp = $data cmp substr( $self->[ $mid_from ], 0, length($data) );
			if($cmp == -1) {			# data < mid_from
				if($mid_from == 0) {
					return 0, -1;
				} else {
					$cmp = $data cmp substr( $self->[ $mid_from - 1 ], 0, length($data) );
					if($cmp == -1) {	# data < mid_from-1
						$max_from = $mid_from - 1;
						return 0, -1 if $max_from < 0;
					}
					elsif($cmp == 1) {	# data > mid_from-1
						return $mid_from, $mid_from - 1;
					}
					else {				# data = mid_from-1
						$max_from = $to = $mid_from - 1;
					}
				}
			}
			elsif($cmp == 1) {			# data > mid_from
				$min_from = $mid_from + 1;
				return $#$self + 1, $#$self if $min_from > $#$self;
			}
			else {						# data = mid_from
				if($mid_from == 0) {
					$from = 0;
				} else {
					$cmp = $data cmp substr( $self->[ $mid_from - 1 ], 0, length($data) );
					if($cmp == -1) {	# data < mid_from-1
						die "Array is not sorted: item #".($mid_from - 1)." > item #$mid_from ($self->[$mid_from-1] > $self->[$mid_from])";
					}
					elsif($cmp == 1) {	# data > mid_from-1
						$from = $mid_from;
					}
					else {				# data = mid_from-1
						$max_from = $mid_from - 1;
						return 0, -1 if $max_from < 0;
					}
				}
			}
		}
		
		if(! defined $to) {
			$cmp = $data cmp substr( $self->[ $mid_to ], 0, length($data) );
			if($cmp == 1) {				# data > mid_to
				if($mid_to == $#$self) {
					return $#$self + 1, $#$self;
				} else {
					$cmp = $data cmp substr( $self->[ $mid_to + 1 ], 0, length($data) );
					if($cmp == 1) {		# data > mid_to+1
						$min_to = $mid_to + 2;
						return $#$self + 1, $#$self if $min_to > $#$self;
					}
					elsif($cmp == -1) {	# data < mid_to+1
						return $mid_to + 1, $mid_to;
					}
					else {				# data = mid_to+1
						$min_to = $from = $mid_to + 1;
					}
				}
			}
			elsif($cmp == -1) {			# data < mid_to
				$max_to = $mid_to;
			}
			else {						# data = mid_to
				if($mid_to == $#$self) {
					$to = $#$self;
				} else {
					$cmp = $data cmp substr( $self->[ $mid_to + 1 ], 0, length($data) );
					if($cmp == -1) {	# data < mid_to+1
						$to = $mid_to;
					}
					elsif($cmp == 1) {	# data > mid_to+1
						die "Array is not sorted: item #$mid_to > item #".($mid_to + 1)." ($self->[$mid_to] > $self->[$mid_to+1])";
					}
					else {				# data = mid_to+1
						$min_to = $mid_to + 1;
					}
				}
			}
		}
	}
	
	return $from, $to;
}

sub upsert {
	my($self, $search_row, $data) = @_;
	
	$_ = $self->pack( $_ ) foreach grep { ref $_ } $search_row, $data;
	
	my($from, $to) = $self->_find( $search_row );
	
	if($to < $from) {
		splice( @$self, $from, 0, $data );
	} else {
		die "Found more then 1 row, can't update" if $to > $from;
		$self->[ $from ] = $data;
	}
	
	return $self;
}

sub delete {
	my($self, $row) = @_;
	
	my($from, $to) = $self->_find($row);
	confess "Value ".Data::Dumper->new($row)->Indent(0)->Terse(1)->Pair('=>')->Quotekeys(0)->Sortkeys(1)->Dump()." wasn't found in $self" if $to < $from;
	splice(@$self, $from, $to - $from + 1);
	
	return $self;
}

use App::SimpleBackuper::DB::Packer;
sub packer { shift; App::SimpleBackuper::DB::Packer->new( @_ ) }

1;
