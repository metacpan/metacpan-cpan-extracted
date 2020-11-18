package Algorithm::CheckDigits::MXX_003;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = qv('v1.3.5');

our @ISA = qw(Algorithm::CheckDigits);

my $perm = [
	[ 1, 5, 7, 6, 2, 8, 3, 0, 9, 4, ],
	[ 5, 8, 0, 3, 7, 9, 6, 1, 4, 2, ],
	[ 8, 9, 1, 6, 0, 4, 3, 5, 2, 7, ],
	[ 9, 4, 5, 3, 1, 2, 6, 8, 7, 0, ],
	[ 4, 2, 8, 6, 5, 7, 3, 9, 0, 1, ],
	[ 2, 7, 9, 3, 8, 0, 6, 4, 1, 5, ],
	[ 7, 0, 4, 6, 9, 1, 3, 2, 5, 8, ],
	[ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, ],
	[ 1, 5, 7, 6, 2, 8, 3, 0, 9, 4, ],
	[ 5, 8, 0, 3, 7, 9, 6, 1, 4, 2, ],
	[ 8, 9, 1, 6, 0, 4, 3, 5, 2, 7, ],
];

my $dieder = [
	[ 0, 1, 2, 3, 4,   5, 6, 7, 8, 9, ],
	[ 1, 2, 3, 4, 0,   6, 7, 8, 9, 5, ],
	[ 2, 3, 4, 0, 1,   7, 8, 9, 5, 6, ],
	[ 3, 4, 0, 1, 2,   8, 9, 5, 6, 7, ],
	[ 4, 0, 1, 2, 3,   9, 5, 6, 7, 8, ],

	[ 5, 9, 8, 7, 6,   0, 4, 3, 2, 1, ],
	[ 6, 5, 9, 8, 7,   1, 0, 4, 3, 2, ],
	[ 7, 6, 5, 6, 8,   2, 1, 0, 4, 3, ],
	[ 8, 7, 6, 5, 9,   3, 2, 1, 0, 4, ],
	[ 9, 8, 7, 6, 5,   4, 3, 2, 1, 0, ],
];

sub new {
	my $proto = shift;
	my $type  = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless({}, $class);
	$self->{type} = lc($type);
	return $self;
} # new()

sub is_valid {
	my ($self,$number) = @_;
	if ($number =~ /^([ADGKLNSUYZ]{2}\d{7}[ADGKLNSUYZ])(\d)$/i) {
		return 1 if ($2 == $self->_compute_checkdigit(uc($1)));
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^[ADGKLNSUYZ]{2}\d{7}[ADGKLNSUYZ]$/i) {
		return $number .  $self->_compute_checkdigit(uc($number));
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([ADGKLNSUYZ]{2}\d{7}[ADGKLNSUYZ])(\d)$/i) {
		return $1 if ($2 == $self->_compute_checkdigit(uc($1)));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([ADGKLNSUYZ]{2}\d{7}[ADGKLNSUYZ])(\d)$/i) {
		return $2 if ($2 == $self->_compute_checkdigit(uc($1)));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	$number =~ tr/ADGKLNSUYZ/0-9/;
	my @digits = split(//,$number);
	my $p0 = $perm->[0]->[$digits[0]];
	my $rd = $p0;

	for (my $i = 1; $i <= $#digits; $i++) {
		my $pi = $perm->[$i % 8]->[$digits[$i]];
		$rd = $dieder->[$rd]->[$pi];
	}
	for (my $j = 0; $j <= 9; $j++) {
		return $j unless($dieder->[$rd]->[$j]);
	}

	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=encoding iso-8859-1

=head1 NAME

CheckDigits::MXX_003 - compute check digits for DEM

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $dem = CheckDigits('dem');

  if ($dem->is_valid('GD0645027K1')) {
	# do something
  }

  $cn = $dem->complete('GD0645027K');
  # $cn = 'GD0645027K1'

  $cd = $dem->checkdigit('GD0645027K1');
  # $cd = '1'

  $bn = $dem->basenumber('GD0645027K1');
  # $bn = 'GD0645027K'
  
=head1 DESCRIPTION

=head2 ALGORITHM

The algorithm is a variation of the Verhoeff scheme.

=over 4

=item S<0>

All letters are changed to numbers.

=item S<1>

All digits are permutated according to a permutation table.

=item S<2>

The permutated digits are combined using a diëder table. The first
with the second, the result with the third, this result with the
fourth and so on.

=item S<3>

The result of the last combination in the diëder table is in such a
way combined that the result is 0 (zero). The number used for this
combination is the checksum.

=back

For details look at the source.

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of numbers and the last digit
is a valid check digit according to the algorithm given above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and concatenated to the end
of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits and spaces.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=item checkdigit($number)

Returns the checkdigit of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 THANKS

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,

=cut
