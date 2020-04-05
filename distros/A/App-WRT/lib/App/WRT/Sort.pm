package App::WRT::Sort;

use strict;
use warnings;
use 5.10.0;

use Carp;

use base qw(Exporter);
our @EXPORT_OK = qw(sort_entries);

=pod

=head1 NAME

App::WRT::Sort - functions for sorting wrt entry lists

=head1 SYNOPSIS

    use App::WRT::Sort qw(sort_entries);
    my (@sorted) = sort_entries(@unsorted);

=head1 DESCRIPTION

This makes an effort to sort a list of entries, which may include both simple
dates and names, or a combination thereof, reasonably.

The main goal is to have dates sorted in order, followed by alphanumeric names.

=head1 FUNCTIONS

=over

=item sort_entries(@entries)

Sort a list of entries by converting them to an array with an easily sortable
string format as the second value, sorting these arrayrefs by that value, and
then re-mapping them to the original values.

See here: L<https://en.wikipedia.org/wiki/Schwartzian_transform>

=cut

sub sort_entries {
  my (@entries) = @_;
  return map  { $_->[0] }
         sort { $a->[1] cmp $b->[1] }
         map  { [$_, sortable_from_entry($_)] }
         @entries;
}

=item sortable_from_entry($entry)

Get a sortable string value that does (more or less) what we want.

In this case, it pads numeric components of the path out to 5 leading 0s and
leaves everything else alone.

=cut

sub sortable_from_entry {
  my ($entry) = @_;

  my @parts = map {

    my $padded;
    if (m/^\d+$/) {
      # There's a year 100k bug here, but I guess I'll cross that bridge when I
      # come to it:
      $padded = sprintf("%05d", $_);
    } else {
      $padded = $_;
    }
    $padded;

  } split '/', $entry;

  return join '', @parts;
}

=back

=cut

1;
