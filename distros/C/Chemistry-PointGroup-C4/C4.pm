package Chemistry::PointGroup::C4;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 4; # number of group elements
my @R  = qw( E C4 C2  C4_3 ); # symmetry elements of C4
my @hi = qw( 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( A B E ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C4
my @A = qw( 1  1  1  1 );
my @B = qw( 1 -1  1 -1 );
my @E = qw( 2  0 -2  0 );

# my (%A, %B, %E);
# @A{@R} = @A; # A
# @B{@R} = @B; # B
# @E{@R} = @E; # E


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+----+---------------------+------+
| C4 |  E   C4   C2   C4_3 |      |
+----+---------------------+------+
|  A |  1    1    1    1   |  z   |
|  B |  1   -1    1   -1   |      |
|  E |  2    0   -2    0   |  x,y |
+----+---------------------+------+  
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
	my $X_C4   = sprintf "%0.f",  ($self->{C4}   - 2); # * (1  + 2 * (0));
	my $X_C2   = sprintf "%0.f",  ($self->{C2}   - 2) * (1  + 2 * (-1));
	my $X_C4_3 = sprintf "%0.f",  ($self->{C4_3} - 2); # * (1  + 2 * (0));
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C4, $X_C2, $X_C4_2);
	
	# Irreducible representation
	my $s = 0;
	my $n_A = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_E = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A, $n_B, $n_E);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C4 - Point group C4

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
