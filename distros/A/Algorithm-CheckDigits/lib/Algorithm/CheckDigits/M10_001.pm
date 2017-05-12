# vim: set ts=4 sw=4 tw=78 si et:
package Algorithm::CheckDigits::M10_001;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = qv('v1.3.2');

our @ISA = qw(Algorithm::CheckDigits);

my %prefix = (
    'amex'     => [ '34', '37', ],
    'bahncard' => [ '70', ],
    'diners'   => [ '30[0-5]', '36', '38', ],
    'discover' => [ '6011', ],
    'enroute' => [ '2014', '2149', ],
    'jcb'     => [ '1800', '2131', '3088', ],
    'mastercard' => [ '5[1-5]', ],
    'miles&more' => [ '99', '22', ],
    'visa'       => [ '4', ],
);

my %ctable = (
    '0' => 0, '1' => 1, '2' => 2, '3' => 3, '4' => 4,
    '5' => 5, '6' => 6, '7' => 7, '8' => 8, '9' => 9,
    'A' => 10, 'B' => 11, 'C' => 12, 'D' => 13, 'E' => 14,
    'F' => 15, 'G' => 16, 'H' => 17, 'I' => 18, 'J' => 19,
    'K' => 20, 'L' => 21, 'M' => 22, 'N' => 23, 'O' => 24,
    'P' => 25, 'Q' => 26, 'R' => 27, 'S' => 28, 'T' => 29,
    'U' => 30, 'V' => 31, 'W' => 32, 'X' => 33, 'Y' => 34,
    'Z' => 35,
);

# Aliases
$prefix{'eurocard'} = $prefix{'mastercard'};

# omit prefixes doesn't work with the test numbers
my %omitprefix = (
    'jcb'      => 0,
    'enroute'  => 0,
    'discover' => 0,
);

sub new {
    my $proto = shift;
    my $type  = shift;
    my $class = ref($proto) || $proto;
    my $self  = bless( {}, $class );
    $self->{type} = lc($type);
    $self->_determine_pattern();
    return $self;
}    # new()

sub is_valid {
    my ( $self, $number ) = @_;
    if ( $number =~ /^($self->{pattern})([0-9])$/i ) {
        return $2 == $self->_compute_checkdigit( uc($1) );
    }
    return '';
}    # is_valid()

sub complete {
    my ( $self, $number ) = @_;
    if ( $number =~ /^$self->{pattern}$/i ) {
        return $number . $self->_compute_checkdigit( uc($number) );
    }
    return '';
}    # complete()

sub basenumber {
    my ( $self, $number ) = @_;
    if ( $number =~ /^($self->{pattern})([0-9])$/i ) {
        return $1 if ( $2 == $self->_compute_checkdigit( uc($1) ) );
    }
    return '';
}    # basenumber()

sub checkdigit {
    my ( $self, $number ) = @_;
    if ( $number =~ /^($self->{pattern})([0-9])$/i ) {
        return $2 if ( $2 == $self->_compute_checkdigit( uc($1) ) );
    }
    return '';
}    # checkdigit()

sub _compute_checkdigit {
    my $self   = shift;
    my $number = shift;
    $number =~ s/\s//g;
    if ( $omitprefix{ $self->{type} } ) {
        my $pf = $prefix{ $self->{type} };
        for my $p ( @{$pf} ) {
            if ( $number =~ /^$p([0-9]+)$/ ) {
                $number = $1;
                last;
            }
        }
    }
    if ('isin' eq $self->{type}) {
        # With ISIN letters are handled differently than for instance with
        # CUSIP, so we substitute them here
        $number =~ s/([A-Z])/$ctable{$1}/ge;
    }
    elsif ('imeisv' eq $self->{type}) {
        # With IMEISV the SV (software version) is left out from the
        # computation of the checkdigit
        $number = substr( $number, 0, 14 ) if ( 'imeisv' eq $self->{type} );
    }

    my @digits =  map { $ctable{$_} } split( //, $number );
    my $even   = 1;
    my $sum    = 0;
    for ( my $i = $#digits; $i >= 0; $i-- ) {
        if ($even) {
            my $tmp = 2 * $digits[$i];
            $sum += $tmp / 10 + $tmp % 10;
        }
        else {
            $sum += $digits[$i] / 10 + $digits[$i] % 10;
        }
        $even = not $even;
    }
    return ( 10 - $sum % 10 ) % 10;
}    # _compute_checkdigit()

sub _determine_pattern {
    my $self = shift;
    if ('cusip' eq $self->{type}) {
        $self->{pattern} = qr/[0-9A-Z]{8}/io;
    }
    else {
        $self->{pattern} = qr/[0-9A-Z ]+/io;
    }
} # _determine_pattern()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M10_001 - compute check digits for Bahncard (DE), IMEI,
IMEISV, ISIN, Miles&More, Payback (DE), Personnummer (SE), Passport
(BR), Credit Cards, SSN (US), Samordningsnummer (SE), VAT RN (ES), VAT
RN (IT), VAT RN (SE), International Securities Identifikation Number
(ISIN), CUSIP

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $visa = CheckDigits('visa');

  if ($visa->is_valid('4111 1111 1111 1111')) {
	# do something
  }

  $cn = $visa->complete('4111 1111 1111 111');
  # $cn = '4111 1111 1111 1111'

  $cd = $visa->checkdigit('4111 1111 1111 1111');
  # $cd = '7'

  $bn = $visa->basenumber('4111 1111 1111 1111');
  # $bn = '4111 1111 1111 111'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning right all numbers are weighted alternatively 1 and 2 (that
is the check digit is weighted 1).

=item 2

The total of the digits of all products is computed.

=item 3

The sum of step 3 ist taken modulo 10.

=item 4

The check digit is the difference between 10 and the number from step
3.

=back

To validate the total of the digits of all numbers inclusive check
digit taken modulo 10 must be 0.

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if the last digit
is a valid check digit according to the algorithm given above.

Returns false otherwise,

If the checked number is of type CUSIP, the number must be exact 9 digits or
letters long and must not have spaces in between.

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
L<Algorithm::CheckDigits>,
F<www.pruefziffernberechnung.de>.
F<http://en.wikipedia.org/wiki/CUSIP>

For IMEI, IMEISV: ETSI Technical Specification TS 100 508 (v6.2.0)

=cut
