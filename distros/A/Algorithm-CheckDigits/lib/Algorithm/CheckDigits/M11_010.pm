package Algorithm::CheckDigits::M11_010;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.6';

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 5, 4, 3, 2, 7, 6, 5, 4, 3, 2 );

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
	if ($number =~ /^([0-9.]+)(\d)$/) {
		return $2 == $self->_compute_checkdigits($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9.]+)$/) {
		return "$1" . $self->_compute_checkdigits($1);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9.]+)(\d)$/) {
		return $1 if ($2 == $self->_compute_checkdigits($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9.]+)(\d)$/) {
		return $2 if ($2 == $self->_compute_checkdigits($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigits {
	my $self   = shift;
	my $number = shift;

	$number =~ s/\.//g;

	my @digits = split(//,$number);
	my $sum = 0;
	for (my $i = 0; $i <= $#digits; $i++) {
		$sum += $weight[$i] * $digits[$i];
	}
	$sum %= 11;
	return $sum == 0 ? 0 : ($sum == 1 ? '' : 11 - $sum);
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_010 - compute check digits AHV number (CH)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ahv = CheckDigits('ahv_ch');

  if ($ahv->is_valid('123.45.678.113')) {
	# do something
  }

  $cn = $ahv->complete('123.45.678.11');
  # $cn = '123.45.678.113'

  $cd = $ahv->checkdigit('123.45.678.113');
  # $cd = '3'

  $bn = $ahv->basenumber('123.45.678.113');
  # $bn = '123.45.678.11';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning left every digit is weighted with 5,4,3,2,7,6,5,4,3,2.

=item 2

The weighted digits are added.

=item 3

The sum from step 2 is taken modulo 11.

=item 4

The checkdigit is 11 minus the sum from step 3. Is the difference 10,
the number won't be taken. If the difference is 11, the checkdigit is
0.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of numbers and dots
and the rightmost digit is a valid check digit according to the
algorithm given above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and appended the
end of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits and dots.

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
