### Change History
  # 1998-12-03 Created. -Simon

package Data::Quantity::Abstract::InstanceIndex;

require 5;
use strict;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Number::Integer '-isasubclass';

use Class::MakeMethods ( 
  'Standard::Inheritable:scalar' => 'instances',
);

# $flag = Data::Quantity::Abstract::InstanceIndex->is_valid_index($number);
  # Is this value acceptable for this quantity.
sub is_valid_index {
  my $class_or_item = shift;
  my $value = shift;
  
  my $instances = $class_or_item->instances or return;
  return ( $value >= 0 and $value == int($value) and $value <= $#$instances );
}

# $flag = Data::Quantity::Abstract::InstanceIndex->is_index_value($number);
  # Is this value acceptable, and *not blank or empty*, for this quantity.
sub is_index_value {
  my $class_or_item = shift;
  my $value = shift;
  
  my $instances = $class_or_item->instances or return;
  return ( $value > 0 and $value == int($value) and $value <= $#$instances );
}

# $definition = Data::Quantity::Abstract::InstanceIndex->instance($number);
sub instance {
  my $class_or_item = shift;
  my $value = shift;
  
  return unless $class_or_item->is_index_value($value);
  return $class_or_item->instances->[ $value ];
}

# $value = Data::Quantity::Abstract::InstanceIndex->readable_value($number)
# $value = Data::Quantity::Abstract::InstanceIndex->readable_value($number, $style)
sub readable_value {
  my $class_or_item = shift;
  my $value = shift;
  my $style = shift || 'name';
  
  my $instance = $class_or_item->instance($value) or return;
  
  return $instance->{ $style };
}

1;