package Chemistry::PointGroup::D3;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 6; # number of group elements
my @R  = qw( E C3 C2 ); # symmetry elements of D3
my @hi = qw( 1 2 3 ); # number of elements in the i-th class
my @I  = qw( A1 A2 E ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D3
my @A1 = qw( 1  1  1 );
my @A2 = qw( 1  1 -1 );
my @E  = qw( 2 -1  0 );

# my (%A1, %A2, %E);
# @A1{@R} = @A1; # A1
# @A2{@R} = @A2; # A2
# @E{@R}  = @E; # E


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+---------------+------+
|  D3 |  E  2C3  3C2  |      |
+-----+---------------+------+
|  A1 |  1   1    1   |      |
|  A2 |  1   1   -1   |  z   |
|  E  |  2  -1    0   |  x,y |
+-----+---------------+------+  
TABLE
}

sub symmetry_elements {
	return @R;
}

sub normal_modes {
	my $self = shift;
	return (3 * $self->{E} - 6);
}

sub irr {
	my $self = shift;

	# proper operations   ( Ur - 2 ) (1 + 2 cos(r))
	my $X_E  = sprintf "%0.f",  ($self->{E}  - 2) * (1  + 2 * 1);
	my $X_C3 = sprintf "%0.f",  ($self->{C3} - 2) * (1  + 2 * (-0.5));
	my $X_C2 = sprintf "%0.f",  ($self->{C2} - 2) * (1  + 2 * (-1));
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C3, $X_C2);
	
	# Irreducible representation
	my $s = 0;
	my $n_A1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_E = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A1, $n_A2, $n_E);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D3 - Point group D3

=head1 SYNOPSIS

see L<Chemistry::PointGroup>

=head1 DESCRIPTION

see L<Chemistry::PointGroup>

=head1 SEE ALSO

L<Chemistry::PointGroup>

=head1 AUTHOR

Leo Manfredi, E<lt>manfredi@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006 by Leo Manfredi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
