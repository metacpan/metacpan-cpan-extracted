package Algorithm::CheckDigits::M11_008;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.3';

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 2, 7, 6, 5, 4, 3, 2, 1 );

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
	if ($number =~ /^(\d{8})$/) {
		return 0 == $self->_compute_checkdigits($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	return "$1" if(   $number =~ /^(\d{8})$/
	              and 0 == $self->_compute_checkdigits($1));
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	return "$1" if(   $number =~ /^(\d{8})$/
	              and 0 == $self->_compute_checkdigits($1));
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	return '' if(   $number =~ /^(\d{8})$/
	            and 0 == $self->_compute_checkdigits($1));
	return undef;
} # checkdigit()

sub _compute_checkdigits {
	my $self    = shift;

	my @digits = split(//,shift);
	my $sum = 0;
	for (my $i = 0; $i <= $#digits; $i++) {
		$sum += $weight[$i] * $digits[$i];
	}
	$sum %= 11;
	return $sum;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_008 - compute check digits for VAT Registration Number (DK)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ustid = CheckDigits('ustid_dk');

  if ($ustid->is_valid('13585628')) {
	# do something
  }

  $cn = $ustid->complete('1358562');
  # $cn = '13585628'

  $cd = $ustid->checkdigit('13585628');
  # $cd = '8'

  $bn = $ustid->basenumber('13585628');
  # $bn = '1358562';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning left every digit is weighted with 2, 7, 6, 5, 4, 3, 2, 1

=item 2

The weighted digits are added.

=item 3

The sum from step 2 is taken modulo 11.

=item 4

The number is valid if the sum from step 3 is zero (0).

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of numbers and the sum
computed according to the algorithm given above is 0.

Returns false otherwise,

=item complete($number)

Returns C<$number> if C<$number> is valid according to the algorithm
given above.

Return '' otherwise.

=item basenumber($number)

Returns C<$number> if C<$number> is valid according to the algorithm
given above.

Return '' otherwise.

=item checkdigit($number)

Returns '' if C<$number> is valid.

Return undef otherwise.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,

=cut
