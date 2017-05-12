### Change History
  # 1999-02-21 Created. -Simon

package Data::Quantity::Time::YearAndMonth;

require 5;
use strict;
use Carp;

use vars qw( $VERSION );
$VERSION = 0.001;

use Data::Quantity::Abstract::Compound '-isasubclass';

sub component_classes {
  qw( Data::Quantity::Time::Year Data::Quantity::Time::MonthOfYear )
}

# $year_q = $month_q->year;
sub year {
  my $month_q = shift;
  $month_q->[0];
}

# $moy_q = $month_q->month_of_year;
sub month_of_year {
  my $month_q = shift;
  $month_q->[1];
}

# $count = $month_q->days_in_month;
sub days_in_month {
  my $month_q = shift;
  
  require Time::DaysInMonth;
  return Time::DaysInMonth::days_in( map { $_->value } @$month_q );
}

# $new_date = $month_q->first_day;
sub first_day {
  my $month_q = shift;
  Data::Quantity::Time::Date->new_from_ymd( 
    $month_q->year, 
    $month_q->month_of_year, 
    Data::Quantity::Time::DayOfMonth->new( 1 ),
  );
}

# $new_date = $month_q->last_day;
sub last_day {
  my $month_q = shift;
  Data::Quantity::Time::Date->new_from_ymd( 
    $month_q->year, 
    $month_q->month_of_year, 
    Data::Quantity::Time::DayOfMonth->new( $month_q->days_in_month ),
  );
}

1;