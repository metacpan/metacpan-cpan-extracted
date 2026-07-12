package DBIO::Oracle::Storage::Savepoints;
# ABSTRACT: Savepoint management for Oracle

use strict;
use warnings;




sub _exec_svp_begin {
  my ($self, $name) = @_;
  $self->_dbh->do("SAVEPOINT $name");
}

# Oracle auto-releases savepoint on same-name reuse; no-op is correct
sub _exec_svp_release { 1 }

sub _exec_svp_rollback {
  my ($self, $name) = @_;
  $self->_dbh->do("ROLLBACK TO SAVEPOINT $name");
}

# DBD::Oracle warns loudly on partial execute_for_fetch failures
sub _dbh_execute_for_fetch {
  local $_[1]->{PrintWarn} = 0;
  shift->next::method(@_);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Oracle::Storage::Savepoints - Savepoint management for Oracle

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

Oracle savepoint operations and DBD::Oracle quirks. Oracle automatically
releases a savepoint when you start another one with the same name, so
L</_exec_svp_release> is a no-op.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
