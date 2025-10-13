package Util;
use strict; use warnings;

# Convert a string with underscores (_) and hyphens (-) into a namespaced CamelCase format using :: as the separator
sub camelize {
  my $str = shift;
  return $str if $str =~ /^[A-Z]/;
  return join '::', map { join('', map { ucfirst lc } split /_/) } split /-/, $str;
}

sub decamelize {
  my $str = shift;
  return $str if $str !~ /^[A-Z]/;
  return join '-', map { join('_', map { lc } grep { length } split /([A-Z]{1}[^A-Z]*)/) } split /::/, $str;
}
1;
