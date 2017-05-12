package Array::Extract;
use base qw(Exporter);

use 5.006;

use strict;
use warnings;

our @EXPORT_OK;
our $VERSION = "1.00";

=head1 NAME

Array::Extract - extract element from an array

=head1 SYNOPSIS

  use Array::Extract qw(extract);

  # remove those members from @members who are
  # blackballed and store them in @banned
  my @banned = extract { $_->blackballed } @members;

=head1 DESCRIPTION

Function to extract elements from an array that match
a block.  See L<Array::Extract::Example> for a
more comprehensive example of how this can be useful

=head2 Function

The function is exported on demand

=over

=item extract BLOCK ARRAY

Removes elements from the ARRAY that match the
block and returns them.

  # leave just the even numbers in @numbers
  my @numbers = (1..100);
  my @odds = extract { $_ % 2 } @numbers;

Care is taken to do the least number of splice
operations as possible (which can be important when
the array is a tied object with a class such as
Tie::File)

=cut

sub extract(&\@) {
  my $block = shift;
  my $array = shift;

  # loop invariants.  The element we're currently on
  # and the length of the array
  my $i = 0;
  my $length = @{ $array };

  # the index we started removing from
  my $remove_from;

  # what we've collected to return
  my @return;

  # for each element of the array
  while ($i < $length) {
    local $_ = $array->[ $i ];
    if (!$block->()) {
      # this content we keep
      if (defined $remove_from) {
        # but first we need to remove the stuff we wanted
        # to extract from the list
        my $number = $i - $remove_from;
        $i -= $number;
        $length -= $number;
        splice @{$array}, $remove_from, $number;
        undef $remove_from;
      }
    } else {
      # remember we're going to remove this content
      $remove_from = $i
        unless defined $remove_from;

      # remember the content we were going to keep
      push @return, $_;
    }
    $i++;
  }

  # remove any thing at the end of the list that we were still removing
  splice @{$array}, $remove_from, $i - $remove_from if defined $remove_from;
  return @return;
}
push @EXPORT_OK, "extract";

=back

=head1 AUTHOR

Written by Mark Fowler <mark@twoshortplanks.com>

=head1 COPYRIGHT

Copyright Mark Fowler 2011.  All Rights Reserved.

This program is free software; you can redistribute it
and/or modify it under the same terms as Perl itself.

=head1 BUGS

This module (deliberately) does not alias C<$_> to the
actual array element within the block

Bugs should be reported via this distribution's
CPAN RT queue.  This can be found at
L<https://rt.cpan.org/Dist/Display.html?Array-Extract>

You can also address issues by forking this distribution
on github and sending pull requests.  It can be found at
L<http://github.com/2shortplanks/Array-Extract>

=head1 SEE ALSO

L<Array::Extract::Example> L<List::Util>, L<List::MoreUtils>, L<Tie::File>

=cut

1;