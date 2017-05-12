package Algorithm::CheckDigits::M23_002;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.2';

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
	if ($number =~ /^(\d{7})([A-W])$/i) {
		return $2 eq $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{7})$/i) {
		return $number . $self->_compute_checkdigit($1);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{7})([A-W])$/i) {
		return $1 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{7})([A-W])$/i) {
		return $2 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;
	my $sum    = 0;

	my @digits = split(//,$number);

	for (my $i = 0; $i < 7; $i++) {
		$sum += $digits[$i] * (8-$i);
	}
	return $keytable[$sum % 23];

} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M23_002 - compute check digits for VAT Registration Number (IE)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $dni = CheckDigits('ustid_ie');

  if ($dni->is_valid('8473625E')) {
	# do something
  }

  $cn = $dni->complete('8473625');
  # $cn = '8473625E'

  $cd = $dni->checkdigit('8473625E');
  # $cd = 'E'

  $bn = $dni->basenumber('8473625E');
  # $bn = '8473625'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning right all digits are weighted with their position in the
number (i.e. the number left from the check digit is multiplied with
2, the next with 3 and so on).

=item 2

All products are added.

=item 3

The check digit is the sum from step 2 modulo 23. This number is
expressed as the corresponding letter from the alphabet where A-V
correspond to 1-22 and W stands for check digit 0.

=back

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

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>.

=cut
