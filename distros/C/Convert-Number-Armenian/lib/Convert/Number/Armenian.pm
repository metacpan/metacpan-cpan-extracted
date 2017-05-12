package Convert::Number::Armenian;

use strict;
use warnings;
use Exporter 'import';
use vars qw/ $VERSION @EXPORT_OK /;

$VERSION = "0.1";
@EXPORT_OK = qw/ arm2int int2arm /;

=encoding utf-8

=head1 NAME

Convert::Number::Armenian - convert between Armenian and Western numerals

=head1 SYNOPSIS

  use Convert::Number::Armenian qw( arm2int int2arm );
  
  my $armenian_rep = int2arm( 1999 );
  my $decimal_val  = arm2int( 'ՌՋՂԹ' );

=head1 DESCRIPTION

This is a relatively simple module for converting between Armenian-style
numbers and their Western decimal representations. The module exports two
functions on request: C<arm2int> and C<int2arm>.

=head1 FUNCTIONS

=head2 arm2int

Takes a string that contains an Armenian number and returns the decimal
value. The function tries to deal with common though non-canonical
representations such as ՃՌ for 100,000. The Armenian string may be upper-
or lowercase, or a mix of both.

=cut

my $BASE = 1328; # Armenian 'A' minus one
#	10^4 is 555-556
#	10^3 is 54C-553
#	10^2 is 543-54B
#	10^1 is 53A-542
#	10^0 is 531-539

sub arm2int {
    my $str = shift;
    # Uppercase the string for convenience.
    $str = uc( $str );
    my @codepoints = unpack( "U*", $str );
    my $total;
    foreach my $digit ( @codepoints ) {
        # Error check.
        unless( $digit > 1328 && $digit < 1367 ) {
            warn "string $str appears not to be an Armenian number\n";
            return 0;
        }

        # Convert into a number.
        my $val;
        if( $digit < 1338 ) {
            $val = $digit - 1328;
        } elsif( $digit < 1347 ) {
            $val = ( $digit - 1337 ) * 10;
        } elsif( $digit < 1356 ) {
            $val = ( $digit - 1346 ) * 100;
        } elsif( $digit < 1365 ) {
        	$val = ( $digit - 1355 ) * 1000;
        } else {
            $val = ( $digit - 1364 ) * 10000;
        }

        # Figure out if we are adding or multiplying.
        if( $total && $total < $val ) {
            $total = $total * $val;
        } else {
            $total += $val;
        }
    }

    return $total;
}

=head2 int2arm

Takes a number and returns its Armenian representation in canonical form, meaning
an uppercase string with digit values descending from left to right. At the moment 
only values between 1 and 29999 can be converted.

=cut

## TODO handle bigger numbers through multiplication, 
## e.g. 144,000 as 144-1000
sub int2arm {
	my $int = shift;
	if( $int < 1 || $int > 29999 ) {
		warn "Can only convert numbers between 1 - 29999";
		return;
	}
	my @parts;
	foreach my $i ( 0 .. 4 ) {
		my $digit = int( $int / ( 10 ** $i ) ) % 10;
		if( $digit ) {
			unshift( @parts, chr( $BASE + ( 9 * $i ) + $digit ) );
		}
	}
	
	return( join( '', @parts ) );
}
		

=head1 TODO

The module as written depends on correct Perl Unicode behavior; that means
that on earlier versions of Perl this module may not work as expected. As
soon as I work out which is the minimum version, I will update the module
with the correct requirement.

Armenian ligatures probably won't produce the correct result for arm2int.

=head1 LICENSE

This package is free software and is provided "as is" without express
or implied warranty.  You can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

Tara L Andrews, L<aurum@cpan.org>

=cut

1;