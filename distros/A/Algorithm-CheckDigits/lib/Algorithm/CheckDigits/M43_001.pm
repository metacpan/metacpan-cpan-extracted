package Algorithm::CheckDigits::M43_001;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.2';

our @ISA = qw(Algorithm::CheckDigits);

my %keytable = (
	'0' =>  0, '1' =>  1, '2' =>  2, '3' =>  3,
	'4' =>  4, '5' =>  5, '6' =>  6, '7' =>  7,
	'8' =>  8, '9' =>  9, 'A' => 10, 'B' => 11,
	'C' => 12, 'D' => 13, 'E' => 14, 'F' => 15,
	'G' => 16, 'H' => 17, 'I' => 18, 'J' => 19,
	'K' => 20, 'L' => 21, 'M' => 22, 'N' => 23,
	'O' => 24, 'P' => 25, 'Q' => 26, 'R' => 27,
	'S' => 28, 'T' => 29, 'U' => 30, 'V' => 31,
	'W' => 32, 'X' => 33, 'Y' => 34, 'Z' => 35,
	'-' => 36, '.' => 37, ' ' => 38, '$' => 39,
	'/' => 40, '+' => 41, '%' => 42,
);

my %keymap = reverse %keytable;

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
	if ($number =~ /^(.*)(.)$/i) {
		return $2 eq $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)$/i) {
		return $number . $self->_compute_checkdigit($1);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)(.)$/i) {
		return $1 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(.*)(.)$/i) {
		return $2 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;
	my $sum    = 0;

	my @digits = split(//,$number);

	for (my $i = 0; $i < length($number); $i++) {
		$sum += $keytable{$digits[$i]};
	}
	$sum %= 43;
	return $keymap{$sum};
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M43_001 - compute check digits for Code-39

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $c39 = CheckDigits('code_39');

  if ($c39->is_valid('AB-123K')) {
	# do something
  }

  $cn = $c39->complete('AB-123');
  # $cn = 'AB-123K'

  $cd = $c39->checkdigit('AB-123K');
  # $cd = 'K'

  $bn = $c39->basenumber('AB-123K');
  # $bn = 'AB-123'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

After replacing all non numeric letters with their respective values,
the sum of all numbers is computers

=item 2

The checkdigit is the sum from step 1 taken modulo 43.

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
