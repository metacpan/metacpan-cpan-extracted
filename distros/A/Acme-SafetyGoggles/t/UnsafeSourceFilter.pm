package t::UnsafeSourceFilter;

# a source filter that changes all instances
# of the digits 1, 2, 4, and 9 in the source code.
# Ooooh! That's a nasty thing to do.

use Filter::Simple;

FILTER {
  tr/4219/1942/;
};

1;
