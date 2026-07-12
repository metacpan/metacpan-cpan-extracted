package DBIO::Oracle::Storage::FKDeferral;
# ABSTRACT: FK constraint deferral for Oracle

use strict;
use warnings;

use Scope::Guard ();
use Context::Preserve 'preserve_context';



sub with_deferred_fk_checks {
  my ($self, $sub) = @_;

  my $txn_scope_guard = $self->txn_scope_guard;

  $self->_do_query('alter session set constraints = deferred');

  my $sg = Scope::Guard->new(sub {
    $self->_do_query('alter session set constraints = immediate');
  });

  return preserve_context { $sub->() } after => sub { $txn_scope_guard->commit };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage::FKDeferral - FK constraint deferral for Oracle

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Runs a coderef between C<ALTER SESSION SET CONSTRAINTS = DEFERRED> and
C<ALTER SESSION SET CONSTRAINTS = IMMEDIATE> to defer foreign key checks.
Constraints must be declared C<DEFERRABLE> for this to work.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
