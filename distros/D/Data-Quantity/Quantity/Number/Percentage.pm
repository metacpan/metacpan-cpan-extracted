### Change History
  # 2001-04-17 Created. -Piglet

package Data::Quantity::Number::Percentage;

use vars qw( $VERSION );
$VERSION = 0.001;

use strict;
use Carp;

# $string = Data::Quantity::Number::Percentage::up_or_down($first, $second)
sub up_or_down {
  my $first = shift;
  my $second = shift;
  my $change = percent_change($first, $second);

  if ($first == $second) {
    return "no change";
  } elsif ($first < $second) {
    return "up $change";
  } else {
    return "down $change";
  }
}

# $string = Data::Quantity::Number::Percentage::percent_change($first, $second)
sub percent_change {
  my $first = shift;
  my $second = shift;
  my $percent;

  if ($first != 0) {
    $percent = sprintf('%.2f', (($second - $first) / $first) * 100);
  } elsif ($second != 0) {
    $percent = 100;
  } else {
    $percent = 0;
  }
  return "$percent%";
}

1;
