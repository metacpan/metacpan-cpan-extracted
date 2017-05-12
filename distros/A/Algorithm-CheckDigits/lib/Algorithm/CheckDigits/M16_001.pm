package Algorithm::CheckDigits::M16_001;

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
	if ($number =~ /^([0-9a-f]{15})([0-9a-f])$/i) {
		return $2 eq $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^[0-9a-f]{15}$/i) {
		return $number . $self->_compute_checkdigit($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9a-f]{15})([0-9a-f])$/i) {
		return $1 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9a-f]{15})([0-9a-f])$/i) {
		return $2 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	if ($number =~ /^[0-9a-f]{15}$/i) {
		my ($a,$b,$c);

		my @digits = split(//,$number);
		$a         = 16;

		for (my $i = 0; $i <= $#digits; $i++) {

			$b = ($a % 17) + hex($digits[$i]);
			$c = $b % 16;
			$c = 16 unless ($c);
			$a = 2 * $c;

		}
		return sprintf("%X",(17 - ($a % 17)) % 16);
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M16_001 - compute check digits for ISAN

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $isan = CheckDigits('isan');

  if ($isan->is_valid('123A567B8912E01A')) {
	# do something
  }

  $cn = $isan->complete('123A567B8912E01');
  # $cn = '123A567B8912E01A'

  $cd = $isan->checkdigit('123A567B8912E01A');
  # $cd = '4'

  $bn = $isan->basenumber('123A567B8912E01A');
  # $bn = '123A567B8912E01'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

C<a(1) = 16>

C<b(i) = a(i) % 17 +d(i)>, where C<d(i)> is the decimal value of the
hexdigit at position I<i>.

C<c(i) = b(i) % 16>

C<a(i) = c(i-1) * 2>, for I<i> greater than 1

=item 2

Beginning left for each I<i> = 1..16, C<a>, C<b>, C<c> are computed.

=item 3

The check digit is the value for C<d(16)> where C<c(16)> equals 1.

=item 4

The check digit is appended as hexadecimal value to the number.

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
