package Algorithm::CheckDigits::M11_012;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.2';

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 2,3,4,5,6,7,1,6,7,2,3 );

my %table_to = (
	0 => 0, 1 => 1, 2 => 2, 3 => 3, 4 => 4, 5 => 5,
	6 => 6, 7 => 7, 8 => 8, 9 => 9, A => 12, B => 14,
	C => 16, D => 18, E => 20, F => 22, G => 24, H => 26,
	I => 28, J => 6, K => 8, L => 10, M => 12, N => 14,
	O => 16, P => 18, Q => 20, R => 22, S => 4, T => 6,
	U => 8, V => 10, W => 12, X => 14, Y => 16, Z => 18,
);

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
	if ($number =~ /^([-0-9a-z]+)(\d)$/i) {
		return $2 == $self->_compute_checkdigits($1);
	}
	return undef;
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^([-0-9a-z]+)$/i
	   and (my $cd = $self->_compute_checkdigits($1)) ne '') {
		return $1 . $cd;
	}
	return undef;
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([-0-9a-z]+)(\d)$/i) {
		return $1 if ($2 == $self->_compute_checkdigits($1));
	}
	return undef;
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([-0-9a-z]+)(\d)$/i) {
		return $2 if ($2 == $self->_compute_checkdigits($1));
	}
	return undef;
} # checkdigit()

sub _compute_checkdigits {
	my $self   = shift;
	my $number = shift;

	$number =~ s/-//g;

	my @digits = split(//,$number);
	my $len = scalar(@digits) + 1;
	my $sum = 0;
	for (my $i = 0; $i <= $#digits; $i++) {
		$sum += $weight[$i] * $table_to{uc($digits[$i])};
	}
	$sum %= 11;
	return ($sum == 0) ? 1 : ($sum == 1) ? 0 : 11 - $sum;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_012 - compute check digits for Bundeswehrpersonenkennnummer (DE)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $bwpk = CheckDigits('bwpk_de');

  if ($bwpk->is_valid('151058-D-20711')) {
	# do something
  }

  $cn = $bwpk->complete('151058-D-2071');
  # $cn = '151058-D-20711'

  $cd = $bwpk->checkdigit('151058-D-20711');
  # $cd = '1'

  $bn = $bwpk->basenumber('151058-D-20711');
  # $bn = '151058-D-2071';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning left all digits are weighted 2,3,4,5,6,7,1,6,7,2,3. Letters
are replaced according to the following table:

  my %table_to = (
	A => 12, B => 14, C => 16, D => 18, E => 20,
	F => 22, G => 24, H => 26, I => 28, J => 6,
	K => 8, L => 10, M => 12, N => 14, O => 16,
	P => 18, Q => 20, R => 22, S => 4, T => 6,
	U => 8, V => 10, W => 12, X => 14, Y => 16,
	Z => 18,
  );

=item 2

The weighted digits are added.

=item 3

The sum from step 2 is taken modulo 11.

=item 4

The checksum is 11 minus the sum from step 3.

If the difference is 10, the checkdigit is 0.

If the difference is 11, the checkdigit is 1.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of numbers, letters and
hyphens and the rightmost digit is a valid check digit according to the
algorithm given above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and appended to the end of
C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits, hyphens and spaces.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=item checkdigit($number)

Returns the check digits of C<$number> if C<$number> has valid check
digits.

Return '' otherwise.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,

=cut
