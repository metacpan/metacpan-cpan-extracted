# vim: set ts=4 sw=4 tw=78 et si:
package Algorithm::CheckDigits::MXX_002;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.2';

our @ISA = qw(Algorithm::CheckDigits);

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
    if ( $number =~ /^(\d{1,7}-?\d{2}-?)(\d)$/ ) {
        return 1 if ( $2 == $self->_compute_checkdigit($1) );
    }
    return '';
}    # is_valid()

sub complete {
    my ( $self, $number ) = @_;
    if ( $number =~ /^\d{1,7}-?\d{2}-?$/ ) {
        return $number . $self->_compute_checkdigit($number);
    }
    return '';
}    # complete()

sub basenumber {
    my ( $self, $number ) = @_;
    if ( $number =~ /^(\d{1,7}-?\d{2}-?)(\d)$/ ) {
        return $1 if ( $2 == $self->_compute_checkdigit($1) );
    }
    return '';
}    # basenumber()

sub checkdigit {
    my ( $self, $number ) = @_;
    if ( $number =~ /^(\d{1,7}-?\d{2}-?)(\d)$/ ) {
        return $2 if ( $2 == $self->_compute_checkdigit($1) );
    }
    return '';
}    # checkdigit()

sub _compute_checkdigit {
    my $self   = shift;
    my $number = shift;

    $number =~ s/-//g;
    my @digits = split( //, $number );
    my $weight = 1;
    my $sum    = 0;

    for ( my $i = $#digits; $i >= 0; $i-- ) {
        $sum += $digits[$i] * $weight++;
    }

    return $sum % 10;
}    # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::MXX_002 - compute check digits for CAS

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $cas = CheckDigits('cas');

  if ($cas->is_valid('1333-74-0')) {
	# do something
  }

  $cn = $cas->complete('1333-74-');
  # $cn = '1333-74-0'

  $cd = $cas->checkdigit('1333-74-0');
  # $cd = '0'

  $bn = $cas->basenumber('1333-74-0');
  # $bn = '1333-74-'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

Beginning right with the second digit all digits are weighted
ascending starting with 1.

=item 2

The sum of those products is computed.

=item 3

The checksum is the last digit of the sum from step 2 (modulo 10).

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

=head1 THANKS

Aaron W. West pointed me to a fault in the computing of the check
digit.

HERMIER Christophe made me aware that CAS is now assigning 10-digit CAS
Registry Numbers (F<http://www.cas.org/newsevents/10digitrn.html>)

=head1 SEE ALSO

L<perl>,
L<CheckDigits>,
F<www.pruefziffernberechnung.de>,
F<www.cas.org>
F<http://www.cas.org/expertise/cascontent/registry/checkdig.html>

=cut
