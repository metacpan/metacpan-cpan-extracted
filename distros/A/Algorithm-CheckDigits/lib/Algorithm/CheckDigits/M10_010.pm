package Algorithm::CheckDigits::M10_010;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.5';

our @ISA = qw(Algorithm::CheckDigits);

my @items = ( 0,9,4,6,8,2,7,1,3,5 );

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
	if ($number =~ /^(\d\d-?\d{8})-?(\d)$/) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^\d\d-?\d{8}-?$/) {
		return  $number . $self->_compute_checkdigit($number);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d\d-?\d{8}-?)(\d)$/) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d\d-?\d{8})-?(\d)$/) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	if ($number =~ /^\d\d-?\d{8}-?$/) {

		$number =~ s/-//g;
		my @digits = split(//,$number);
		my $sum    = 0;
		my $cf     = 0;

		for (my $i = 0; $i <= $#digits; $i++) {

			$cf = $items[($digits[$i] + $cf) % 10];

		}
		return (10 - $cf) % 10;
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M10_010 - compute check digits for Postscheckkonti (CH)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $pck = CheckDigits('postcheckkonti');

  if ($pck->is_valid('85-12345678-7')) {
	# do something
  }

  $cn = $pck->complete('85-12345678');
  # $cn = '85-12345678-7'

  $cd = $pck->checkdigit('85-12345678-7');
  # $cd = '7'

  $bn = $pck->basenumber('85-12345678-7');
  # $bn = '85-12345678'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

The sequence of digits is processed left to right. For the first digit
we assume a carry forward of 0.

=item 2

For each digit d(i) the carry forward cf(i) is the digit at the
the position p in the sequence ( 0, 9, 4, 6, 8, 2, 7, 1, 3, 5 ), where
p is (d(i) + cf(i-1)) modulo 10.

=item 3

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
