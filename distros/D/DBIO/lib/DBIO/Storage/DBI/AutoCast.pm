package DBIO::Storage::DBI::AutoCast;
# ABSTRACT: Storage component for RDBMS requiring explicit placeholder typing

use strict;
use warnings;

use base qw/DBIO::Storage::DBI/;
use mro 'c3';

__PACKAGE__->mk_group_accessors('simple' => 'auto_cast' );



sub _prep_for_execute {
  my $self = shift;

  my ($sql, $bind) = $self->next::method (@_);

# If we're using ::NoBindVars, there are no binds by this point so this code
# gets skipped.
  if ($self->auto_cast && @$bind) {
    my $new_sql;
    my @sql_part = split /\?/, $sql, scalar @$bind + 1;
    for (@$bind) {
      my $cast_type = $self->_native_data_type($_->[0]{sqlt_datatype});
      $new_sql .= shift(@sql_part) . ($cast_type ? "CAST(? AS $cast_type)" : '?');
    }
    $sql = $new_sql . shift @sql_part;
  }

  return ($sql, $bind);
}


sub connect_call_set_auto_cast {
  my $self = shift;
  $self->auto_cast(1);
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::DBI::AutoCast - Storage component for RDBMS requiring explicit placeholder typing

=head1 VERSION

version 0.900000

=head1 SYNOPSIS

  $schema->storage->auto_cast(1);

=head1 DESCRIPTION

In some combinations of RDBMS and DBD drivers (e.g. FreeTDS and Sybase)
statements with values bound to columns or conditions that are not strings will
throw implicit type conversion errors.

As long as a column L<data_type|DBIO::ResultSource/add_columns> is
defined and resolves to a base RDBMS native type via
L<_native_data_type|DBIO::Storage::DBI/_native_data_type> as
defined in your Storage driver, the placeholder for this column will be
converted to:

  CAST(? as $mapped_type)

This option can also be enabled in
L<connect_info|DBIO::Storage::DBI/connect_info> as:

  on_connect_call => ['set_auto_cast']

=head1 ATTRIBUTES

=head2 auto_cast

Boolean toggle enabling automatic C<CAST(? AS ...)> placeholder rewriting.

=head1 METHODS

=head2 _prep_for_execute

Rewrite C<?> placeholders as C<CAST(? AS $type)> when L</auto_cast> is
enabled and the bind's C<sqlt_datatype> resolves to a native type.

=head2 connect_call_set_auto_cast

Executes:

  $schema->storage->auto_cast(1);

on connection.

Used as:

    on_connect_call => ['set_auto_cast']

in L<connect_info|DBIO::Storage::DBI/connect_info>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
