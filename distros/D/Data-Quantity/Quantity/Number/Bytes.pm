### Change History
  # 1998-12-02 Created. -Simon

package Data::Quantity::Number::Bytes;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

# undef = Data::Quantity::Number::Number->scale();
sub scale {
  return 'Bytes';
}

# @ByteScales - text labels for powers of two-to-the-tenth bytes
use vars qw( @ByteScales );
@ByteScales = qw( B KB MB GB TB );

# $value = Data::Quantity::Number::Bytes->readable_value($number)
  # Show no more than one decimal place, followed by scale label
sub readable_value {
  my $class_or_item = shift;
  my $value = my $number = shift;
  
  my $scale;
  foreach $scale (@ByteScales) {
    return ( (int($value * 10 + 0.5)/10) . $scale ) if ($value < 1024); 
    $value = $value / 1024;
  }
  carp "Quantity out of range: $number Bytes";
}

1;
