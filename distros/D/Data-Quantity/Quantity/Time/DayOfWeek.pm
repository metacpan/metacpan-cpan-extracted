### Change History
  # 1999-02-21 Added weekday and weekend attributes.
  # 1998-12-03 Factored out Data::Quantity::Abstract::InstanceIndex superclass.
  # 1998-12-02 Created. -Simon

package Data::Quantity::Time::DayOfWeek;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Abstract::InstanceIndex '-isasubclass';

# undef = Data::Quantity::Time::DayOfWeek->scale();
sub scale {
  return 'DayOfWeek';
}

Data::Quantity::Time::DayOfWeek->instances();
Data::Quantity::Time::DayOfWeek->instances( [
  {
  },
  {
    'name' => 'Monday',
    'short' => 'Mon',
    'initial' => 'M',
    'weekday' => 1,
  },
  {
    'name' => 'Tuesday',
    'short' => 'Tue',
    'initial' => 'T',
    'weekday' => 1,
  },
  {
    'name' => 'Wednesday',
    'short' => 'Wed',
    'initial' => 'W',
    'weekday' => 1,
  },
  {
    'name' => 'Thursday',
    'short' => 'Thr',
    'initial' => 'R',
    'weekday' => 1,
  },
  {
    'name' => 'Friday',
    'short' => 'Fri',
    'initial' => 'F',
    'weekday' => 1,
  },
  {
    'name' => 'Saturday',
    'short' => 'Sat',
    'initial' => 'S',
    'weekend' => 1,
  },
  {
    'name' => 'Sunday',
    'short' => 'Sun',
    'initial' => 'U',
    'weekend' => 1,
  },
] );

1;
