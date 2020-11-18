package Algorithm::CheckDigits::M11_003;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.5';

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 4,2,1,6,3,7,9,10,5,8,4,2 );

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
	if ($number =~ /^(\d{11})(\d)$/) {
		return $2 == $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^\d{11}$/) {
		my $cd = $self->_compute_checkdigit($number);
		return  0 > $cd ? '' : $number . $cd;
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{11})(\d)$/) {
		return $1 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{11})(\d)$/) {
		return $2 if ($2 == $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	if ($number =~ /^\d{11}$/) {

		my @digits = split(//,$number);
		my $sum    = 0;
		my $cf     = 0;

		for (my $i = 0; $i <= $#digits; $i++) {

			$sum += $weight[$i] * $digits[$i];

		}
		$sum %= 11;
		for (my $i = 0; $i <= 9; $i++) {
			return $i
				if (10 == ($sum + $weight[11] * $i) % 11);
		}
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_003 - compute check digits for PKZ (GDR)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $pkz = CheckDigits('pkz');

  if ($pkz->is_valid('150765400354')) {
	# do something
  }

  $cn = $pkz->complete('15076540035');
  # $cn = '150765400354'

  $cd = $pkz->checkdigit('150765400354');
  # $cd = '4'

  $bn = $pkz->basenumber('150765400354');
  # $bn = '150765400354'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

The checkdigit is set to 0.

=item 2

From right to left the digits are weighted (multiplied) with
2,4,8,5,10,9,7,3,6,1,2,4.

=item 3

The products are added.

=item 4

The sum of step 3 is taken modulo 11.

=item 5

The value of step 4 is added to a multiple (0..9) of the weight of the
checkdigit (2).

=item 6

The sum of step 5 is taken modulo 11.

=item 7

The checkdigit is the multiple of the weight of the checkdigit where
the value of step 6 equals 10.

=item 8

If there can't be reached a value of 10 in step 6, the number cannot
be taken as a PKZ.

=back

To validate a PKZ apply steps 2 to 4 to the complete number.

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
