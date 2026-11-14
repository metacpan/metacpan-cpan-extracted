package DBIO::Replicated::Balancer::First;
# ABSTRACT: Always use the first active replicant

use strict;
use warnings;

our $VERSION = '0.900005';

use base 'DBIO::Replicated::Balancer';


sub next_storage {
  return (shift->pool->active_replicants)[0];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Replicated::Balancer::First - Always use the first active replicant

=head1 VERSION

version 0.900005

=head1 METHODS

=head2 next_storage

Returns the first of the pool's active replicants, or nothing if there is
none (the caller then falls back to the master).

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
