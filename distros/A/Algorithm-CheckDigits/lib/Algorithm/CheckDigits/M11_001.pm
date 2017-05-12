package Algorithm::CheckDigits::M11_001;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.2';

our @ISA = qw(Algorithm::CheckDigits);

my $cd = {
	'isbn'		=> [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'X', 0 ],
	'ustid_pt'	=> [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,  0,  0 ],
	'hkid'		=> [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'A', 0 ],
	'wagonnr_br'	=> [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,  0,  1 ],
	'nhs_gb'	=> [ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1,  0 ],
	'vat_sl'	=> [ 1, 0, 2, 3, 4, 5, 6, 7, 8, 9,  0, -1 ], # ?
};

$cd->{'issn'} = $cd->{'isbn'};
$cd->{'vatrn_pt'} = $cd->{'ustid_pt'};

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
	if ($number =~ /^(.+)(.)$/) {
		return uc($2) eq $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^[-0-9A-Za-z]+$/) {
		return  $number . $self->_compute_checkdigit($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(.+)(.)$/) {
		return $1 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(.+)(.)$/) {
		return $2 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	if ($number =~ /^[-0-9A-Za-z]+$/) {

		$number =~ s/-//g;
		my @digits = split(//,$number);
		my $sum    = 0;
		my $weight = 2;

		for (my $i = $#digits; $i >= 0; $i--) {

			$digits[$i] = 1 + ord(uc($digits[$i])) - ord('A')
				if ($digits[$i] =~ /[A-Z]/i);
			$sum += $weight * $digits[$i];
			++$weight;

		}
		$sum %= 11;
		return $cd->{$self->{type}}[11-$sum] if ($cd->{$self->{type}});
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_001 - compute check digits for ISBN, ISSN, VAT RN
(PT), HKID (HK), Wagon number (BR), NHS (GB), VAT (SL)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $isbn = CheckDigits('isbn');

  if ($isbn->is_valid('3-88229-192-3')) {
	# do something
  }

  $cn = $isbn->complete('3-88229-192-');
  # $cn = '3-88229-192-3'

  $cd = $isbn->checkdigit('3-88229-192-3');
  # $cd = '3'

  $bn = $isbn->basenumber('3-88229-192-3');
  # $bn = '3-88229-192-'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

The sequence of digits is processed right to left.
Every digit is multiplied with their position in the sequence (i.e.
the digit left to the check digit has the weight 2 then 3 etc.).

With a Hongkong ID (hkid) the leftmost char is replaced with its
position in the alphabet and then multiplied with 8 (its weight).

=item 2

The sum of all products is computed.

=item 3

The sum of step 2 is taken modulo 11.

=item 4

The checkdigit is the difference of the sum from step 3 to eleven
under the following conditions:

=over 8

=item isbn,issn

If the difference is 10, the check digit is 'X'.

If the difference is 11, the check digit is 0.

=item ustid_pt

If the difference is greater then 9, the check digit is '0'.

=item hkid

If the difference is 10, the check digit is 'A'.

If the difference is 11, the check digit is 0.

=item wagonnr_br

If the difference is 10, the check digit is 0.

If the difference is 11, the check digit is 1.

=item nhs_gb

If the difference is 10, the number would not be taken.

If the difference is 11, the check digit is 0.

=item vat_sl

This is a little bit unclear, don't trust on the method for this type.

=back

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
