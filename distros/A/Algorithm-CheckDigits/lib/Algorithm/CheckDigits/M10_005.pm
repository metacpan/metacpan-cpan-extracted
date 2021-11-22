package Algorithm::CheckDigits::M10_005;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.6';

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
	if ($number =~ /^([0-9 .]{11,})([0-9])$/) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^[0-9 .]{11,}$/) {
		return  $number . $self->_compute_checkdigit($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9 .]{11,})([0-9])$/) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([0-9 .]{11,})([0-9])$/) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;
	$number =~ s/[.\s]//g;
	if ($number =~ /^([0-9]{11})$/) {
		my @digits = split(//,$number);
		my $even = 0;
		my $sum  = 0;
		for (my $i = 0; $i <= $#digits; $i++) {
			if ($even) {
				$sum += 9 * $digits[$i];
			} else {
				$sum += 4 * $digits[$i];
			}
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

CheckDigits::M10_005 - compute check digits for Deutsche Post
Identcode/Leitcode (DE)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ic = CheckDigits('identcode_dp');

  if ($ic->is_valid('21.802 580.906 6')) {
	# do something
  }

  $cn = $ic->complete('21.802 580.906');
  # $cn = '21.802 580.9066'

  $cd = $ic->checkdigit('21.802 580.906 6');
  # $cd = '6'

  $bn = $ic->basenumber('21.802 580.906 6');
  # $bn = '21.802 580.906'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning left all numbers are weighted alternatively 4 and 9.

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
