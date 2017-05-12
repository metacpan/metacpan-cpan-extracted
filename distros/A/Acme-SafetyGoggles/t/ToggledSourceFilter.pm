package t::ToggledSourceFilter;

# a source filter that is nasty if a certain environment
# variable is set.

use Filter::Simple;

FILTER {
  if ($ENV{TOGGLE} eq 'ON') {
    tr/1249/4912/;
  }
};

1;
