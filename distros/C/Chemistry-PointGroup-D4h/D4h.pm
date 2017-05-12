package Chemistry::PointGroup::D4h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 16; # number of group elements
my @R  = qw( E C4 C2 C2f C2s i S4 sh sv sd ); # symmetry elements of D4h
my @hi = qw( 1 2 1 2 2 1 2 1 2 2 ); # number of elements in the i-th class
my @I  = qw( A1g A2g B1g B2g Eg A1u A2u B1u B2u Eu ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D4h
my @A1g = qw( 1  1  1  1  1  1  1  1  1  1 );
my @A2g = qw( 1  1  1 -1 -1  1  1  1 -1 -1 );
my @B1g = qw( 1 -1  1  1 -1  1 -1  1  1 -1 );
my @B2g = qw( 1 -1  1 -1  1  1 -1  1 -1  1 );
my @Eg  = qw( 2  0 -2  0  0  2  0 -2  0  0 );
my @A1u = qw( 1  1  1  1  1 -1 -1 -1 -1 -1 );
my @A2u = qw( 1  1  1 -1 -1 -1 -1 -1  1  1 );
my @B1u = qw( 1 -1  1  1 -1 -1  1 -1 -1  1 );
my @B2u = qw( 1 -1  1 -1  1 -1  1 -1  1 -1 );
my @Eu  = qw( 2  0 -2  0  0 -2  0  2  0  0 );


# my (%A1g, %A2g, %B1g, %B2g, %Eg, %A1u, %A2u, %B1u, %B2u, %Eu);
# @A1g{@R} = @A1g;
# @A2g{@R} = @A2g;
# @B1g{@R} = @B1g;
# @B2g{@R} = @B2g;
# @Eg{@R}  = @Eg;
# @A1u{@R} = @A1u;
# @A2u{@R} = @A2u;
# @B1u{@R} = @B1u;
# @B2u{@R} = @B2u;
# @Eu{@R}  = @Eu;


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+----------------------------------------------+-----+
| D4h |  E  2C4  C2  2C2' 2C2"  i  2S4  sh  2sv  2sd |     |
+-----+----------------------------------------------+-----+
| A1g |  1   1    1   1    1    1   1   1    1    1  |     |
| A2g |  1   1    1  -1   -1    1   1   1   -1   -1  |     |
| B1g |  1  -1    1   1   -1    1  -1   1    1   -1  |     |
| B2g |  1  -1    1  -1    1    1  -1   1   -1    1  |     |
| Eg  |  2   0   -2   0    0    2   0  -2    0    0  |     |
| A1u |  1   1    1   1    1   -1  -1  -1   -1   -1  |     |
| A2u |  1   1    1  -1   -1   -1  -1  -1    1    1  | z   |
| B1u |  1  -1    1   1   -1   -1   1  -1   -1    1  |     |
| B2u |  1  -1    1  -1    1   -1   1  -1    1   -1  |     |
| Eu  |  2   0   -2   0    0   -2   0   2    0    0  | x,y |
+-----+----------------------------------------------+-----+  
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
	# E C4 C2 C2f C2s i S4 sh sv sd
	# proper operations   ( Ur - 2 ) (1 + 2 cos(r))
	my $X_E   = sprintf "%0.f",  ($self->{E}   - 2) * (1  + 2 * 1);
	my $X_C4  = sprintf "%0.f",  ($self->{C4}  - 2) * (1  + 2 * 0);
	my $X_C2  = sprintf "%0.f",  ($self->{C2}  - 2) * (1  + 2 * (-1));
	my $X_C2f = sprintf "%0.f",  ($self->{C2f} - 2) * (1  + 2 * (-1));
	my $X_C2s = sprintf "%0.f",  ($self->{C2s} - 2) * (1  + 2 * (-1));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i  = sprintf "%0.f",  $self->{i}  * (-1  + 2 * (-1));
	my $X_S4 = sprintf "%0.f",  $self->{S4} * (-1  + 2 * 0);
	my $X_sh = sprintf "%0.f",  $self->{sh} * (-1  + 2 * 1);
	my $X_sv = sprintf "%0.f",  $self->{sv} * (-1  + 2 * 1);
	my $X_sd = sprintf "%0.f",  $self->{sd} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr= ($X_E, $X_C4, $X_C2, $X_C2f, $X_C2s,
	         $X_i, $X_S4, $X_sh, $X_sv, $X_sd); # reducible representation
	
	# irreducible representation
	# A1g 
	my $s = 0;
	my $n_A1g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1g[$_] , $s] } (0..$#hi))[-1]->[1];
	# A2g 
	$s = 0;
	my $n_A2g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2g[$_] , $s] } (0..$#hi))[-1]->[1];
	# B1g 
	$s = 0;
	my $n_B1g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B1g[$_] , $s] } (0..$#hi))[-1]->[1];
	# B2g 
	$s = 0;
	my $n_B2g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B2g[$_] , $s] } (0..$#hi))[-1]->[1];
	# Eg 
	$s = 0;
	my $n_Eg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eg[$_] , $s] } (0..$#hi))[-1]->[1];
	# A1u 
	$s = 0;
	my $n_A1u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1u[$_] , $s] } (0..$#hi))[-1]->[1];
	# A2u 
	$s = 0;
	my $n_A2u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2u[$_] , $s] } (0..$#hi))[-1]->[1];
	# B1u 
	$s = 0;
	my $n_B1u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B1u[$_] , $s] } (0..$#hi))[-1]->[1];
	# B2u 
	$s = 0;
	my $n_B2u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B2u[$_] , $s] } (0..$#hi))[-1]->[1];
	# Eu 
	$s = 0;
	my $n_Eu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eu[$_] , $s] } (0..$#hi))[-1]->[1];
	
	
	my @ri = ($n_A1g, $n_A2g, $n_B1g, $n_B2g, $n_Eg,
	          $n_A1u, $n_A2u, $n_B1u, $n_B2u, $n_Eu);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D4h - Point group D4h

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
