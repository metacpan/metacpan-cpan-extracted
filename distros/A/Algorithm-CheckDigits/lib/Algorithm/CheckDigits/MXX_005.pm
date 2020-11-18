package Algorithm::CheckDigits::MXX_005;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.5';

our @ISA = qw(Algorithm::CheckDigits);

my $ctable = [
	[ 0, 9, 4, 6, 8, 2, 7, 1, 3, 5,  0, ],
	[ 9, 4, 6, 8, 2, 7, 1, 3, 5, 0,  9, ],
	[ 4, 6, 8, 2, 7, 1, 3, 5, 0, 9,  8, ],
	[ 6, 8, 2, 7, 1, 3, 5, 0, 9, 4,  7, ],
	[ 8, 2, 7, 1, 3, 5, 0, 9, 4, 6,  6, ],
	[ 2, 7, 1, 3, 5, 0, 9, 4, 6, 8,  5, ],
	[ 7, 1, 3, 5, 0, 9, 4, 6, 8, 2,  4, ],
	[ 1, 3, 5, 0, 9, 4, 6, 8, 2, 7,  3, ],
	[ 3, 5, 0, 9, 4, 6, 8, 2, 7, 1,  2, ],
	[ 5, 0, 9, 4, 6, 8, 2, 7, 1, 3,  1, ],
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
	if ($number =~ /^(\d{8})(\d)$/i) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8})$/i) {
		return  $number .  $self->_compute_checkdigit($1);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8})(\d)$/i) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8})(\d)$/i) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;
	my $carry  = 0;
	if ($number =~ /^\d{8}$/) {
		my @digits = split(//,$number);
		for (my $i = 0;$i <= $#digits;$i++) {
			$carry = $ctable->[$carry]->[$digits[$i]];
		}
		return (10 - $carry) % 10;
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::MXX_005 - compute check digits for ESR9 (CH)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $esr = CheckDigits('esr9');

  if ($esr->is_valid('123456786')) {
	# do something
  }

  $cn = $esr->complete('12345678');
  # $cn = '123456786'

  $cd = $esr->checkdigit('123456786');
  # $cd = '6'

  $bn = $esr->basenumber('123456786');
  # $bn = '12345678'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Digits are processed left to right. For the first digit applies the
balance is 0.

=item 2

The new balance is taken from the balance table according to the
current balance (row) and the digit (column).

=item 3

The check digit is the difference from the last balance to 10 taken
modulo 10.

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
