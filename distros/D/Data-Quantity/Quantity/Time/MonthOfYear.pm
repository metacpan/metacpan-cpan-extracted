### Change History
  # 1998-12-03 Factored out Data::Quantity::Abstract::InstanceIndex superclass.
  # 1998-12-02 Created. -Simon

package Data::Quantity::Time::MonthOfYear;

require 5;
use strict;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Abstract::InstanceIndex '-isasubclass';

# undef = Data::Quantity::Time::MonthOfYear->scale();
sub scale {
  return 'MonthOfYear';
}

Data::Quantity::Time::MonthOfYear->instances();
Data::Quantity::Time::MonthOfYear->instances( [
  {
  },
  { 
    'name' => 'January',
    'short' => 'Jan',
  },
  { 
    'name' => 'February',
    'short' => 'Feb',
  },
  { 
    'name' => 'March',
    'short' => 'Mar',
  },
  { 
    'name' => 'April',
    'short' => 'Apr',
  },
  { 
    'name' => 'May',
    'short' => 'May',
  },
  { 
    'name' => 'June',
    'short' => 'Jun',
  },
  { 
    'name' => 'July',
    'short' => 'Jul',
  },
  { 
    'name' => 'August',
    'short' => 'Aug',
  },
  { 
    'name' => 'September',
    'short' => 'Sep',
  },
  { 
    'name' => 'October',
    'short' => 'Oct',
  },
  { 
    'name' => 'November',
    'short' => 'Nov',
  },
  { 
    'name' => 'December',
    'short' => 'Dec',
  },
] );


# $padded = $quantity->zero_padded();
sub zero_padded {
  my $date = shift;
  $date->SUPER::zero_padded( scalar @_ ? @_ : 2 );
}

1;
