package Chemistry::PointGroup::C4h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 8; # number of group elements
my @R  = qw( E C4 C2 C4_3 i S4_3 sh S4 ); # symmetry elements of C4h
my @hi = qw( 1 1 1 1 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( Ag Bg Eg Au Bu Eu ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C4h
my @Ag = qw( 1  1  1  1  1  1  1  1 ); 
my @Bg = qw( 1 -1  1 -1  1 -1  1 -1 );
my @Eg = qw( 2  0 -2  0  2  0 -2  0 );
my @Au = qw( 1  1  1  1 -1 -1 -1 -1 ); 
my @Bu = qw( 1 -1  1 -1 -1  1 -1  1 );
my @Eu = qw( 2  0 -2  0 -2  0  2  0 );

# my (%Ag, %Bg, %Eg, %Au, %Bu, %Eu);
# @Ag{@R} = @Ag; # Ag
# @Bg{@R} = @Bg; # Bg
# @Eg{@R} = @Eg; # Eg
# @Au{@R} = @Au; # Au
# @Bu{@R} = @Bu; # Bu
# @Eu{@R} = @Eu; # Eu


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+------------------------------------+------+
| C4h |  E  C4  C2  C4_3  i  S4_3  sh  S4  |      |
+-----+------------------------------------+------+
|  Ag |  1   1   1    1   1    1   1   1   |      |
|  Bg |  1  -1   1   -1   1   -1   1  -1   |      |
|  Eg |  2   0  -2    0   2    0  -2   0   |      |
|  Au |  1   1   1    1  -1   -1  -1  -1   |  z   |
|  Bu |  1  -1   1   -1  -1    1  -1   1   |      |
|  Eu |  2   0  -2    0  -2    0   2   0   |  x,y |
+-----+------------------------------------+------+  
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
	my $X_E    = sprintf "%0.f",  ($self->{E}    - 2) * (1  + 2 * 1);
	my $X_C4   = sprintf "%0.f",  ($self->{C4}   - 2) * (1  + 2 * 0);
	my $X_C2   = sprintf "%0.f",  ($self->{C2}   - 2) * (1  + 2 * (-1));
	my $X_C4_3 = sprintf "%0.f",  ($self->{C4_3} - 2) * (1  + 2 * 0);
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i    = sprintf "%0.f",  $self->{i}    * (-1  + 2 * (-1));
	my $X_S4_3 = sprintf "%0.f",  $self->{S4_3} * (-1  + 2 * 0);
	my $X_sh   = sprintf "%0.f",  $self->{sh}   * (-1  + 2 * 1);
	my $X_S4   = sprintf "%0.f",  $self->{S4}   * (-1  + 2 * 0);
	
	# in the same order of @hi
	my @rr= ($X_E ,$X_C4 ,$X_C2, $X_C4_3, $X_i, $X_S4_3, $X_sh, $X_S4); 
	
	# Irreducible representation
	my $s = 0;
	my $n_Ag = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ag[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Bg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Bg[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eg[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Au = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Au[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Bu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Bu[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eu[$_] , $s] } (0..$#hi))[-1]->[1];

							
							
							
	my @ri = ($n_Ag , $n_Bg , $n_Eg , $n_Au , $n_Bu , $n_Eu );
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C4h - Point group C4h

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
