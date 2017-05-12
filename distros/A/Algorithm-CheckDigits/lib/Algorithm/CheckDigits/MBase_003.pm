package Algorithm::CheckDigits::MBase_003;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = qv('v1.3.2');

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 6, 3, 7, 9, 10, 5, 8, 4, 2, 1 );

my %table_to = (
	'0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4,
	'5' => 5, '6' => 6, '7' => 7, '8' => 8, '9' => 9,
	'A' => 10, 'B' => 11, 'C' => 12, 'D' => 13, 'E' => 14,
	'F' => 15, 'G' => 16, 'H' => 17, 'I' => 18, 'J' => 19,
	'K' => 20, 'L' => 21, 'M' => 22, 'N' => 23, 'O' => 24,
	'P' => 25, 'Q' => 26, 'R' => 27, 'S' => 28, 'T' => 29,
	'U' => 30, 'V' => 31, 'W' => 32, 'X' => 33, 'Y' => 34,
	'Z' => 35,
);

my @table_from = (
	'0', '1', '2', '3', '4',
	'5', '6', '7', '8', '9',
	'A', 'B', 'C', 'D', 'E',
	'F', 'G', 'H', 'I', 'J',
	'K', 'L', 'M', 'N', 'O',
	'P', 'Q', 'R', 'S', 'T',
	'U', 'V', 'W', 'X', 'Y',
	'Z', '#',
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
	if ($number =~ /^(.*)(.)$/) {
		return uc($2) eq $self->_compute_checkdigits($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)$/) {
		return "$1"
		     . $self->_compute_checkdigits($1)
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)(.)$/) {
		return "$1" if ($2 eq $self->_compute_checkdigits($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)(.)$/) {
		return $2 if ($2 eq $self->_compute_checkdigits($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigits {
	my $self    = shift;
	my $number  = shift;

	my $digit;

	my @digits  = split(//,$number);
	my $even    = 0;
	my $sum1    = 0;
	my $sum2    = 0;

	for (my $i = $#digits; $i>= 0; $i--) {
		if (uc($digits[$i]) =~ /[0-9A-Z]/) {
			$digit = $table_to{uc($digits[$i])};
		} else {
			$digit = 36;
		}
		$sum1 += 3 * $digit unless ($even);
		$sum2 += $digit     if     ($even);
		$even = not $even;
	}
	my $sum = 37 - (($sum1 + $sum2) % 37);

	return $table_from[$sum];

} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::MBase_003 - compute check digits for SICI (Serial Item
and Contribution Identifier)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $sici = CheckDigits('sici');

  if ($sici->is_valid('0784-8679(20040308)6:<138>2.0.TX;2-H')) {
	# do something
  }

  $cn = $sici->complete('0784-8679(20040308)6:<138>2.0.TX;2-');
  # $cn = '0784-8679(20040308)6:<138>2.0.TX;2-H'

  $cd = $sici->checkdigit('0784-8679(20040308)6:<138>2.0.TX;2-H');
  # $cd = 'H'

  $bn = $sici->basenumber('0784-8679(20040308)6:<138>2.0.TX;2-H');
  # $bn = '0784-8679(20040308)6:<138>2.0.TX;2-';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item S<0>

In the string describing the number all letters (A-Z) are replaced
with numbers 10-35 accordingly. All other non-numbers are replaced by
36.

=item S<1>

Beginning right the numbers at all odd positions are added.

=item S<2>

The sum from step 1 is multiplied by 3.

=item S<3>

Beginning right the numbers at all even positions are added.

=item S<4>

The sums from step 2 and 3 are added.

=item S<5>

The sum from step 4 is taken modulo 37.

=item S<6>

The checksum is 37 minus the sum from step 5 where numbers from 10 to
35 are represented by 'A' to 'Z' accordingly and 36 is represented by
'#'.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if the last letter is a valid check letter according
to the algorithm given above.

Returns false otherwise,

=item complete($number)

The check letter for C<$number> is computed and appended the
end of C<$number>.

Returns the complete number with check letter or ''.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=item checkdigit($number)

Returns the check letter of C<$number> if C<$number> has valid check
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
F<http://sunsite.berkeley.edu/SICI/sici.pdf>

=cut
