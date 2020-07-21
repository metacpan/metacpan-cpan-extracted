package Algorithm::CheckDigits::M11_013;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.3';

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
	if ($number =~ /^([0-9]+)(\d)$/) {
		return $2 == $self->_compute_checkdigits($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]+)$/
	   and (my $cd = $self->_compute_checkdigits($1)) ne '') {
		return $1 . $cd;
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]+)(\d)$/) {
		return $1 if ($2 == $self->_compute_checkdigits($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]+)(\d)$/) {
		return $2 if ($2 == $self->_compute_checkdigits($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigits {
	my $self   = shift;
	my $number = shift;

	my @digits = split(//,$number);
	my $len = scalar(@digits);
	my $sum = 0;
	for (my $i = $#digits; $i >= 0; $i--) {
		$sum += 2 ** ($len - $i) * $digits[$i];
	}
	$sum %= 11;
	return ($sum > 9) ? 0 : $sum;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_013 - compute check digits for VAT Registration Number (GR)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ustid = CheckDigits('ustid_gr');

  if ($ustid->is_valid('123456783')) {
	# do something
  }

  $cn = $ustid->complete('12345678');
  # $cn = '123456783'

  $cd = $ustid->checkdigit('123456783');
  # $cd = '3'

  $bn = $ustid->basenumber('123456783');
  # $bn = '12345678';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning right with the digit before the checkdigit all digits are
weighted with 2 ** position. I. e. the last digit is
multiplied with 2, the next with 4, then 8 and so on.

=item 2

The weighted digits are added.

=item 3

The sum from step 2 is taken modulo 11.

=item 4

If the sum from step 3 is greater than 9, the check sum is 0 else it
is the sum itself.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of numbers and the
rightmost digit is a valid check digit according to the algorithm given
above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and appended to the end of
C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits.

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
