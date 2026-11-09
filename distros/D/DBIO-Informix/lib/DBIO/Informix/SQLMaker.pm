package DBIO::Informix::SQLMaker;
# ABSTRACT: Informix-specific SQL generation for DBIO

use warnings;
use strict;

our $VERSION = '0.900004';

use base qw( DBIO::SQLMaker );


#
# Informix does not understand SELECT ... FOR UPDATE
# Disable it here
sub _lock_select () { '' };


sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_SkipFirst($sql, $rs_attrs, $rows, $offset);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Informix::SQLMaker - Informix-specific SQL generation for DBIO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Informix-specific subclass of L<DBIO::SQLMaker>. Disables C<SELECT ... FOR UPDATE>
locking syntax, which Informix does not support, and slices result sets with
C<SELECT SKIP ? FIRST ?> via L</apply_limit>. All other SQL generation is
inherited from L<DBIO::SQLMaker>.

This class is set as the C<sql_maker_class> by L<DBIO::Informix::Storage> and
is not normally instantiated directly.

=head1 METHODS

=head2 apply_limit

    my $sql = $sqlmaker->apply_limit($sql, $rs_attrs, $rows, $offset);

Emits C<SELECT SKIP ? FIRST ? ...> instead of the default
C<... LIMIT ? OFFSET ?>, which Informix does not understand. Replaces the
DBIx::Class C<sql_limit_dialect = 'SkipFirst'> string dispatch.

=head1 SEE ALSO

=over

=item * L<DBIO::SQLMaker> - Base SQL generation class

=item * L<DBIO::Informix::Storage> - Storage driver that uses this SQL maker

=item * L<DBIO::Informix> - Top-level Informix schema component

=back

=cut

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
