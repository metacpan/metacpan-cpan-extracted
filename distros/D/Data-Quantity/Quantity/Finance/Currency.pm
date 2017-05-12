### Data::Quantity::Finance::Currency provides currency-appropriate formatting for numbers

### Copyright 1997, 1998 Evolution Online Systems, Inc.
  # You may use this software for free under the terms of the Artistic License

### Change History
  # 2002-01-21 Simon: Removed bogus dependency on Err::Debug.
  # 1999-08-02 Simon: Revived; moved to Data::Quantity:: package space.
  # 1998-07-17 Simon: Refactored; added support for non-decimal display.
  # 1998-04-18 Jeremy: Added POD.
  # 1998-03-24 Del: Corrected typos; most functions are not methods. 
  # 1998-03-17 Del: Corrected typo in method call. 
  # 1997-11-17 Simon: Preliminary revised version. 

package Data::Quantity::Finance::Currency;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Number '-isasubclass';

use Class::MakeMethods (
  'Template::ClassName:subclass_name --require' => 'type',
  'Standard::Global:scalar' => 'default_type',
  'Standard::Inheritable:scalar' => 'scale',
);

### Package Configuration

Data::Quantity::Finance::Currency->default_type( Data::Quantity::Finance::Currency->type('USD') );

1;

__END__


=pod

=head1 Data::Quantity::Finance::Currency

Currency-appropriate formatting for numbers


=head1 Synopsis

  use Data::Quantity::Finance::Currency;
  
  print Data::Quantity::Finance::Currency->type('USD')->readable_value( $pennies );
  
  $pennies = Data::Quantity::Finance::Currency->type('USD')->numeric_value( <STDIN> );
  

=head1 Description

This module provides functions to convert between different representations of currency values. It does not (yet) actually handle any foreign currencies, conversions or multiple-currency environments, but I imagine it might, some day.

Integer values are used for internal representation of currency values to avoid floating-point vagaries. For US Dollars, this means that values are stored as an integer number of pennies.

=over 4

=item readable_value 

Converts an integer value to a readable string. 

For US Dollars, this includes C<1 => $0.01> and C<148290 => $1,482.90>.

=item numeric_value

Convert an externally-generated candidate value into an integer.

For US Dollars, this includes C<1 => $0.01> and C<148290 => $1,482.90>.

=back

There are two internal representations:

=over 4

=item storable 

An integer value containing the major and minor currency numbers.

    148290

=item split

A list of the major and minor currency numbers; in the context of US currency, these would be the dollar and cent amounts.

    ( 1482, 90 )

=back


=head1 Reference

=head2 Package Configuration

=over 4

=item $CurrencySymbol

The local currency symbol. Defaults to '$'.

=item $DecimalPlaces

The number of decimal places supported by the selected currency. Defaults to 2.

=item $DecimalSep

The decimal separator for the selected currency. Defaults to '.'.

=item $DisplayDecimals

A flag to indicate if decimals are shown in display string. Defaults to 1.

=back


=head2 Conversions

=over 4

=item display_store( $integer_value ) : $display_str

Converts a value in the integral storage format to a formatted display string.

=item update_store( $integer_value ) : $decimal_number

Converts a value in the integral storage format to an editable decimal number.

=item store_update( $decimal_number ) : $integer_value

Converts a value in the editable decimal number format to a storable integer.

=item display_update( $decimal_number ) : $display_str

Converts a value in the editable decimal number format to a formatted display string.

=back


=head2 Split Input

These functions take a value in the storage or update format and convert it to a list of major and minor currency numbers.

=over 4

=item split_update( $decimal_number ) : ($major, $minor)

Accepts a dollar value (formatted or not) and returns a list of dollars and cents.

=item split_store( $integer_value ) : ($major, $minor)

=item conventionalize($major, $minor) : ($major, $minor)

Provides appropriate zero-padding for the major and minor currency numbers.

=back


=head2 Split Output

=over 4

=item store_split($major, $minor) : $integer_value

=item update_split($major, $minor) : $decimal_number

=item display_split($major, $minor) : $display_str

=back


=head2 Compatibility 

=over 4

=item pretty_dollars( $decimal_number ) : $display_str

Now invokes display_update.

Returns a value with a dollar sign, comma separated groups and appropriate decimal values.

=item cents_to_dollars( $integer_value ) : $display_str

Now invokes display_store.

Works as pretty_dollars above, but converts argument from an integer number of pennies.

=item dollars_to_cents( $decimal_number ) : $integer_value

Now invokes store_update.

Accepts a dollar value and returns an integer ammount of pennies.

=item pennies( $integer_value ) : $decimal_number

Now invokes update_store.

=back


=head1 Caveats and Upcoming Changes

This module is still somewhat disorganized; the interface is likely to change in future versions.


=head1 This is Free Software

Copyright 1997, 1998 Evolution Online Systems, Inc.

You can use this software under the same terms as Perl itself.

=cut
