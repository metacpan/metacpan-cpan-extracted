package DBIO::Firebird::SQLMaker;
# ABSTRACT: Firebird-specific SQL generation for DBIO

use strict;
use warnings;

use base qw( DBIO::SQLMaker );



sub apply_limit {
  my ($self, $sql, $rs_attrs, $rows, $offset) = @_;
  return $self->_FirstSkip($sql, $rs_attrs, $rows, $offset);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Firebird::SQLMaker - Firebird-specific SQL generation for DBIO

=head1 VERSION

version 0.900000

=head1 DESCRIPTION

L<DBIO::SQLMaker> subclass for the Firebird RDBMS. Firebird has no
C<LIMIT>/C<OFFSET> keyword; it slices result sets with C<FIRST n SKIP m>
immediately after C<SELECT>. This class implements that via L</apply_limit>.

Set as the C<sql_maker_class> by L<DBIO::Firebird::Storage::Common>, so both
the L<DBD::Firebird|DBIO::Firebird::Storage> and
L<DBD::InterBase|DBIO::Firebird::Storage::InterBase> variants use it. Not
normally instantiated directly.

=head1 METHODS

=head2 apply_limit

    my $sql = $sqlmaker->apply_limit($sql, $rs_attrs, $rows, $offset);

Emits C<SELECT FIRST ? SKIP ? ...> instead of the default
C<... LIMIT ? OFFSET ?>, which Firebird does not understand. Replaces the
DBIx::Class C<sql_limit_dialect = 'FirstSkip'> string dispatch.

=head1 SEE ALSO

=over

=item * L<DBIO::SQLMaker> - Base SQL generation class

=item * L<DBIO::Firebird::Storage::Common> - Storage base that uses this SQL maker

=item * L<DBIO::Firebird> - Top-level Firebird schema component

=back

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
