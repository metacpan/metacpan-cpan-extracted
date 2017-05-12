package Algorithm::Interval2Prefix;
use strict;

use vars qw($VERSION @ISA @EXPORT);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(interval2prefix interval2regex);

$VERSION = '0.02';

my %Step;  # cache

sub _step {
  my($i, $base) = @_;
  return $Step{$base}[$i] if exists $Step{$base}[$i];
  $Step{$base}[0] = 1;  # n**0 == 1
  return $Step{$base}[$i] = $Step{$base}[$i-1] * $base;
}

sub _i2a {
  my($lo, $hi, $base, $render) = @_;
  my @res;
  while ($lo <= $hi) {
    my $i = 0;
    while (($lo % _step($i+1, $base) == 0) and
          (($lo + _step($i+1, $base) - 1 <= $hi))) {
      $i++;
    }
    push @res, $render->($lo, $i, $base);
    $lo += _step($i, $base);
  }
  return @res;
}

sub interval2prefix {
  my($lo, $hi, $base) = @_;
  return _i2a($lo, $hi, $base || 10,
              sub {
                my($n, $i, $base)= @_;
                return $n / _step($i, $base);
              });
}

sub interval2regex {
  my($lo, $hi) = @_;
  my @res = _i2a($lo, $hi, 10,
                 sub {
                   my($n, $i, $base)= @_;
                   my $p = $n / _step($i, $base);
                   my $s = length($n) - length($p);
                   return $p . ($s ? '\d' . ($s > 1 ? "{$s}" : '') : '');
                 });
  return unless @res;
  return '^(?:' . join('|', @res) . ')$';
}

1;

=head1 NAME

Algorithm::Interval2Prefix - Generate prefixes from intervals

=head1 SYNOPSIS

  use Algorithm::Interval2Prefix;

  my @prefixes = interval2prefix('33400','33599');
  print join(',', @prefixes);  # prints "334,335"

  my $regex = interval2regex('33400','33599');
  if ($n =~ /$regex/) { ... }

=head1 DESCRIPTION

Taking an interval as input, this module will construct the smallest
set of prefixes, such that all numbers in the interval will match
exactly one of the prefixes, and no prefix will match a number not in
the interval.

E.g. all numbers in the interval 39967000 to 39980999 would be matched
by the following set of prefixes:

  39967
  39968
  39969
  3997
  39980

This type of conversion is particularly useful when working with
telephony switching equipment, which usually determines call routing
based on number prefixes rather than ranges.

Note that the numbers in the interval must be of the same length
for the result to make sense.

The algorithm is much dependent on the number base, which defaults to
10. Other number bases can be specified explicitly.

An additional function is provided, that will generate a regular
expression string matching B<only> those numbers in the interval.

=head1 FUNCTIONS

=over 4

=item interval2prefix LO,HI,BASE

=item interval2prefix LO,HI

Yields an array of prefixes, covering the interval LO to HI,
using number base BASE.

BASE is optional, and defaults to 10.

=item interval2regex LO,HI

Yields a regular expression string, which will match B<only> those
numbers in the interval.

This function assumes base 10.

=back

=head1 EXPORT

Both interval2prefix() and interval2regex() are exported by default.

=head1 BUGS/TODO

=over 4

=item *

With interval2prefix(), the endpoints of the interval must be the
same length (same number of digits in the particular number base)
for the results to make any sense.

=item *

interval2regex() only does base 10.

=back

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Algorithm-Interval2Prefix

or by sending mail to

  bug-Algorithm-Interval2Prefix@rt.cpan.org

=head1 AUTHOR

Lars Thegler <lars@thegler.dk>

=head1 COPYRIGHT

Copyright (c) 2003 Lars Thegler. All rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
