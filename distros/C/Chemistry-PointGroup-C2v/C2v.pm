package Chemistry::PointGroup::C2v;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 4; # number of group elements
my @R  = qw( E C2 sv svf ); # symmetry elements of C2v
my @hi = qw( 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( A1 A2 B1 B2 ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C2v
my @A1 = qw( 1  1  1  1 );
my @A2 = qw( 1  1 -1 -1 );
my @B1 = qw( 1 -1  1 -1 );
my @B2 = qw( 1 -1 -1  1 );

# my (%A1, %A2, %B1, %B2);
# @A1{@R} = @A1; # A1
# @A2{@R} = @A2; # A2
# @B1{@R} = @B1; # B1
# @B2{@R} = @B2; # B2


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+------------------------------+------+
| C2v |  E   C2  sv(xy)   sv'(yz)    |      |
+-----+------------------------------+------+
|  A1 |  1    1     1       1        |  z   |
|  A2 |  1    1    -1      -1        |      |
|  B1 |  1   -1     1      -1        |  x   |
|  B2 |  1   -1    -1       1        |  y   |
+-----+------------------------------+------+  
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
	my $X_sv  = sprintf "%0.f",  $self->{sv}  * (-1  + 2 * 1);
	my $X_svf = sprintf "%0.f",  $self->{svf} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C2, $X_sv, $X_svf);
	
	# Irreducible representation
	my $s = 0;
	my $n_A1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B1 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B1[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_B2 = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B2[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A1 ,  $n_A2 ,  $n_B1 ,  $n_B2 );
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C2v - Point group C2v

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
