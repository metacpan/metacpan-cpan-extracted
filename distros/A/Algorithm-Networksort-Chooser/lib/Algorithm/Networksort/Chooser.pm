package Algorithm::Networksort::Chooser;

our $VERSION = '0.110';

use common::sense;

use Math::Combinatorics;




sub silence_carps {
  local *Algorithm::Networksort::carp = sub {};

  shift->();
}


sub build_selection_network {
  my ($network, $selection) = @_;

  my $pinned = {};
  $pinned->{$_} = 1 foreach (@$selection);

  my @reversed_network = reverse @$network;
  my @reversed_output;

  foreach my $comparator (@reversed_network) {
    if ($pinned->{$comparator->[0]} || $pinned->{$comparator->[1]}) {
      $pinned->{$comparator->[0]} = $pinned->{$comparator->[1]} = 1;

      push @reversed_output, $comparator;
    }
  }

  return [ reverse @reversed_output ];
}



sub average_swaps_zero_one {
  my ($n, $network) = @_;

  my $sum = 0;
  my $count = 0;

  for my $i (0 .. (2**$n - 1)) {
    my $p = [ split //, sprintf("%0${n}b", $i) ];
    $count++;
    Algorithm::Networksort::nw_sort($network, $p);
    my %stats = Algorithm::Networksort::nw_sort_stats();
    $sum += $stats{swaps};
  }

  return $sum / $count;
}


sub average_swaps_permutation {
  my ($n, $network) = @_;

  my $sum = 0;
  my $count = 0;

  for my $p (Math::Combinatorics::permute(0 .. ($n-1))) {
    $count++;
    Algorithm::Networksort::nw_sort($network, $p);
    my %stats = Algorithm::Networksort::nw_sort_stats();
    $sum += $stats{swaps};
  }

  return $sum / $count;
}


1;




=encoding utf-8

=head1 NAME

Algorithm::Networksort::Chooser - Helper utility for Algorithm::Networksort

=head1 DESCRIPTION

This module contains library routines used by the L<algorithm-networksort-chooser> command-line script.

=head1 SEE ALSO

L<Algorithm-Networksort-Chooser github repo|https://github.com/hoytech/Algorithm-Networksort-Chooser>

=head1 AUTHOR

Doug Hoyte, C<< <doug@hcsw.org> >>

=head1 COPYRIGHT & LICENSE

Copyright 2013-2016 Doug Hoyte.

This module is licensed under the same terms as perl itself.
