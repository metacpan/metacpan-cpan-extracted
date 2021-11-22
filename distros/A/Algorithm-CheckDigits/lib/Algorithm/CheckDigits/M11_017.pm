# vim: set ts=4 sw=4 tw=78 si et:
package Algorithm::CheckDigits::M11_017;

use 5.006;
use strict;
use warnings;
use integer;

use version; our $VERSION = 'v1.3.6';

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
    if ( $number =~ /^([-\d]+)(\d)$/ ) {
        return $2 eq $self->_compute_checkdigit($1);
    }
    return '';
}    # is_valid()

sub complete {
    my ( $self, $number ) = @_;
    if ( $number =~ /^[-\d]+$/ ) {
        my $cd = $self->_compute_checkdigit($number);
        return $number . $cd unless 0 > $cd;
    }
    return '';
}    # complete()

sub basenumber {
    my ( $self, $number ) = @_;
    if ( $number =~ /^([-\d]+)(\d)$/ ) {
        return $1 if ( $2 eq $self->_compute_checkdigit($1) );
    }
    return '';
}    # basenumber()

sub checkdigit {
    my ( $self, $number ) = @_;
    if ( $number =~ /^([-\d.]+)(\d)$/ ) {
        return $2 if ( $2 eq $self->_compute_checkdigit($1) );
    }
    return '';
}    # checkdigit()

sub _compute_checkdigit {
    my $self   = shift;
    my $number = shift;
    my ( $cd1, $cd2 ) = ( '', '' );

    $number =~ s/[-]//g;
    my @digits = split //, $number;
    my $sum = 0;
    for ( my $i = 0; $i <= $#digits; $i++ ) {
        $sum += ( $i + 1 ) * $digits[$i];
    }
    $sum %= 11;
    return 0 if ( 9 < $sum );
    return $sum;
}    # _compute_checkdigit()

# Preloaded methods go here.

1;
__END__

=head1 NAME

CheckDigits::M11_017 - compute check digits for EC-No, EINECS, ELINCS

=head1 SYNOPSIS

  use Algorithm::CheckDigits;

  $ecno = CheckDigits('ecno');

  if ($ecno->is_valid('200-236-6')) {
	# do something
  }

  $cn = $ecno->complete('200-236-');
  # $cn = '200-236-6'

  $cd = $ecno->checkdigit('200-236-6');
  # $cd = '6'

  $bn = $ecno->basenumber('200-236-6');
  # $bn = '200-236-'
  
=head1 DESCRIPTION

=head2 ALGORITHM

=over 4

=item 1

From left to right all digits are multiplied with their position
in the sequence.

=item 2

The sum of all products is computed.

=item 3

The sum of step 2 is taken modulo 11.

The checkdigit is the last digit of the result.

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
F<http://en.wikipedia.org/wiki/EC-No>.

=cut
