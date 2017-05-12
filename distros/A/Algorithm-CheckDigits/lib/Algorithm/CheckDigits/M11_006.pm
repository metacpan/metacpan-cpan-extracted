package Algorithm::CheckDigits::M11_006;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.2';

our @ISA = qw(Algorithm::CheckDigits);

my @weight = ( 6, 3, 7, 9, 10, 5, 8, 4, 2, 1 );

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
	if ($number =~ /^(\d{4}-?\d{4})-?(\d\d)-?(\d{10})$/) {
		return uc($2) eq $self->_compute_checkdigits($1,$3);
	}
	return ''
} # is_valid()

sub complete {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{4}-?\d{4})[-\s]+(\d{10})$/) {
		return "$1-"
		     . $self->_compute_checkdigits($1,$2)
		     . "-$2";
	}
	return '';
} # complete()

sub basenumber {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{4}-?\d{4})-?(\d\d)-?(\d{10})$/) {
		return "$1-  -$3" if ($2 eq $self->_compute_checkdigits($1,$3));
	}
	return '';
} # basenumber()

sub checkdigit {
	my ($self,$number) = @_;
	if ($number =~ /^(\d{4}-?\d{4})-?(\d\d)-?(\d{10})$/) {
		return $2 if ($2 eq $self->_compute_checkdigits($1,$3));
	}
	return '';
} # checkdigit()

sub _compute_checkdigits {
	my $self    = shift;
	my $bank    = shift;
	my $account = shift;

	$bank =~ s/-//g;

	my $calc = sub {
		my @digits = split(//,shift);
		my $sum = 0;
		for (my $i = 0; $i <= $#digits; $i++) {
			$sum += $weight[$i] * $digits[$#digits - $i];
		}
		$sum %= 11;
		return $sum ? 11 - $sum : 0;
	};
	my $first  = $calc->($bank);
	my $second = $calc->($account);

	return sprintf("%d%d",$first,$second);
} # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=encoding iso-8859-1

=head1 NAME

CheckDigits::M11_006 - compute check digits for Código de Cuenta Corriente (ES)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ccc = CheckDigits('ccc_es');

  if ($ccc->is_valid('2420-0730-27-0050103552')) {
	# do something
  }

  $cn = $ccc->complete('2420-0730-  -0050103552');
  # $cn = '2420-0730-27-0050103552'

  $cd = $ccc->checkdigit('2420-0730-27-0050103552');
  # $cd = '27'

  $bn = $ccc->basenumber('2420-0730-27-0050103552');
  # $bn = '2420-0730-  -0050103552';
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning right all digits are weighted 6,3,7,9,10,5,8,4,2,1.

=item 2

The weighted digits are added.

=item 3

The sum of step 2 is taken modulo 11.

=item 4

The checkdigit is 11 minus the sum from step 3.

If the difference is 10, the checkdigit is 1.

If the difference is 11, the checkdigit is 0.

=back

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of numbers and hyphens
and the two digits in the middle
are valid check digits according to the algorithm given above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and inserted into the
middle of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits, hyphens and spaces.

=item basenumber($number)

Returns the basenumber of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=item checkdigit($number)

Returns the check digits of C<$number> if C<$number> has valid check
digits.

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

=cut
