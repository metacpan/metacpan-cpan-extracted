package Chemistry::PointGroup::Td;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 24; # number of group elements
my @R  = qw( E C3 C2 S4 sd ); # symmetry elements of Td
my @hi = qw( 1  8  3  6  6 ); # number of elements in the i-th class
my @I  = qw( A1 A2 E T1 T2 ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of Td
my @A1 = qw( 1  1  1  1  1 );
my @A2 = qw( 1  1  1 -1 -1 );
my @E  = qw( 2 -1  2  0  0 );
my @T1 = qw( 3  0 -1  1 -1 );
my @T2 = qw( 3  0 -1 -1  1 );

# my (%A1, %A2, %E, %T1, %T2);
# @A1{@R} = @A1; # A1
# @A2{@R} = @A2; # A2
# @E{@R}  = @E;  # E
# @T1{@R} = @T1; # T1
# @T2{@R} = @T2; # T2

sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+---------------------------+-------+
|  Td |  E   8C3  3C2  6S4  6sd   |       |
+-----+---------------------------+-------+
|  A1 |  1    1    1    1    1    |       |
|  A2 |  1    1    1   -1   -1    |       |
|  E  |  2   -1    2    0    0    |       |
|  T1 |  3    0   -1    1   -1    |       |
|  T2 |  3    0   -1   -1    1    | x,y,x |
+-----+---------------------------+-------+  
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
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_S4  = sprintf "%0.f",  $self->{S4} * (-1  + 2 * (0));
	my $X_sd  = sprintf "%0.f",  $self->{sd} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C3, $X_C2, $X_S4, $X_sd);
	
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

	$s = 0;
	my $n_T1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $T1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_T2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $T2[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A1, $n_A2, $n_E, $n_T1, $n_T2);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::Td - Point group Td

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
