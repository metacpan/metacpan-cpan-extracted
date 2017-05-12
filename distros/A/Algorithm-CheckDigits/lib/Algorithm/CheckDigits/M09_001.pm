package Algorithm::CheckDigits::M09_001;

use 5.006;
use strict;
use warnings;

use version; our $VERSION = 'v1.3.2';

our @ISA = qw(Algorithm::CheckDigits);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	return bless({}, $class);
} # new()

sub is_valid {
	my ($self,$number) = @_;
	if ($number =~ /^([A-Za-z][0-9]{10})([0-9])$/) {
		return $2 == _compute_checkdigit($1);
	}
	return 0;
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^[A-Za-z][0-9]{10}$/) {
		return  $number . _compute_checkdigit($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([A-Za-z][0-9]{10})([0-9])$/) {
		return $1 if ($2 == _compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([A-Za-z][0-9]{10})([0-9])$/) {
		return $2 if ($2 == _compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $number = shift;
	if ($number =~ /^([A-Za-z])([0-9]{10})$/) {
		my @nums = ();
		my $sum  = 0;
		push(@nums,ord(uc($1)) - ord('A') +1);
		push(@nums,split(//,$2));
		foreach my $num (@nums) {
			$sum += $num;
		}
		return 8 - ($sum % 9);
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M09_001 - compute check digits for Euro notes

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $euro = CheckDigits('euronote');

  if ($euro->is_valid('X07738250357')) {
	# do something
  }

  $cn = $euro->complete('X0773825035');     # $cn = 'X07738250357'

  $cd = $euro->checkdigit('X07738250357'); # $cd = '7'

  $bn = $euro->basenumber('X07738250357'); # $bn = 'X0773825035'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Letters are replaced with their position in the alphabet ('A' = 1, ...).

=item 2

The total of the digits of all numbers is computed.

=item 3

This sum is taken modulo 9.

=item 4

The check digit is the difference between 8 and the number of step 3.

=back

To validate the last digit of the total of the digits of all numbers
inclusive check digit must be 8.

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
does not consist solely of digits.

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
