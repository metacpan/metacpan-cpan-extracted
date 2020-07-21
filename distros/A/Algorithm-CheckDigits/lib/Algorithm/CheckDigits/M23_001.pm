package Algorithm::CheckDigits::M23_001;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.3';

our @ISA = qw(Algorithm::CheckDigits);

my @keytable = (
	'T', 'R', 'W', 'A', 'G', 'M', 'Y', 'F',
	'P', 'D', 'X', 'B', 'N', 'J', 'Z', 'S',
	'Q', 'V', 'H', 'L', 'C', 'K', 'E',
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
	if ($number =~ /^(\d{8})-?([A-HJ-NP-TV-Z])$/i) {
		return $2 eq $self->_compute_checkdigit($1);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8})-?$/i) {
		return $number . $self->_compute_checkdigit($1);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8}-?)([A-HJ-NP-TV-Z])$/i) {
		return $1 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{8})-?([A-HJ-NP-TV-Z])$/i) {
		return $2 if (uc($2) eq $self->_compute_checkdigit($1));
	}
	return '';
} # checkdigit()

sub _compute_checkdigit {
	my $self   = shift;
	my $number = shift;

	$number =~ s/-//g;
	if ($number =~ /^\d{8}$/i) {
		return $keytable[($number % 23)];
	}
	return -1;
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M23_001 - compute check digits for DNI (ES)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $dni = CheckDigits('dni_es');

  if ($dni->is_valid('54362315K')) {
	# do something
  }

  $cn = $dni->complete('54362315');
  # $cn = '54362315K'

  $cd = $dni->checkdigit('54362315K');
  # $cd = 'K'

  $bn = $dni->basenumber('54362315K');
  # $bn = '54362315'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

The checkdigit is the whole number taken modulo 23 and coded according
to a keytable.

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
