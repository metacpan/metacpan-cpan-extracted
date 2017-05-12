package Chemistry::PointGroup::D3d;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 12; # number of group elements
my @R  = qw( E C3 C2 i S6 sd ); # symmetry elements of D3d
my @hi = qw( 1 2 3 1 2 3 ); # number of elements in the i-th class
my @I  = qw( A1g A2g Eg A1u A2u Eu ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D3d
my @A1g = qw( 1  1  1  1  1  1 );
my @A2g = qw( 1  1 -1  1  1 -1 );
my @Eg  = qw( 2 -1  0  2 -1  0 );
my @A1u = qw( 1  1  1 -1 -1 -1 );
my @A2u = qw( 1  1 -1 -1 -1  1 );
my @Eu  = qw( 2 -1  0 -2  1  0 );

# my (%A1g, %A2g, %Eg, %A1u, %A2u, %Eu);
# @A1g{@R} = @A1g; # A1g
# @A2g{@R} = @A2g; # A2g
# @Eg{@R} = @Eg; # Eg
# @A1u{@R} = @A1u; # A1u
# @A2u{@R} = @A2u; # A2u
# @Eu{@R} = @Eu; # Eu


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+-------------------------------+------+
| D3d |  E   2C3  3C2   i   2S6  3sd  |      |
+-----+-------------------------------+------+
| A1g |  1    1    1    1    1    1   |      |
| A2g |  1    1   -1    1    1   -1   |      |
| Eg  |  2   -1    0    2   -1    0   |      |
| A1u |  1    1    1   -1   -1   -1   |      |
| A2u |  1    1   -1   -1   -1    1   |  z   |
| Eu  |  2   -1    0   -2    1    0   |  x,y |
+-----+-------------------------------+------+  
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
	# E C3 C2 i S6 sd
	# proper operations   ( Ur - 2 ) (1 + 2 cos(r))
	my $X_E  = sprintf "%0.f",  ($self->{E}  - 2) * (1  + 2 * 1);
	my $X_C3 = sprintf "%0.f",  ($self->{C3} - 2) * (1  + 2 * (-0.5));
	my $X_C2 = sprintf "%0.f",  ($self->{C2} - 2) * (1  + 2 * (-1));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i  = sprintf "%0.f",  $self->{i}  * (-1  + 2 * (-1));
	my $X_S6 = sprintf "%0.f",  $self->{S6} * (-1  + 2 * 0.5);
	my $X_sd = sprintf "%0.f",  $self->{sd} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C3, $X_C2, $X_i, $X_S6, $X_sd);
	
	# Irreducible representation
	my $s = 0;
	my $n_A1g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1g[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A2g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2g[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eg[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A1u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1u[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A2u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2u[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eu[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A1g ,  $n_A2g ,  $n_Eg ,  $n_A1u , $n_A2u, $n_Eu);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D3d - Point group D3d

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
