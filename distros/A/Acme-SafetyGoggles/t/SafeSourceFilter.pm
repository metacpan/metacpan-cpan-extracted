package t::SafeSourceFilter;

# a source filter that changes all instances of "42" in the source code to "42"
# (that is, it doesn't change anything)

use Filter::Simple;

FILTER {
  s/42/42/g;
};

1;
