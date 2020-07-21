package Algorithm::CheckDigits::MBase_002;

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
	if ($number =~ /^(.+)(.)$/) {
		return uc($2) eq $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^[ 0-9]+$/) {
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

	if ($number =~ /^[ 0-9]+$/) {

		$number =~ s/ //g;
		my @digits = split(//,$number);
		my $sum    = 0;
		my $prod   = 10;

		for (my $i = 0; $i <= $#digits; $i++) {

			$sum  = (($prod + $digits[$i]) % 10) || 10;
			$prod = (2 * $sum) % 11;

		}
		return (11 - $prod) % 10;
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=encoding iso-8859-1

=head1 NAME

CheckDigits::MBase_002 - compute check digits for blood bags (DE), BZÜ
(DE), VAT Registration Number (DE)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $bb = CheckDigits('blutbeutel');

  if ($bb->is_valid('2761011234567893')) {
	# do something
  }

  $cn = $bb->complete('276101123456789');
  # $cn = '2761011234567893'

  $cd = $bb->checkdigit('2761011234567893');
  # $cd = '3'

  $bn = $bb->basenumber('2761011234567893');
  # $bn = '276101123456789';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Start with values P = 10, S = 0.

=item 2

Beginning left you do the following for all digits

=over 4

=item 1

S = (P + digit) modulo 10

=item 2

If S is 0 then S = 10.

=item 3

P = (2 * S) modulo 11

=back

=item 3

The check digit is (11 - P) modulo 10.

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
F<www.pruefziffernberechnung.de>,
F<www.eurocode.org>.

=cut
