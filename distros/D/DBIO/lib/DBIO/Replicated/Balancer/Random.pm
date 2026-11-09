package DBIO::Replicated::Balancer::Random;
# ABSTRACT: Randomly choose an active replicant

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Replicated::Balancer';

__PACKAGE__->mk_group_accessors(simple => 'master_read_weight');


sub new {
  my ($class, %args) = @_;
  my $self = $class->SUPER::new(%args);
  $self->master_read_weight(exists $args{master_read_weight} ? $args{master_read_weight} : 0);
  return $self;
}


sub next_storage {
  my $self = shift;

  my @replicants = $self->pool->active_replicants;
  return if not @replicants;

  my $rnd = $self->_random_number(@replicants + $self->master_read_weight);
  return $rnd >= @replicants ? $self->master : $replicants[int $rnd];
}

sub _random_number {
  rand($_[1]);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Balancer::Random - Randomly choose an active replicant

=head1 VERSION

version 0.900004

=head1 METHODS

=head2 new

Same as L<DBIO::Replicated::Balancer/new>, plus C<master_read_weight>
(default 0), which is also available as a read/write accessor.

=head2 next_storage

Returns nothing if there are no active replicants. Otherwise draws a random
number in C<< [0, replicants + master_read_weight) >>: values below the
replicant count pick that replicant, the rest pick the master. With the
default weight 0 the master is never picked while a replicant is active;
a weight of 1 gives the master the same share as one replicant.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
