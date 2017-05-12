package Chemistry::PointGroup::Cs;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 2; # number of group elements
my @R  = qw( E sh ); # symmetry elements of Cs
my @hi = qw( 1 1 ); # number of elements in the i-th class
my @I  = qw( Af As ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of Cs
my @Af = qw( 1  1 );
my @As = qw( 1 -1 );


# my (%Af, %As);
# @Af{@R} = @Af; # A'
# @As{@R} = @As; # A"



sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+----+-----------+------+
| Cs |  E   sh   |      |
+----+-----------+------+
| A' |  1    1   |  x,y |
| A" |  1   -1   |  z   |
+----+-----------+------+  
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
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_sh = sprintf "%0.f",  $self->{sh} * (-1  + 2 * 1);
	
	# in the same order of @hi
	my @rr = ($X_E, $X_sh);
	
	# Irreducible representation
	my $s = 0;
	my $n_Af = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Af[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_As = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $As[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_Af, $n_As);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::Cs - Point group Cs

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
