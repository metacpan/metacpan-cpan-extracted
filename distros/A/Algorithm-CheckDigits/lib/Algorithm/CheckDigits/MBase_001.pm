package Algorithm::CheckDigits::MBase_001;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.2';

our @ISA = qw(Algorithm::CheckDigits);

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
	if ($number =~ /^(\d+)(\d)$/) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^\d+$/) {
		return  $number . $self->_compute_checkdigit($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d+)(\d)$/) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d+)(\d)$/) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	if ($number =~ /^\d+$/) {

		my @digits = split(//,$number);
		my $sum    = 0;
		my $even   = 0;

		for (my $i = 0; $i <= $#digits; $i++) {

			if ($even) {
				$sum += $digits[$i];
			} else {
				$sum += 3 * $digits[$i];
			}
			$even = not $even;
		}
		return (10 - ($sum % 10)) % 10;
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::MBase_001 - compute check digits for UPC (US)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $rv = CheckDigits('upc');

  if ($rv->is_valid('012345678905')) {
	# do something
  }

  $cn = $rv->complete('01234567890');
  # $cn = '012345678905'

  $cd = $rv->checkdigit('012345678905');
  # $cd = '5'

  $bn = $rv->basenumber('012345678905');
  # $bn = '01234567890'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Add all digits in odd-numbered positions.

=item 2

Multiply the sum from step 1 with 3.

=item 3

Add all digits in even-numbered positions.

=item 4

Add the product from step 2 and the sum from step 3.

=item 5

If the sum from step 4 is 0 modulo 10, the check digit is 0. Else the
check digit is 10 minus the sum from step 4 taken modulo 10.

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

=head1 THANKS

Aaron W. West pointed me to a fault in the computing of the check
digit.

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,
F<www.export911.com/e911/coding/upcChar.htm>,
F<www.adams1.com/pub/russadam/upccode.html>,
F<http://www.upcdatabase.com>.

=cut
