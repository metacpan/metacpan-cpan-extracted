package DBIO::MySQL::SQLMaker::MariaDB;
# ABSTRACT: SQLMaker subclass for MariaDB's SQL syntax quirks

use strict;
use warnings;

use base 'DBIO::MySQL::SQLMaker';


# Reuse the parent's lock_modifiers (NOWAIT / SKIP LOCKED) but override
# the lock_types mapping: 'share' means LOCK IN SHARE MODE on MariaDB.
my $lock_types = {
  update => 'FOR UPDATE',
  share  => 'LOCK IN SHARE MODE',
};

my $lock_modifiers = {
  nowait      => 'NOWAIT',
  skip_locked => 'SKIP LOCKED',
};

sub _lock_select {
  my ($self, $type) = @_;

  if (ref $type eq 'HASH') {
    my $lock_type = $type->{type};
    my $tables    = $type->{of};
    my $modifier  = $type->{modifier};

    my $lock_clause = $lock_types->{$lock_type}
      || $self->throw_exception("Unknown SELECT .. FOR type '$lock_type' requested");

    if ($tables) {
      my @table_list = ref $tables eq 'ARRAY' ? @$tables : ($tables);
      if (@table_list) {
        my $quoted_tables = join(', ', map { $self->_quote($_) } @table_list);
        $lock_clause .= " OF $quoted_tables";
      }
    }

    if ($modifier) {
      my $mod_sql = $lock_modifiers->{$modifier}
        || $self->throw_exception("Unknown lock modifier '$modifier' requested");
      $lock_clause .= " $mod_sql";
    }

    return " $lock_clause";
  }

  my $sql = $lock_types->{$type}
    || $self->throw_exception("Unknown SELECT .. FOR type '$type' requested");
  return " $sql";
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::SQLMaker::MariaDB - SQLMaker subclass for MariaDB's SQL syntax quirks

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

C<DBIO::MySQL::SQLMaker::MariaDB> is a SQLMaker subclass for MariaDB.
It is used automatically by L<DBIO::MySQL::Storage::MariaDB>.

MariaDB's locking syntax differs from MySQL 8.0+: it only supports
C<LOCK IN SHARE MODE>, not C<FOR SHARE>. This subclass overrides
C<_lock_select> so that C<< for =E<gt> 'share' >> emits
C<LOCK IN SHARE MODE> when talking to MariaDB, while still accepting
the same DSL the MySQL parent uses.

=seealso

=over 4

=item * L<DBIO::MySQL::SQLMaker> - MySQL parent class

=item * L<DBIO::MySQL::Storage::MariaDB> - consumer of this SQLMaker

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
