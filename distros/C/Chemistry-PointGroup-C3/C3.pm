package Chemistry::PointGroup::C3;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 3; # number of group elements
my @R  = qw( E C3 C3_2); # symmetry elements of C3
my @hi = qw( 1 1 1 ); # number of elements in the i-th class
my @I  = qw( A E ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C3
my @A = qw( 1  1  1 );
my @E = qw( 2 -1 -1 );

# my (%A, %E);
# @A{@R} = @A; # A
# @E{@R} = @E; # E


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+----+-----------------+------+
| C3 |  E   C3   C3_2  |      |
+----+-----------------+------+
|  A |  1    1    1    |  z   |
|  E |  2   -1   -1    |  x,y |
+----+-----------------+------+  
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
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C3, $X_C3_2);
	
	# Irreducible representation
	my $s = 0;
	my $n_A = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_E = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $E[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A, $n_E);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C3 - Point group C3

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
