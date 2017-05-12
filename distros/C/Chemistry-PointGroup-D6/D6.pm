package Chemistry::PointGroup::D6;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 12; # number of group elements
my @R  = qw( E C6 C3 C2 C2f C2s ); # symmetry elements of D6
my @hi = qw( 1 2 2 1 3 3 ); # number of elements in the i-th class
my @I  = qw( A1 A2 B1 B2 E1 E2 ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D6
my @A1 = qw( 1  1  1  1  1  1 );
my @A2 = qw( 1  1  1  1 -1 -1 );
my @B1 = qw( 1 -1  1 -1  1 -1 );
my @B2 = qw( 1 -1  1 -1 -1  1 );
my @E1 = qw( 2  1 -1 -2  0  0 );
my @E2 = qw( 2 -1 -1  2  0  0 );

# my (%A1, %A2, %B1, %B2, %E1, %E2);
# @A1{@R} = @A1; # A1
# @A2{@R} = @A2; # A2
# @B1{@R} = @B1; # B1
# @B2{@R} = @B2; # B2
# @E1{@R} = @E1; # E1
# @E2{@R} = @E2; # E2


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+----+----------------------------------+------+
| D6 |  E   2C6   2C3   C2   3C2'  3C2" |      |
+----+----------------------------------+------+
| A1 |  1    1    1     1     1     1   |      |
| A2 |  1    1    1     1    -1    -1   |  z   |
| B1 |  1   -1    1    -1     1    -1   |      |
| B2 |  1   -1    1    -1    -1     1   |      |
| E1 |  2    1   -1    -2     0     0   |  x,y |
| E2 |  2   -1   -1     2     0     0   |      |
+----+----------------------------------+------+  
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
	my $X_E   = sprintf "%0.f",  ($self->{E}   - 2) * (1  + 2 * 1);
	my $X_C6  = sprintf "%0.f",  ($self->{C6}  - 2) * (1  + 2 * (0.5));
	my $X_C3  = sprintf "%0.f",  ($self->{C3}  - 2) * (1  + 2 * (-0.5));
	my $X_C2  = sprintf "%0.f",  ($self->{C2}  - 2) * (1  + 2 * (-1));
	my $X_C2f = sprintf "%0.f",  ($self->{C2f} - 2) * (1  + 2 * (-1));
	my $X_C2s = sprintf "%0.f",  ($self->{C2s} - 2) * (1  + 2 * (-1));
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C6, $X_C3, $X_C2, $X_C2f, $X_C2s);
	
	# Irreducible representation
	my $s = 0;
	my $n_A1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B2[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_E1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_E2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E2[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A, $n_B, $n_E);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D6 - Point group D6

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
