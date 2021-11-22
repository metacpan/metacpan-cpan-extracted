package Algorithm::CheckDigits::M97_002;
# vim: set sw=4 ts=4 tw=78 et si:

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = qv('v1.3.6');

our @ISA = qw(Algorithm::CheckDigits);

my %subst = (
    A => 10, B => 11, C => 12, D => 13, E => 14,
    F => 15, G => 16, H => 17, I => 18, J => 19,
    K => 20, L => 21, M => 22, N => 23, O => 24,
    P => 25, Q => 26, R => 27, S => 28, T => 29,
    U => 30, V => 31, W => 32, X => 33, Y => 34,
    Z => 35,
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
    my $self = shift;

    if (my ($checkdigit,$number) = _prepare_number(shift)) {

        return $checkdigit eq _compute_checkdigit($number);
    }
	return ''
} # is_valid()

sub complete {
    my $self = shift;
    my $incomplete = uc(shift);

    if (my ($checkdigit,$number) = _prepare_number($incomplete)) {

        $incomplete =~ /^(..)..(.+)/;

		return $1 . _compute_checkdigit($number) . $2;
    }
    return '';
} # complete()

sub basenumber {
    my $self = shift;
    my $unchecked = shift;

    if (my ($checkdigit,$number) = _prepare_number($unchecked)) {

        $unchecked =~ /^(..)..(.+)/;

		return $1.'00'.$2
            if ($checkdigit eq _compute_checkdigit($number));
    }
    return '';
} # basenumber()

sub checkdigit {
    my $self = shift;

    if (my ($checkdigit,$number) = _prepare_number(shift)) {
		return $checkdigit
            if ($checkdigit eq _compute_checkdigit($number));
    }
    return '';
} # checkdigit()

sub _compute_checkdigit {
    my $number = shift;

#    my $bignum = Math::BigInt->new($number);
#    my $mod    = $bignum % 97;
#
# A comparison with Benchmark::compthese() brought:
#
#             Rate   bignum 9_digits
# bignum    2502/s       --     -95%
# 9_digits 46225/s    1748%       --
#
# so I reverted _compute_checkdigit to this code.
# Thanks to Detlef Pilzecker for making me aware of this.

    my $mod = '';
    while ($number ne '') {
        $number = $mod . $number;
        $mod    = substr($number,0,9,'') % 97;
    }
    return sprintf("%02d",(98 - $mod));
} # _compute_checkdigit()

sub _prepare_number {
    my $number = uc(shift);

    $number        =~ s/\s//g;

    if ($number =~ /^([A-Z]{2})(\d\d)([A-Z\d]{2,30})$/) {
        my $checkdigit = $2;
        $number        = $3 . $1 . '00';
        $number        =~ s/([A-Z])/$subst{$1}/g;
        return ($checkdigit,$number);
    }
    return;
} # _prepare_number()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M97_002 - compute check digits for International Bank
Account Number (IBAN)

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $iban = CheckDigits('iban');

  if ($iban->is_valid('DE88 2008 0000 09703 7570 0')) {
	# do something
  }

  $cn = $iban->complete('DE00 2008 0000 09703 7570 0');
  # $cn = 'DE88 2008 0000 09703 7570 0'

  $cd = $iban->checkdigit('DE88 2008 0000 09703 7570 0');
  # $cd = '88'

  $bn = $iban->basenumber('DE88 2008 0000 09703 7570 0');
  # $bn = 'DE00 2008 0000 09703 7570 0'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item S<0>

The IBAN number must be prepared. The first two letters and the
checksum will be moved to the right end. The letters are substituted
according to the substitute table and the checksum is set to '00'.

=item S<1>

The whole number is taken modulo 97.

=item S<2>

The checksum is difference between 98 and the result of step 1.

=item S<3>

If the checksum is smaller then 10, a leading zero will be
prepended.

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

Returns the checkdigits of C<$number> if C<$number> has a valid check
digit.

Return '' otherwise.

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 THANKS

Detlef Pilzecker pointed out to me that there may be more letters as the first
two in an IBAN number. He also made me aware of a faster method to compute the
check number than using Math::BigInt.

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,
F<www.sic.ch/en/tkicch_home/tkicch_standardization/tkicch_financialinstitutions_ibanipi.htm>.

=cut
