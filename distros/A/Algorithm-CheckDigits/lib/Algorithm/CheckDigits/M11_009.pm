package Algorithm::CheckDigits::M11_009;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.6';

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 2, 7, 6, 5, 4, 3, 2 );

my @keys   = ('', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'Z', 'J' );

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
	if ($number =~ /^([fgst])?(\d{7})([a-jz])$/i) {
		return (uc($3) eq $self->_compute_checkdigits($2));
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if($number =~ /^([fgst])?(\d{7})$/i) {
		my $prefix = $1 || '';
		return $prefix . $2 . $self->_compute_checkdigits($2);
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if(   $number =~ /^([fgst])?(\d{7})([a-jz])$/i
	  and uc($3) eq $self->_compute_checkdigits($2)) {
		my $prefix = $1 || '';
		return $prefix . $2;
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^([fgst])?(\d{7})([a-jz])$/i) {
		return $self->_compute_checkdigits($2);
	}
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
	return $keys[11 - $sum];
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_009 - compute check digits NRIC (SG)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $nric = CheckDigits('nric_sg');

  if ($nric->is_valid('S1234567D')) {
	# do something
  }

  $cn = $nric->complete('S1234567');
  # $cn = 'S1234567D'

  $cd = $nric->checkdigit('S1234567D');
  # $cd = 'D'

  $bn = $nric->basenumber('S1234567D');
  # $bn = 'S1234567';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning left every digit is weighted with 2, 7, 6, 5, 4, 3, 2

=item 2

The weighted digits are added.

=item 3

The sum from step 2 is taken modulo 11.

=item 4

The checkdigit is 11 minus the sum from step 3 converted to a
character according to the following table:

  @cd = ('','A','B','C','D','E','F','G','H','I','Z','J', );

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists of seven digits
(optional preceded by a letter out of 'F', 'G', 'S', 'T')
followed by a valid letter according to the algorithm given above.

Returns false otherwise,

=item complete($number)

The check letter for C<$number> is computed and appended to the
end of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits and letters.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

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
