package Chemistry::PointGroup::D2h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 8; # number of group elements
my @R  = qw( E C2z C2y C2x i sxy sxz syz ); # symmetry elements of D2h
my @hi = qw( 1 1 1 1 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( Ag B1g B2g B3g Au B1u B2u B3u ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D2h
my @Ag  = qw( 1  1  1  1  1  1  1  1 );
my @B1g = qw( 1  1 -1 -1  1  1 -1 -1 );
my @B2g = qw( 1 -1  1 -1  1 -1  1 -1 );
my @B3g = qw( 1 -1 -1  1  1 -1 -1  1 );
my @Au  = qw( 1  1  1  1 -1 -1 -1 -1 );
my @B1u = qw( 1  1 -1 -1 -1 -1  1  1 );
my @B2u = qw( 1 -1  1 -1 -1  1 -1  1 );
my @B3u = qw( 1 -1 -1  1 -1  1  1 -1 );


# my (%Ag, %B1g, %B2g, %B3g, %Au,  %B1u, %B2u, %B3u);
# @Ag{@R}  = @Ag;
# @B1g{@R} = @B1g;
# @B2g{@R} = @B2g;
# @B3g{@R} = @B3g;
# @Au{@R}  = @Au;
# @B1u{@R} = @B1u;
# @B2u{@R} = @B2u;
# @B3u{@R} = @B3u;


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+--------------------------------------------------+-----+
| D2h |  E  C2(z)  C2(y)  C2(x)  i  s(xy)  s(xz)  s(yz)  |     |
+-----+--------------------------------------------------+-----+
| Ag  |  1   1      1      1     1    1      1      1    |     |
| B1g |  1   1     -1     -1     1    1     -1     -1    |     |
| B2g |  1  -1      1     -1     1   -1      1     -1    |     |
| B3g |  1  -1     -1      1     1   -1     -1      1    |     |
| Au  |  1   1      1      1    -1   -1     -1     -1    |     |
| B1u |  1   1     -1     -1    -1   -1      1      1    | z   |
| B2u |  1  -1      1     -1    -1    1     -1      1    | y   |
| B3u |  1  -1     -1      1    -1    1      1     -1    | x   |
+-----+--------------------------------------------------+-----+  
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
	# E C2z C2y C2x i sxy sxz syz
	# proper operations   ( Ur - 2 ) (1 + 2 cos(r))
	my $X_E   = sprintf "%0.f",  ($self->{E}   - 2) * (1  + 2 * 1);
	my $X_C2z = sprintf "%0.f",  ($self->{C2z} - 2) * (1  + 2 * (-1));
	my $X_C2y = sprintf "%0.f",  ($self->{C2y} - 2) * (1  + 2 * (-1));
	my $X_C2x = sprintf "%0.f",  ($self->{C2x} - 2) * (1  + 2 * (-1));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_i   = sprintf "%0.f",  $self->{i}   * (-1  + 2 * (-1));
	my $X_sxy = sprintf "%0.f",  $self->{sxy} * (-1  + 2 * 1);
	my $X_sxz = sprintf "%0.f",  $self->{sxz} * (-1  + 2 * 1);
	my $X_syz = sprintf "%0.f",  $self->{syz} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr= ($X_E, $X_C2z, $X_C2y, $X_C2x,
	         $X_i, $X_sxy, $X_sxz, $X_syz); # reducible representation
	
	# irreducible representation
	# Ag 
	my $s = 0;
	my $n_Ag = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ag[$_] , $s] } (0..$#hi))[-1]->[1];
	# B1g 
	$s = 0;
	my $n_B1g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B1g[$_] , $s] } (0..$#hi))[-1]->[1];
	# B2g 
	$s = 0;
	my $n_B2g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B2g[$_] , $s] } (0..$#hi))[-1]->[1];
	# B3g 
	$s = 0;
	my $n_B3g = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B3g[$_] , $s] } (0..$#hi))[-1]->[1];
	# Au 
	$s = 0;
	my $n_Au = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Au[$_] , $s] } (0..$#hi))[-1]->[1];
	# B1u 
	$s = 0;
	my $n_B1u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B1u[$_] , $s] } (0..$#hi))[-1]->[1];
	# B2u 
	$s = 0;
	my $n_B2u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B2u[$_] , $s] } (0..$#hi))[-1]->[1];
	# B3u 
	$s = 0;
	my $n_B3u = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $B3u[$_] , $s] } (0..$#hi))[-1]->[1];
	
	
	my @ri = ($n_Ag, $n_B1g, $n_B2g, $n_B3g,
	          $n_Au, $n_B1u, $n_B2u, $n_B3u);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D2h - Point group D2h

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
