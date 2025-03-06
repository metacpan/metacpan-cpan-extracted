package Array::Intersection;
use strict;
use warnings;
use List::MoreUtils qw{uniq};
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(intersection);

our $VERSION = '0.03';
our $UNDEF   = "\000\001\002 QXJyYXk6OkludGVyc2VjdGlvbiBDb3B5cmlnaHQgKEMpIDIwMjQgYnkgTWljaGFlbCBSLiBEYXZpcw== \002\001\000"; #hash keys cannot be undef()

=head1 NAME

Array::Intersection - Calculates the intersection of two array references

=head1 SYNOPSIS

  use Array::Intersection;
  my @intersection = intersection([1,2,3,4], [3,4,5,6]); #expect (3,4)

=head1 DESCRIPTION

This package exports the intersection() function which uses the magic of a hash slice to return an intersection of the data.

=head2 LIMITATIONS

Hash keys are strings so numeric data like 1 and 1.0 will be uniqued away in the string folding process. However, the function folds undef into a unique string so that it supports both empty string "" and undef.

=head2 FUNCTIONS

=head2 intersection

This intersection function uses a hash slice method to determine the intersection between the first array reference and the second array reference.

  my @intersection = intersection([1,2,3,4], [3,4,5,6]); #expect (3,4)
  my @intersection = intersection(\@array_1, \@array_2);

=cut

sub intersection {
  my $syntax       = 'Syntax: my @output = intersection(\@array1, \@array2)';
  my $aref1        = shift or die($syntax);
  my $aref2        = shift or die($syntax);
  my %hash1        =      map {defined ? ($_ => $_) : ($UNDEF => $UNDEF)} @$aref1;  #fold undef into string, copy keys to values, and unique based on hash assignment
  my @uniq2        = uniq map {defined ?  $_        :  $UNDEF           } @$aref2;  #fold undef into string, and uniq to perserve order of second array
  my @intersection = map {$_ eq $UNDEF ? undef : $_} grep {defined} @hash1{@uniq2}; #hash slice for values, remove undef values where not exists, revert undef keys from sting
  return @intersection;
}

=head1 SEE ALSO

https://perldoc.perl.org/perlfaq4#How-do-I-compute-the-difference-of-two-arrays?-How-do-I-compute-the-intersection-of-two-arrays?
L<List::MoreUtils>

=head1 AUTHOR

Michael R. Davis

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2024 by Michael R. Davis

MIT

=cut

1;
