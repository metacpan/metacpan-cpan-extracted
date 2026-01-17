use strict;
use warnings;
use Test::More;
use Test::Fatal;

BEGIN {
	eval {
		require Moose;
		require MooseX::XSAccessor;
		require MooseX::XSConstructor;
		require Types::Common;
		1;
	} or plan skip_all => 'Missing modules';
};

BEGIN {
	package Local::XS;
	use Moose;
	use MooseX::XSAccessor;
	use MooseX::XSConstructor;
	use Types::Common -types;
		
	has n        => ( is => 'ro', isa => Int,      required => 1 );
	has children => ( is => 'ro', isa => ArrayRef, lazy => 1, builder => '_build_children' );
	has sum      => ( is => 'ro', isa => Int,      lazy => 1, builder => '_build_sum' );
	
	sub _build_children {
		my $self = shift;
		return [] if $self->n < 1;
		
		my @kids = map {
			my $n = $_;
			__PACKAGE__->new( n => $n );
		} 0 .. $self->n - 1;
		return \@kids;
	}
	
	sub _build_sum {
		my $self = shift;
		
		my $sum = $self->n;
		$sum += $_->sum for @{ $self->children };
		
		return $sum;
	}

	__PACKAGE__->meta->make_immutable;
};

is( Local::XS->new( n => 0 )->sum, 0);
is( Local::XS->new( n => 1 )->sum, 1);
is( Local::XS->new( n => 2 )->sum, 3);
is( Local::XS->new( n => 3 )->sum, 7);

done_testing;