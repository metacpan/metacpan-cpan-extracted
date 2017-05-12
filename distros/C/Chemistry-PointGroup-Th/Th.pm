package Chemistry::PointGroup::Th;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 24; # number of group elements
my @R  = qw( E C3 C3_2 C2 i S6 S6_5 sh ); # symmetry elements of Th
my @hi = qw( 1  4  4  3  1  4  4  4  3 ); # number of elements in the i-th class
my @I  = qw( Ag Au Eg Eu Tg Tu ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of Th
my @Ag = qw( 1  1  1  1  1  1  1  1 );
my @Au = qw( 1  1  1  1 -1 -1 -1 -1 );
my @Eg = qw( 2 -1 -1  2  2 -1 -1  2 );
my @Eu = qw( 2 -1 -1  2 -2  1  1 -2 );
my @Tg = qw( 3  0  0 -1  1  0  0 -1 );
my @Tu = qw( 3  0  0 -1 -1  0  0  1 );

# my (%Ag, %Au, %Eg, %Eu, %Tg, %Tu);
# @Ag{@R} = @Ag; # Ag
# @Au{@R} = @Au; # Au
# @Eg{@R} = @Eg; # Eg
# @Eu{@R} = @Eu; # Eu
# @Tg{@R} = @Tg; # Tg
# @Tu{@R} = @Tu; # Tu

sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+---------------------------------------------+-------+
|  Th |  E   4C3  4C3_2  3C2   i   4S6  4S6_5  3sh  |       |
+-----+---------------------------------------------+-------+
|  Ag |  1    1     1     1    1    1     1     1   |       |
|  Au |  1    1     1     1   -1   -1    -1    -1   |       |
|  Eg |  2   -1    -1     2    2   -1    -1     2   |       |
|  Eu |  2   -1    -1     2   -2    1     1    -2   |       |
|  Tg |  3    0     0    -1    1    0     0    -1   |       |
|  Tu |  3    0     0    -1   -1    0     0     1   | x,y,x |
+-----+---------------------------------------------+-------+  
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
	my $X_E    = sprintf "%0.f",  ($self->{E}  - 2)   * (1  + 2 * 1);
	my $X_C3   = sprintf "%0.f",  ($self->{C3} - 2)   * (1  + 2 * (-0.5));
	my $X_C3_2 = sprintf "%0.f",  ($self->{C3_2} - 2) * (1  + 2 * (-0.5));
	my $X_C2   = sprintf "%0.f",  ($self->{C2} - 2)   * (1  + 2 * (-1));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i    = sprintf "%0.f",  $self->{i}    * (-1  + 2 * (-1));
	my $X_S6   = sprintf "%0.f",  $self->{S6}   * (-1  + 2 * (0.5));
	my $X_S6_5 = sprintf "%0.f",  $self->{S6_5} * (-1  + 2 * (0.5));
	my $X_sh   = sprintf "%0.f",  $self->{sh}   * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C3, $X_C3_2, $X_C2, $X_i, $X_S6, $X_S6_5, $X_sh);
	
	# Irreducible representation
	my $s = 0;
	my $n_Ag = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ag[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Au = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Au[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eg[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eu[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Tg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Tg[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Tu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Tu[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_Ag, $n_Au, $n_Eg, $n_Eu, $n_Tg, $n_Tu);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::Th - Point group Th

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
