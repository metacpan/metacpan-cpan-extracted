package Chemistry::PointGroup::C2h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 4; # number of group elements
my @R  = qw( E C2 i sh ); # symmetry elements of C2h
my @hi = qw( 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( Ag Au Bg Bu ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C2h
my @Ag = qw( 1  1  1  1 );
my @Au = qw( 1  1 -1 -1 );
my @Bg = qw( 1 -1  1 -1 );
my @Bu = qw( 1 -1 -1  1 );

# my (%Ag, %Au, %Bg, %Bu);
# @Ag{@R} = @Ag; # Ag
# @Au{@R} = @Au; # Au
# @Bg{@R} = @Bg; # Bg
# @Bu{@R} = @Bu; # Bu


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+--------------------+------+
| C2h |  E   C2   i   sh   |      |
+-----+--------------------+------+
|  Ag |  1    1   1    1   |      |
|  Au |  1    1  -1   -1   |  z   |
|  Bg |  1   -1   1   -1   |      |
|  Bu |  1   -1  -1    1   | x,y  |
+-----+--------------------+------+  
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
	my $X_C2 = sprintf "%0.f",  ($self->{C2} - 2) * (1  + 2 * (-1));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i  = sprintf "%0.f",  $self->{i}  * (-1  + 2 * (-1));
	my $X_sh = sprintf "%0.f",  $self->{sh} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C2, $X_i, $X_sh);
	
	# Irreducible representation
	my $s = 0;
	my $n_Ag = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ag[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Au = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Au[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Bg = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Bg[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Bu = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Bu[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_Ag, $n_Au, $n_Bg, $n_Bu);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C2h - Point group C2h

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
