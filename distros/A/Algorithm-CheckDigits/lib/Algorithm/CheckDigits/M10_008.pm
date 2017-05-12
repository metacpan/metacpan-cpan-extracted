package Algorithm::CheckDigits::M10_008;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = qv('v1.3.2');

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 1,3,1,7,3,9,1 );

my $value = 0;
my %ctable = map { $_, $value++ } ( '0'..'9', 'A'..'Z' );

my $re_alpha = qr/[B-DF-HJ-NP-TV-Z]/;
my $re_alnum = qr/[0-9B-DF-HJ-NP-TV-Z]/;
my $re_sedol = qr/(\d{6}|$re_alpha$re_alnum{5})(\d)?/;

sub new {
	my $proto = shift;
	my $type  = shift;
	my $class = ref($proto) || $proto;
	my $self  = bless({}, $class);
	$self->{type} = lc($type);
	return $self;
} # new()

sub is_valid {
	my $self = shift;
	my $number = uc shift;

	if ($number =~ /^$re_sedol$/o) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my $self = shift;
	my $number = uc shift;

	if ($number =~ /^$re_sedol$/o) {
		return  $number . $self->_compute_checkdigit($number);
	}
	else {
		return '';
	}
} # complete()

sub basenumber {
	my $self = shift;
	my $number = uc shift;

	if ($number =~ /^$re_sedol$/o) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my $self = shift;
	my $number = uc shift;

	if ($number =~ /^$re_sedol$/o) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;


	my @digits = map { $ctable{$_} } split(//,$number);
	my $sum    = 0;

	for (my $i = 0; $i <= $#digits; $i++) {

		$sum += $weight[$i] * $digits[$i];

	}
	return (10 - ($sum % 10)) % 10;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M10_008 - compute check digits for Sedol (GB)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $sedol = CheckDigits('sedol');

  if ($sedol->is_valid('0123457')) {
	# do something
  }

  $cn = $sedol->complete('012345');
  # $cn = '0123457'

  $cd = $sedol->checkdigit('0123457');
  # $cd = '7'

  $bn = $sedol->basenumber('0123457');
  # $bn = '012345'
  
=head1 DESCRIPTION

Prior to March 2004 SEDOL codes solely consisted of numbers. Since March
2004 SEDOL codes are a 7 character alphanumeric code.

The structure of the alphanumeric SEDOL codes is one alpha character
followed by 5 alphanumeric characters followed by the numerical check
digit.

=over 4

=item Alpha characters are B-Z excluding vowels.

=item Alphanumerical characters are 0-9, B-Z excluding vowels.

=item Numerical Characters are 0-9.

=back

No SEDOL code will be issued without the first alpha character. Active
numerical SEDOL codes issued prior to March 2004 remain valid.

=head2 ALGORITHM

=over 4

=item S<0>

All characters are assigned a numerical value from 0 to 35 where the
characters '0' to '9' get 0 to 9, 'B' to 'Z' get 11 to 35 with the
position of the vowels kept empty (for instance 'D' gets 13, 'F' gets
15). 

=item S<1>

Beginning left all numbers are weighted with 1,3,1,7,3,9 and 1
(checkdigit)

=item S<2>

The sum of all products is computed.

=item S<3>

The check digit is the difference of the sum from step 3 to the next
multiple of 10.

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

This function always returns the SEDOL code in upper case.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

This function always returns the SEDOL base number in upper case.

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
F<www.londonstockexchange.com> Masterfile technical specifications V7.0.

=cut
