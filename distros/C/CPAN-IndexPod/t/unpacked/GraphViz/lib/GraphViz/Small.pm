package GraphViz::Small;

use strict;
use GraphViz;
use vars qw($VERSION @ISA);

# This is incremented every time there is a change to the API
$VERSION = '0.01';

@ISA = qw(GraphViz);

=head1 NAME

GraphViz::Small - subclass of GraphViz with small nodes

=head1 SYNOPSIS

  use GraphViz::Small;

  my $g = GraphViz::Small->new();
  # methods as for GraphViz

=head1 DESCRIPTION

Graphs produced by GraphViz are occasionally huge, making it hard to
observe the structure. This subclass simply makes the nodes small and
empty, allowing the structure to stand out.

=head1 METHODS

As for GraphViz.

=cut

sub add_node_munge {
  my $self = shift;
  my $node = shift;

  $node->{label} = '';
  $node->{height} = 0.2;
  $node->{width} = 0.2;
  $node->{style} = 'filled';
  $node->{color} = 'black' unless $node->{color};
}

=head1 AUTHOR

Leon Brocard E<lt>F<acme@astray.com>E<gt>

=head1 COPYRIGHT

Copyright (C) 2000-1, Leon Brocard

This module is free software; you can redistribute it or modify it
under the same terms as Perl itself.

=cut

1;
