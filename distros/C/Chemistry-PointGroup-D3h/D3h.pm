package Chemistry::PointGroup::D3h;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 12; # number of group elements
my @R  = qw( E C3 C2 sh S3 sv); # symmetry elements of D3h
my @hi = qw( 1 2 3 1 2 3 ); # number of elements in the i-th class
my @I  = qw( A1f A2f Ef A1s A2s Es ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of D3h
my @A1f = qw( 1  1  1  1  1  1 );
my @A2f = qw( 1  1 -1  1  1 -1 );
my @Ef  = qw( 2 -1  0  2 -1  0 );
my @A1s = qw( 1  1  1 -1 -1 -1 );
my @A2s = qw( 1  1 -1 -1 -1  1 );
my @Es  = qw( 2 -1  0 -2  1  0 );

# my (%A1f, %A2f, %Ef, %A1s, %A2s, %Es);
# @A1f{@R} = @A1f; # A'1
# @A2f{@R} = @A2f; # A'2
# @Ef{@R}  = @Ef;  # E'
# @A1s{@R} = @A1s; # A"1
# @A2s{@R} = @A2s; # A"2
# @Es{@R}  = @Es;  # E"


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub normal_modes {
	my $self = shift;
	return (3 * $self->{E} - 6);
}

sub character_tables {
return <<'TABLE';
+-----+-------------------------------------+------+
| D3h |   E    2C3   3C2   sh   2S3   3sv   |      |
+-----+-------------------------------------+------+
| A1f |   1     1     1     1     1     1   |      |
| A2f |   1     1    -1     1     1    -1   |      |
| Ef  |   2    -1     0     2    -1     0   |  x,y |
| A1s |   1     1     1    -1    -1    -1   |      |
| A2s |   1     1    -1    -1    -1     1   |  z   |
| Es  |   2    -1     0    -2     1     0   |      |
+-----+-------------------------------------+------+  
TABLE
}

sub symmetry_elements {
	return @R;
}

sub irr {
	my $self = shift;
	
	# proper operations   ( Ur - 2 ) (1 + 2 cos(r))
	my $X_E  = sprintf "%0.f", ($self->{E}  - 2) * (1 + 2 * 1);
	my $X_C3 = 0; #sprintf "%0.f", ($self->{C3} - 2) * (1 + 2 * (-0.5));
	my $X_C2 = sprintf "%0.f", ($self->{C2} - 2) * (1 + 2 * (-1));
	
	# improper operations  Ur (-1 + 2 cos(r))
	my $X_sh = sprintf "%0.f", $self->{sh} * (-1 + 2 * 1 );
	my $X_S3 = sprintf "%0.f", $self->{S3} * (-1 + 2 * (-0.5) );
	my $X_sv = sprintf "%0.f", $self->{sv} * (-1 + 2 * 1 );
	
	# in the same order of @hi
	my @rr = ($X_E, $X_C3, $X_C2, $X_sh, $X_S3, $X_sv);
	
	# irreducible representations
	my $s = 0;
	my $n_A1f = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1f[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A2f = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2f[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Ef  = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Ef[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A1s = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A1s[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_A2s = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A2s[$_] , $s] } (0..$#hi))[-1]->[1];

	$s = 0;
	my $n_Es  = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $Es[$_] , $s] } (0..$#hi))[-1]->[1];

	
	my @ri = ($n_A1f, $n_A2f, $n_Ef, $n_A1s, $n_A2s, $n_Es);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;

}
1;

__END__

=head1 NAME

Chemistry::PointGroup::D3h - Point group D3h

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
