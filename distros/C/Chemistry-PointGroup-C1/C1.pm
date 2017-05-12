package Chemistry::PointGroup::C1;

use 5.008001;
use strict;
use warnings;

our $VERSION = '0.01';

my $h  = 1; # number of group elements
my @R  = qw( E ); # symmetry elements of C1
my @hi = qw( 1 ); # number of elements in the i-th class
my @I  = qw( A ); # irreducible representations
my %R;
@R{@R}=@hi;

# characters of the irreducible representations of C1
my @A = qw( 1 );

# my (%A);
# @A{@R} = @A; # A


sub new {
	my $type = shift;
	$type = ref($type) || $type;
	my %Ur   = @_;
	return bless \%Ur, $type;
}

sub character_tables {
return <<'TABLE';
+----+-----+
| C1 |  E  |
+----+-----+
|  A |  1  |
+----+-----+
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

	# in the same order of @hi
	my @rr = ($X_E);
	
	# Irreducible representation
	my $s = 0;
	my $n_A = sprintf"%0.f", 
	(1/$h)*(map { [ $s += $hi[$_] * $rr[$_] * $A[$_] , $s] } (0..$#hi))[-1]->[1];

	my @ri = ($n_A);
	my %ri = ();
	@ri{@I} = @ri;
	return %ri;
}
1;

__END__

=head1 NAME

Chemistry::PointGroup::C1 - Point group C1

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
