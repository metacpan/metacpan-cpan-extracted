package Algorithm::CheckDigits::M23_002;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.6';

our @ISA = qw(Algorithm::CheckDigits);

my @keytable = (
	'W', 'A', 'B', 'C', 'D', 'E', 'F', 'G',
	'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O',
	'P', 'Q', 'R', 'S', 'T', 'U', 'V', 
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
	if ($number =~ /^(\d{7})([A-W])([A-IW])?$/i) {
		return $2 eq $self->_compute_checkdigit($1,$3);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{7}).?([A-IW])?$/i) {
		return $1 . $self->_compute_checkdigit($1,$2) . ($2 || '');
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{7})([A-W])([A-IW])?$/i) {
		if (uc($2) eq $self->_compute_checkdigit($1,$3)) {
			return $3 ? "$1.$3" : $1;
		}
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{7})([A-W])([A-IW])?$/i) {
		return $2 if (uc($2) eq $self->_compute_checkdigit($1,$3));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my ($self, $number,$optional) = @_;
	my $sum    = 0;
	my @digits = split(//,$number);

	for (my $i = 0; $i < 7; $i++) {
		$sum += $digits[$i] * (8-$i);
	}
	if ($optional and $optional =~ /[A-I]/i) {
		$sum += 9 * (ord($optional) - ord('A') + 1);
	}
	return $keytable[$sum % 23];

} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M23_002 - compute check digits for Tax Identification Number (IE)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $dni = CheckDigits('tin_ie');

  if ($dni->is_valid('8473625E')) {
	# do something
  }

  $cn = $dni->complete('1234567.W');
  # $cn = '1234567TW'

  $cd = $dni->checkdigit('1234577IA');
  # $cd = 'I'

  $bn = $dni->basenumber('1234577WW');
  # $bn = '1234577.W'
  
=head1 DESCRIPTION

=head2 ALGORITHM

The irish TIN (Tax Identification Number) or VAT Regstration Number
consists of 7 digits, a letter in the range from 'A' - 'W' as checksum,
and an optionally letter in the range from 'A' - 'I' or the letter 'W'.

=over 4

=item 1

In reverse order, each digit is multiplied by a weight started at 2.
(i.e. the number left from the check digit is multiplied with 2,
the next with 3 and so on).

=item 2

If there is an optional letter following the checksum letter (position 9),
this letter is mapped to a numeric value based on the following mapping:
"A" = 1, "B" = 2, ... "H" = 8, "I" = 9. "W" or absence of this letter
means a value of 0. This numeric value is multiplied with 9.

=item 3

All products from step 1 and 2 are added.

=item 4

The check digit is the sum from step 3 modulo 23. This number is
expressed as the corresponding letter from the alphabet where A-V
correspond to 1-22 and W stands for check digit 0.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> complies with the rules given above
and there is a valid check digit at position eight.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and inserted at position eight
of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits and an optional letter at position nine.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit. As a placeholder for the checksum a point ('.') is inserted
at position eight when the checksum contains the optional letter
at position nine.

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

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<https://ec.europa.eu/taxation_customs/tin/>

=cut
