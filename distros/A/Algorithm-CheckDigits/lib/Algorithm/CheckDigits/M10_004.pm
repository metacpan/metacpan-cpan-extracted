package Algorithm::CheckDigits::M10_004;

# vim: set tw=78 sw=4 ts=4 si sr et:

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.5';

our @ISA = qw(Algorithm::CheckDigits);

my $valid_prefix = {
    isbn13 => {
        978 => 1,
        979 => 1,
    },
    issn13 => { 977 => 1, },
};

sub new {
    my $proto = shift;
    my $type  = shift;
    my $class = ref($proto) || $proto;
    my $self  = bless( {}, $class );
    $self->{type} = lc($type);
    return $self;
}    # new()

sub is_valid {
    my ( $self, $number ) = @_;
    if ( $number =~ /^([0-9 -]+)([0-9])$/ ) {
        return $2 == $self->_compute_checkdigit($1);
    }
    return '';
}    # is_valid()

sub complete {
    my ( $self, $number ) = @_;
    if ( $number =~ /^[0-9 -]+$/ ) {
        return $number . $self->_compute_checkdigit($number);
    }
    return '';
}    # complete()

sub basenumber {
    my ( $self, $number ) = @_;
    if ( $number =~ /^([0-9 -]+)([0-9])$/ ) {
        return $1 if ( $2 == $self->_compute_checkdigit($1) );
    }
    return '';
}    # basenumber()

sub checkdigit {
    my ( $self, $number ) = @_;
    if ( $number =~ /^([0-9 -]+)([0-9])$/ ) {
        return $2 if ( $2 == $self->_compute_checkdigit($1) );
    }
    return '';
}    # checkdigit()

sub _compute_checkdigit {
    my $self   = shift;
    my $number = shift;
    $number =~ s/[ -]//g;
    if ( $number =~ /^([0-9]*)$/ ) {
        if ( $valid_prefix->{ $self->{type} } ) {
            my $prefix = substr $number, 0, 3;
            unless ( $valid_prefix->{ $self->{type} }->{$prefix} ) {
                return -1;
            }
        }
        my @digits = split( //, $number );
        my $even   = 1;
        my $sum    = 0;
        for ( my $i = $#digits; $i >= 0; $i-- ) {
            if ($even) {
                $sum += 3 * $digits[$i];
            }
            else {
                $sum += $digits[$i];
            }
            $even = not $even;
        }
        return ( 10 - $sum % 10 ) % 10;
    }
    return -1;
}    # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M10_004 - compute check digits for 2aus5, EAN, ILN, ISBN13, NVE

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ean = CheckDigits('ean');

  if ($ean->is_valid('7622200004607')) {
	# do something
  }

  $cn = $ean->complete('762220000460');
  # $cn = '7622200004607'

  $cd = $ean->checkdigit('7622200004607');
  # $cd = '7'

  $bn = $ean->basenumber('7622200004607');
  # $bn = '762220000460'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning right all numbers are weighted alternatively 1 and 3 (that
is the check digit is weighted 1).

=item 2

The sum of all products is computed.

=item 3

The sum of step 3 ist taken modulo 10.

=item 4

The check digit is the difference between 10 and the number from step 3.

=back

To validate the total of the digits of all numbers inclusive check
digit taken modulo 10 must be 0.

=head2 METHODS

=over 4

=item is_valid($number)

Returns true only if C<$number> consists solely of digits, spaces and hyphen
and the last digit is a valid check digit according to the algorithm given
above.

Returns false otherwise,

=item complete($number)

The check digit for C<$number> is computed and concatenated to the end
of C<$number>.

Returns the complete number with check digit or '' if C<$number>
does not consist solely of digits, spaces and hyphen.

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

=head1 BUGS AND LIMITATIONS

When invoked as C<CheckDigits('isbn13')> the module checks whether the first
three digits (the country code) are 978 or 979, the current (as of 2006) EAN
country codes for books. If at any time other EAN country codes for ISBN-13
will be specified and the then responsible maintainer ignores this in the
code, please send a friendly email.

=head1 AUTHOR

Mathias Weidner, C<< <mamawe@cpan.org> >>

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>.

=cut
