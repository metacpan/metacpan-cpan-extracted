package Algorithm::CheckDigits::MXX_004;

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
	if ($number =~ /^(?:AT)?U?(\d{7})(\d)$/i) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(?:AT)?U?(\d{7})$/i) {
		return  $number .  $self->_compute_checkdigit($1);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(AT)?(U)?(\d{7})(\d)$/i) {
		my $cc = $1 || '';
		my $u  = $2 || '';
		return $cc.$u.$3 if ($4 == $self->_compute_checkdigit($3));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(?:AT)?U?(\d{7})(\d)$/i) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;
	$number =~ s/\s//g;
	if ($number =~ /^\d{7}$/) {
		my @digits = split(//,$number);
		my $even = 1;
		my $sum  = 0;
		for (my $i = $#digits;$i >= 0;$i--) {
			if ($even) {
				$sum += $digits[$i];
			} else {
				my $tmp = 2 * $digits[$i];
				$sum += $tmp / 10 + $tmp % 10;
			}
			$even = not $even;
		}
		return (96 - $sum) % 10;
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::MXX_004 - compute check digits for VAT RN (AT)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $vat = CheckDigits('ustid_at');

  if ($vat->is_valid('U13585627')) {
	# do something
  }

  $cn = $vat->complete('U1358562');
  # $cn = 'U13585627'

  $cd = $vat->checkdigit('U13585627');
  # $cd = '7'

  $bn = $vat->basenumber('U13585627');
  # $bn = 'U1358562'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning right all numbers before the check digit are weighted
alternatively 1 and 2.

=item 2

The total of the digits of all products is computed and then
subtracted from 96.

=item 3

The check digit is the sum of step 3 taken modulo 10.

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
