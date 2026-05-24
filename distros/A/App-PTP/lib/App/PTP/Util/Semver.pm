# This module compares version strings following the precedence rules of the
# Semantic Versioning specification (https://semver.org, item 11). It is lenient
# about the structure of the input: an optional path-like prefix (anything up to
# a first '/', as long as there is no '.' before it) and an optional leading 'v'
# are recognized, and the version core may have any number of dot-separated
# numeric components (missing components are treated as 0, so that "1.1" and
# "1.1.0" compare as equal).

package App::PTP::Util::Semver;

use 5.022;
use strict;
use warnings;

our $VERSION = '0.01';

# Parses a version string into a hash ref with the following keys:
#  - prefix: the optional path-like prefix (the empty string when there is none);
#  - core: an array ref of the dot-separated components of the version core;
#  - pre: an array ref of the dot-separated pre-release identifiers, or undef
#    when there is no pre-release part;
#  - warnings: an array ref of messages describing the edge cases hit while
#    parsing (currently, core components that are not numeric).
# The build metadata (anything after a '+') is dropped as it does not affect
# precedence.
sub parse {
  my ($version) = @_;
  my $original = $version;
  my @warnings;
  $version =~ s/\+.*//s;
  my $prefix = $version =~ s{^([^./]+)/}{} ? $1 : '';
  $version =~ s/^v//i;
  my ($core, $pre) = split /-/, $version, 2;
  my @core = split /\./, $core // '';

  for my $component (@core) {
    push @warnings,
        "version '${original}' has a non-numeric component '${component}' that is treated as 0"
        if $component !~ /^[0-9]+$/;
  }
  return {
    prefix => $prefix,
    core => \@core,
    pre => defined $pre ? [split /\./, $pre] : undef,
    warnings => \@warnings,
  };
}

# Compares the numeric cores of two versions (two array refs), padding the
# shorter one with zeros. Returns a negative, zero or positive number.
sub _compare_core {
  my ($first, $other) = @_;
  no warnings 'numeric';  ## no critic (ProhibitNoWarnings)
  my $count = @$first > @$other ? @$first : @$other;
  for my $i (0 .. $count - 1) {
    my $result = ($first->[$i] // 0) <=> ($other->[$i] // 0);
    return $result if $result;
  }
  return 0;
}

# Compares the pre-release parts of two versions (two array refs of
# identifiers), field by field. Numeric identifiers are compared numerically and
# have lower precedence than alphanumeric ones, which are compared as strings.
# When all the shared fields are equal, the longer list has higher precedence.
sub _compare_pre_release {
  my ($first, $other) = @_;
  my $count = @$first < @$other ? @$first : @$other;
  for my $i (0 .. $count - 1) {
    my ($x, $y) = ($first->[$i], $other->[$i]);
    my ($x_numeric, $y_numeric) = ($x =~ /^[0-9]+$/, $y =~ /^[0-9]+$/);
    my $result =
          $x_numeric && $y_numeric ? $x <=> $y
        : $x_numeric ? -1
        : $y_numeric ? 1
        : $x cmp $y;
    return $result if $result;
  }
  return @$first <=> @$other;
}

# Compares two parsed versions (as returned by parse), returning a negative,
# zero or positive number when the first one sorts respectively before, at the
# same place as, or after the second one. The prefixes are compared as strings
# first, then the numeric cores, and finally the pre-release parts: a version
# with a pre-release part sorts before the same version without one (e.g.
# "1.0.0-alpha" before "1.0.0").
sub compare_parsed {
  my ($first, $other) = @_;
  my $result = $first->{prefix} cmp $other->{prefix};
  return $result if $result;
  $result = _compare_core($first->{core}, $other->{core});
  return $result if $result;
  return 0 if !defined $first->{pre} && !defined $other->{pre};
  return -1 if defined $first->{pre} && !defined $other->{pre};
  return 1 if !defined $first->{pre} && defined $other->{pre};
  return _compare_pre_release($first->{pre}, $other->{pre});
}

# Compares two version strings, parsing them with parse and comparing them with
# compare_parsed. Any parsing warning is silently ignored; callers that need to
# report them should use parse directly.
sub compare {
  my ($first, $other) = @_;
  return compare_parsed(parse($first), parse($other));
}

1;
