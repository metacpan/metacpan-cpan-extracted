package Algorithm::CheckDigits::M10_006;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.5';

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 2,1,2,5,7,1,2,1,2,1,2,1 );

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
	if ($number =~ /^(\d{8}[A-Za-z]\d\d)(\d)$/) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^\d{8}[A-Za-z]\d\d$/) {
		return  $number . $self->_compute_checkdigit($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8}[A-Za-z]\d\d)(\d)$/) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8}[A-Za-z]\d\d)(\d)$/) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	if ($number =~ /^(\d{8})([A-Za-z])(\d\d)$/) {

		my $lv     = sprintf("%2.2d",ord(uc($2)) - ord('A') + 1);
		my @digits = split(//,"$1$lv$3");
		my $sum    = 0;

		for (my $i = 0; $i <= $#digits; $i++) {

			my $tmp = $weight[$i] * $digits[$i];

			$sum += $tmp / 10;
			$sum += $tmp % 10
		}
		return $sum % 10;
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M10_006 - compute check digits for Rentenversicherung (DE)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $rv = CheckDigits('rentenversicherung');

  if ($rv->is_valid('65180539W001')) {
	# do something
  }

  $cn = $rv->complete('65180539W00');
  # $cn = '65180539W001'

  $cd = $rv->checkdigit('65180539W001');
  # $cd = '1'

  $bn = $rv->basenumber('65180539W001');
  # $bn = '65180539W00'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

The letter is replaced with a two-figure number appropriate to the
position of the letter in the german alphabet.

=item 2

Beginning left all numbers are weighted with 2,1,2,5,7,1,2,1,2,1,2,1.

=item 3

The the total of the digits of all products is computed.

=item 4

The check digit is sum from step 3 taken modulo 10.

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
