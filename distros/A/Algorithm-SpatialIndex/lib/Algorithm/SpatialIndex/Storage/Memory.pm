package Algorithm::SpatialIndex::Storage::Memory;
use 5.008001;
use strict;
use warnings;
use Carp qw(croak);

use parent 'Algorithm::SpatialIndex::Storage';

use Class::XSAccessor {
  getters => {
    _options => 'options',
  },
};

sub init {
  my $self = shift;
  $self->{nodes} = [];
  $self->{options} = {};
  $self->{buckets} = [];
}

sub fetch_node {
  my $self  = shift;
  my $index = shift;
  my $nodes = $self->{nodes};
  return($index > $#$nodes ? undef : $nodes->[$index]);
}

sub store_node {
  my $self = shift;
  my $node = shift;
  my $nodes = $self->{nodes};
  my $id = $node->id;
  if (not defined $id) {
    $id = $#{$nodes} + 1;
    $node->id($id);
  }
  $nodes->[$id] = $node;
  return $id;
}

sub get_option {
  my $self = shift;
  return $self->_options->{shift()};
}

sub set_option {
  my $self  = shift;
  my $key   = shift;
  my $value = shift;
  $self->_options->{$key} = $value;
}

sub store_bucket {
  my $self   = shift;
  my $bucket = shift;
  $self->{buckets}->[$bucket->node_id] = $bucket;
}

sub fetch_bucket {
  my $self    = shift;
  my $node_id = shift;
  return $self->{buckets}->[$node_id];
}

sub delete_bucket {
  my $self    = shift;
  my $node_id = shift;
  $node_id = $node_id->node_id if ref($node_id);
  my $buckets = $self->{buckets};
  $buckets->[$node_id] = undef;
  pop(@$buckets) while @$buckets and not defined $buckets->[-1];
  return();
}


1;
__END__

=head1 NAME

Algorithm::SpatialIndex::Storage::Memory - In-memory storage backend

=head1 SYNOPSIS

  use Algorithm::SpatialIndex;
  my $idx = Algorithm::SpatialIndex->new(
    storage => 'Memory',
  );

=head1 DESCRIPTION

Inherits from L<Algorithm::SpatialIndex::Storage>.

This storage backend is volatile.

=head1 AUTHOR

Steffen Mueller, E<lt>smueller@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010, 2011 by Steffen Mueller

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
