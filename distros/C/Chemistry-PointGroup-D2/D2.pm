package Chemistry::PointGroup::D2;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 4; # number of group elements
my @R  = qw( E C2z C2y C2x); # symmetry elements of D2
my @hi = qw( 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( A B1 B2 B3 ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D2
my @A  = qw( 1  1  1  1 );
my @B1 = qw( 1  1 -1 -1 );
my @B2 = qw( 1 -1  1 -1 );
my @B3 = qw( 1 -1 -1  1 );

# my (%A, %B1, %B2, %B3);
# @A{@R}  = @A;  # A
# @B1{@R} = @B1; # B1
# @B2{@R} = @B2; # B2
# @B3{@R} = @B3; # B3


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+--------------------------+------+
|  D2 |  E   C2(z)  C2(y)  C2(x) |      |
+-----+--------------------------+------+
|  A  |  1    1      1      1    |      |
|  B1 |  1    1     -1     -1    |  z   |
|  B2 |  1   -1      1     -1    |  y   |
|  B3 |  1   -1     -1      1    |  x   |
+-----+--------------------------+------+  
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
	my $X_C2z = sprintf "%0.f",  ($self->{C2z} - 2) * (1  + 2 * (-1));
	my $X_C2y = sprintf "%0.f",  ($self->{C2y} - 2) * (1  + 2 * (-1));
	my $X_C2x = sprintf "%0.f",  ($self->{C2x} - 2) * (1  + 2 * (-1));
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C2z, $X_C2y, $X_C2x);
	
	# Irreducible representation
	my $s = 0;
	my $n_A = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B2[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B3 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B3[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A, $n_B1, $n_B2, $n_B3);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D2 - Point group D2

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
