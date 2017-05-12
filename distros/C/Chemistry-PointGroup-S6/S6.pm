package Chemistry::PointGroup::S6;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 6; # number of group elements
my @R  = qw( E C3 C3_2 i S6_5 S6 ); # symmetry elements of S6
my @hi = qw( 1 1 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( Ag Eg Au Eu ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of S6
my @Ag = qw( 1  1  1  1  1  1 );
my @Eg = qw( 2 -1 -1  2 -1 -1 );
my @Au = qw( 1  1  1 -1 -1 -1 );
my @Eu = qw( 2 -1 -1 -2  1  1 );

# my (%Ag, %Eg, %Au, %Eu);
# @Ag{@R} = @Ag; # Ag
# @Eg{@R} = @Eg; # Eg
# @Au{@R} = @Au; # Au
# @Eu{@R} = @Eu; # Eu


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+----+------------------------------+------+
| S6 |  E   C3   C3_2  i  S6_5  S6  |      |
+----+------------------------------+------+
| Ag |  1    1    1    1    1    1  |      |
| Eg |  2   -1   -1    2   -1   -1  |      |
| Au |  1    1    1   -1   -1   -1  |  z   |
| Eu |  2   -1   -1   -2    1    1  |  x,y |
+----+------------------------------+------+  
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
	my $X_C3   = sprintf "%0.f",  ($self->{C3}   - 2) * (1  + 2 * (-0.5));
	my $X_C3_2 = sprintf "%0.f",  ($self->{C3_2} - 2) * (1  + 2 * (-0.5));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i    = sprintf "%0.f",  $self->{i}    * (-1  + 2 * (-1));
	my $X_S6_5 = sprintf "%0.f",  $self->{S6_5} * (-1  + 2 * (0.5));
	my $X_S6   = sprintf "%0.f",  $self->{S6}   * (-1  + 2 * (0.5));
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C3, $X_C3_2, $X_i, $X_S6_5, $X_S6);
	
	# Irreducible representation
	my $s = 0;
	my $n_Ag = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ag[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eg[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Au = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Au[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Eu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Eu[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_Ag, $n_Eg, $n_Au, $n_Eu);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::S6 - Point group S6

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
