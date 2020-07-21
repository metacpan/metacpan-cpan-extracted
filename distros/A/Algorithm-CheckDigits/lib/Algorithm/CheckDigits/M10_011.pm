package Algorithm::CheckDigits::M10_011;

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
	if ($number =~ /^(.*)([0-9])$/) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	my $cd = $self->_compute_checkdigit($number);
	if ($cd != -1) {
		return $number . $cd;
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)([0-9])$/) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)([0-9])$/) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;
	$number =~ s/\s//g;
	$number =~ s/^1z//i;
	$number =~ y/A-Za-z/2-90-90-72-90-90-7/;
	if ($number =~ /^([0-9]*)$/) {
		my @digits = split(//,$number);
		my $even = 0;
		my $sum  = 0;
		foreach my $digit (@digits) {
			$sum += $digit;
			$sum += $digit if ($even);
			$even = not $even;
		}
		return (10 - $sum % 10) % 10;
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M10_011 - compute check digits UPS (US)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ups = CheckDigits('ups');

  if ($ups->is_valid('1Z 591580 68 55587736')) {
	# do something
  }

  $cn = $ups->complete('1Z 591580 68 5558773');
  # $cn = '1Z 591580 68 55587736'

  $cd = $ups->checkdigit('1Z 591580 68 55587736');
  # $cd = '6'

  $bn = $ups->basenumber('1Z 591580 68 55587736');
  # $bn = '1Z 591580 68 5558773'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning left all numbers are weighted alternatively 1 and 2.

=item 2

The sum of all products is computed.

=item 3

The sum of step 3 ist taken modulo 10.

=item 4

The check digit is the difference between 10 and the number from step 3.

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
