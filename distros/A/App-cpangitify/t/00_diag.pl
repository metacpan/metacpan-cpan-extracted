use strict;
use warnings;
use Test::More;

our $format;
diag sprintf $format, 'git', eval {
  require Git::Wrapper;
  Git::Wrapper->new(".")->version;
} || '-';

1;
