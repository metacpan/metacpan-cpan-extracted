package Chemistry::PointGroup::C6h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 12; # number of group elements
my @R  = qw( E C6 C3 C2 C3_2 C6_5 i S3_5 S6_5 sh S6 S3 ); # symmetry elements of C6h
my @hi = qw( 1 1 1 1 1 1 1 1 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( Ag Bg E1g E2g Au Bu E1u E2u ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C6h
my @Ag  = qw( 1  1  1  1  1  1  1  1  1  1  1  1 );
my @Bg  = qw( 1 -1  1 -1  1 -1  1 -1  1 -1  1 -1 );
my @E1g = qw( 2  1 -1 -2 -1  1  2  1 -1 -2 -1  1 );
my @E2g = qw( 2 -1 -1  2 -1 -1  2 -1 -1  2 -1 -1 );
my @Au  = qw( 1  1  1  1  1  1 -1 -1 -1 -1 -1 -1 );
my @Bu  = qw( 1 -1  1 -1  1 -1 -1  1 -1  1 -1  1 );
my @E1u = qw( 2  1 -1 -2 -1  1 -2 -1  1  2  1 -1 );
my @E2u = qw( 2 -1 -1  2 -1 -1 -2  1  1 -2  1  1 );

# my (%Ag,  %Bg, %E1g, %E2g, %Au, %Bu, %E1u, %E2u);
# @Ag{@R}  = @Ag;
# @Bg{@R}  = @Bg;
# @E1g{@R} = @E1g;
# @E2g{@R} = @E2g;
# @Au{@R}  = @Au;
# @Bu{@R}  = @Bu;
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
+-----+--------------------------------------------------------+-----+
| C6h |  E  C6  C3  C2  C3_2  C6_5  i  S3_5  S6_5  sh  S6  S3  |     |
+-----+--------------------------------------------------------+-----+
|  Ag |  1   1   1   1    1    1    1    1    1    1    1   1  |     |
|  Bg |  1  -1   1  -1    1   -1    1   -1    1   -1    1  -1  |     |
| E1g |  2   1  -1  -2   -1    1    2    1   -1   -2   -1   1  |     |
| E2g |  2  -1  -1   2   -1   -1    2   -1   -1    2   -1  -1  |     |
|  Au |  1   1   1   1    1    1   -1   -1   -1   -1   -1  -1  | z   |
|  Bu |  1  -1   1  -1    1   -1   -1    1   -1    1   -1   1  |     |
| E1u |  2   1  -1  -2   -1    1   -2   -1    1    2    1  -1  | x,y |
| E2u |  2  -1  -1   2   -1   -1   -2    1    1   -2    1   1  |     |
+-----+--------------------------------------------------------+-----+  
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
	# E C6 C3 C2 C3_2 C6_5 i S3_5 S6_5 sh S6 S3
	# proper operations   ( Ur - 2 ) (1 + 2 cos(r))
	my $X_E    = sprintf "%0.f",  ($self->{E}    - 2) * (1  + 2 * 1);
	my $X_C6   = sprintf "%0.f",  ($self->{C6}   - 2) * (1  + 2 * (0.5));
	my $X_C3   = sprintf "%0.f",  ($self->{C3}   - 2) * (1  + 2 * (-0.5));
	my $X_C2   = sprintf "%0.f",  ($self->{C2}   - 2) * (1  + 2 * (-1));
	my $X_C3_2 = sprintf "%0.f",  ($self->{C3_2} - 2) * (1  + 2 * (-0.5));
	my $X_C6_5 = sprintf "%0.f",  ($self->{C6_5} - 2) * (1  + 2 * (0.5));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i    = sprintf "%0.f",  $self->{i}    * (-1  + 2 * (-1));
	my $X_S3_5 = sprintf "%0.f",  $self->{S3_5} * (-1  + 2 * (-0.5));
	my $X_S6_5 = sprintf "%0.f",  $self->{S6_5} * (-1  + 2 * (0.5));
	my $X_sh   = sprintf "%0.f",  $self->{sh}   * (-1  + 2 * 1);
	my $X_S6   = sprintf "%0.f",  $self->{S6}   * (-1  + 2 * (0.5));
	my $X_S3   = sprintf "%0.f",  $self->{S3}   * (-1  + 2 * (-0.5));
	
	# in the same order of @hi
	my @rr= ($X_E, $X_C6, $X_C3, $X_C2, $X_C3_2, $X_C6_5,
	         $X_i, $X_S3_5, $X_S6_5, $X_sh, $X_S6, $X_S3); # reducible representation
	
	# irreducible representation
	# Ag 
	my $s = 0;
	my $n_Ag = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ag[$_] , $s] } (0..$#hi))[-1]->[1];
	# Bg 
	$s = 0;
	my $n_Bg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Bg[$_] , $s] } (0..$#hi))[-1]->[1];
	# E1g 
	$s = 0;
	my $n_E1g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E1g[$_] , $s] } (0..$#hi))[-1]->[1];
	# E2g 
	$s = 0;
	my $n_E2g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E2g[$_] , $s] } (0..$#hi))[-1]->[1];
	# Au
	$s = 0;
	my $n_Au = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Au[$_] , $s] } (0..$#hi))[-1]->[1];
	# Bu
	$s = 0;
	my $n_Bu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Bu[$_] , $s] } (0..$#hi))[-1]->[1];
	# E1u
	$s = 0;
	my $n_E1u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E1u[$_] , $s] } (0..$#hi))[-1]->[1];
	# E2u
	$s = 0;
	my $n_E2u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E2u[$_] , $s] } (0..$#hi))[-1]->[1];
	
	
	my @ri = ($n_Ag, $n_Bg, $n_E1g, $n_E2g,
	          $n_Au, $n_Bu, $n_E1u, $n_E2u);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C6h - Point group C6h

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
