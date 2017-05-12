package Chemistry::PointGroup::D6h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 24; # number of group elements
my @R  = qw( E C6 C3 C2 C2f C2s i S3 S6 sh sd sv ); # symmetry elements of D6h
my @hi = qw( 1 2 2 1 3 3 1 2 2 1 3 3 ); # number of elements in the i-th class
my @I  = qw( A1g A2g B1g B2g E1g E2g A1u A2u B1u B2u E1u E2u ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D6h
my @A1g = qw( 1  1  1  1  1  1  1  1  1  1  1  1 );
my @A2g = qw( 1  1  1  1 -1 -1  1  1  1  1 -1 -1 );
my @B1g = qw( 1 -1  1 -1  1 -1  1 -1  1 -1  1 -1 );
my @B2g = qw( 1 -1  1 -1 -1  1  1 -1  1 -1 -1  1 );
my @E1g = qw( 2  1 -1 -2  0  0  2  1 -1 -2  0  0 );
my @E2g = qw( 2 -1 -1  2  0  0  2 -1 -1  2  0  0 );
my @A1u = qw( 1  1  1  1  1  1 -1 -1 -1 -1 -1 -1 );
my @A2u = qw( 1  1  1  1 -1 -1 -1 -1 -1 -1  1  1 );
my @B1u = qw( 1 -1  1 -1  1 -1 -1  1 -1  1 -1  1 );
my @B2u = qw( 1 -1  1 -1 -1  1 -1  1 -1  1  1 -1 );
my @E1u = qw( 2  1 -1 -2  0  0 -2 -1  1  2  0  0 );
my @E2u = qw( 2 -1 -1  2  0  0 -2  1  1 -2  0  0 );


# my (%A1g, %A2g, %B1g, %B2g, %E1g, %E2g, %A1u, %A2u, %B1u, %B2u, %E1u, %E2u);
# @A1g{@R} = @A1g;
# @A2g{@R} = @A2g;
# @B1g{@R} = @B1g;
# @B2g{@R} = @B2g;
# @E1g{@R} = @E1g;
# @E2g{@R} = @E2g;
# @A1u{@R} = @A1u;
# @A2u{@R} = @A2u;
# @B1u{@R} = @B1u;
# @B2u{@R} = @B2u;
# @E1u{@R} = @E1u;
# @E2u{@R} = @E2u;


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+----------------------------------------------------------+-----+
| D6h |  E  2C6  2C3   C2  3C2'  3C2"  i  2S3  2S6  sh  3sd  3sv |     |
+-----+----------------------------------------------------------+-----+
| A1g |  1   1    1    1    1     1    1   1    1   1    1    1  |     |
| A2g |  1   1    1    1   -1    -1    1   1    1   1   -1   -1  |     |
| B1g |  1  -1    1   -1    1    -1    1  -1    1  -1    1   -1  |     |
| B2g |  1  -1    1   -1   -1     1    1  -1    1  -1   -1    1  |     |
| E1g |  2   1   -1   -2    0     0    2   1   -1  -2    0    0  |     |
| E2g |  2  -1   -1    2    0     0    2  -1   -1   2    0    0  |     |
| A1u |  1   1    1    1    1     1   -1  -1   -1  -1   -1   -1  |     |
| A2u |  1   1    1    1   -1    -1   -1  -1   -1  -1    1    1  |  z  |
| B1u |  1  -1    1   -1    1    -1   -1   1   -1   1   -1    1  |     |
| B2u |  1  -1    1   -1   -1     1   -1   1   -1   1    1   -1  |     |
| E1u |  2   1   -1   -2    0     0   -2  -1    1   2    0    0  | x,y |
| E2u |  2  -1   -1    2    0     0   -2   1    1  -2    0    0  |     |
+-----+----------------------------------------------------------+-----+  
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
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i  = sprintf "%0.f",  $self->{i}  * (-1  + 2 * (-1));
	my $X_S3 = sprintf "%0.f",  $self->{S3} * (-1  + 2 * (-0.5));
	my $X_S6 = sprintf "%0.f",  $self->{S6} * (-1  + 2 * (0.5));
	my $X_sh = sprintf "%0.f",  $self->{sh} * (-1  + 2 * 1);
	my $X_sd = sprintf "%0.f",  $self->{sd} * (-1  + 2 * 1);
	my $X_sv = sprintf "%0.f",  $self->{sv} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr= ($X_E, $X_C6, $X_C3, $X_C2, $X_C2f, $X_C2s,
	         $X_i, $X_S3, $X_S6, $X_sh, $X_sd, $X_sv); # reducible representation
	
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
	# E1g 
	$s = 0;
	my $n_E1g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E1g[$_] , $s] } (0..$#hi))[-1]->[1];
	# E2g 
	$s = 0;
	my $n_E2g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E2g[$_] , $s] } (0..$#hi))[-1]->[1];
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
	# E1u 
	$s = 0;
	my $n_E1u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E1u[$_] , $s] } (0..$#hi))[-1]->[1];
	# E2u
	$s = 0;
	my $n_E2u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E2u[$_] , $s] } (0..$#hi))[-1]->[1];
	
	
	my @ri = ($n_A1g, $n_A2g, $n_B1g, $n_B2g, $n_E1g, $n_E2g,
	          $n_A1u, $n_A2u, $n_B1u, $n_B2u, $n_E1u, $n_E2u );
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D6h - Point group D6h

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
