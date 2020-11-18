package Algorithm::CheckDigits::M07_001;

use 5.006;
use strict;
use warnings;

use version; our $VERSION = 'v1.3.5';

our @ISA = qw(Algorithm::CheckDigits);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	return bless({}, $class);
} # new()

sub is_valid {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]*)([0-9])$/) {
		return ($2 == _compute_checkdigit($1));
	}
	return 0;
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]*)$/) {
		return $number . _compute_checkdigit($1);
	}
	return undef;
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]*)([0-9])$/) {
		return $1 if ($2 == _compute_checkdigit($1));
	}
	return undef;
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9]*)([0-9])$/) {
		return $2 if ($2 == _compute_checkdigit($1));
	}
	return undef;
} # checkdigit()

sub _compute_checkdigit {
	my $number = shift;
	my @digits = split(//,$number);
	my $even   = 0;
	my $sum    = 0;
	foreach my $digit (@digits) {
		$sum += $digit;
		$sum += $digit if ($even);
		$even = not $even;
	}
	return $sum % 7;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M07_001 - compute check digits modulo 7 method 1

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $m001 = CheckDigits('m001');

  if ($m001->is_valid('1234567892')) {
	# do something
  }

  $cn = $m001->complete('123456789');    # $cn = '1234567892'

  $cd = $m001->checkdigit('1234567892'); # $cd = '2'

  $bn = $m001->basenumber('1234567892'); # $bn = '123456789'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1.

All digits are added.

=item 2.

All digits at even positions are added.

=item 3.

The sum of step 1 and 2 is taken modulo 7.

=item 4.

This is the check digit.

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

Returns the complete number with check digit or undef if C<$number>
does not consist solely of digits.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return undef otherwise.

=item checkdigit($number)

Returns the check digit belonging to C<$number> or undef if C<$number> does
not consist solely of digits.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 SEE ALSO

L<perl>, F<www.pruefziffernberechnung.de>.

=cut
