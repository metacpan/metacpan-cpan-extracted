package Chemistry::PointGroup::C3h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 6; # number of group elements
my @R  = qw( E C3 C3_2 sh S3 S3_5 ); # symmetry elements of C3h
my @hi = qw( 1 1 1 1 1 1 ); # number of elements in the i-th class
my @I  = qw( Af As Ef Es ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C3h
my @Af = qw( 1  1  1  1  1  1 ); 
my @As = qw( 1  1  1 -1 -1 -1 );
my @Ef = qw( 2 -1 -1  2 -1 -1 );
my @Es = qw( 2 -1 -1 -2  1  1 );

# my (%Af, %As, %Ef, %Es);
# @Af{@R} = @Af; # A'
# @As{@R} = @As; # A"
# @Ef{@R} = @Ef; # E'
# @Es{@R} = @Es; # E"


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+-----+------------------------------+------+
| C3h |  E   C3  C3_2  sh  S3  S3_5  |      |
+-----+------------------------------+------+
|  A' |  1   1    1    1    1    1   |      |
|  A" |  1   1    1   -1   -1   -1   |  x,y |
|  E' |  2  -1   -1    2   -1   -1   |  z   |
|  E" |  2  -1   -1   -2    1    1   |      |
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
	my $X_E    = sprintf "%0.f",  ($self->{E}    - 2) * (1  + 2 * 1);
	my $X_C3   = sprintf "%0.f",  ($self->{C3}   - 2) * (1  + 2 * (-0.5));
	my $X_C3_2 = sprintf "%0.f",  ($self->{C3_2} - 2) * (1  + 2 * (-0.5));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_sh   = sprintf "%0.f",  $self->{sh}   * (-1  + 2 * 1);
	my $X_S3   = sprintf "%0.f",  $self->{S3}   * (-1  + 2 * (-0.5));
	my $X_S3_5 = sprintf "%0.f",  $self->{S3_5} * (-1  + 2 * (-0.5));
	
	# in the same order of @hi
	my @rr= ($X_E ,$X_C3 ,$X_C3_2, $X_sh, $X_S3, $X_S3_5); 
	
	# Irreducible representation
	my $s = 0;
	my $n_Af = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Af[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_As = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $As[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Ef = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ef[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Es = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Es[$_] , $s] } (0..$#hi))[-1]->[1];
							
							
							
	my @ri = ($n_Af ,  $n_As ,  $n_Ef ,  $n_Es );
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C3h - Point group C3h

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
