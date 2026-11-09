package DBIO::PostgreSQL::Diff::Dependents;
# ABSTRACT: A drop that meets objects outside the model is refused, naming them

use strict;
use warnings;

our $VERSION = '0.900004';



sub _describe {
  my ($dependent) = @_;
  return join ' ', grep { defined && length }
    $dependent->{kind}, $dependent->{name},
    (defined $dependent->{on} ? "on $dependent->{on}" : ());
}

sub refuse {
  my ($class, @items) = @_;
  @items = grep { @{ $_->{dependents} // [] } } @items;
  return unless @items;

  die join "\n",
    ( map {
        my $item = $_;
        ( sprintf('refusing to diff: %s is not in the target and would be dropped, and these objects outside the deploy depend on it:',
            $item->{object}),
          ( map { '  ' . _describe($_) } @{ $item->{dependents} } ),
          '' )
      } @items ),
    'The drop is written without CASCADE, so nothing outside the deploy goes with it.',
    'No statement was generated.',
    '',
    'Change or drop these yourself, or keep the object in the target, and diff again.',
    '';
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::Diff::Dependents - A drop that meets objects outside the model is refused, naming them

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    use DBIO::PostgreSQL::Diff::Dependents ();

    # in the diff method of an operation class, before the drop is built
    DBIO::PostgreSQL::Diff::Dependents->refuse(
      map { {
        object     => "table $_",
        dependents => $outside->{tables}{$_},
      } } @dropped,
    );

=head1 DESCRIPTION

L<DBIO::PostgreSQL::Diff> writes C<DROP TABLE>, C<DROP TYPE> and C<DROP SCHEMA>
without C<CASCADE>. The order of the operations drops what the model holds in
or on the object first (foreign keys, views, indexes, columns, tables,
functions, types); what is left is what the model does not hold, and the
server refuses the drop for it. With C<pg_schemas> the model holds the declared
schemas only, so a materialized view in another schema that reads the table,
a foreign key of another schema's table that points at it, or a column of
another schema's table that is of the type, is outside the model and stands in
the way.

The rule that answers this stands here, once:

B<A drop that would meet an object outside the model is not written.> The
C<outside_dependents> section of the model
(L<DBIO::PostgreSQL::Introspect::OutsideDependents>) names such objects, and
L</refuse> dies with C<refusing to diff: ...>, see
L<DBIO::PostgreSQL::Diff/WHAT IS REFUSED>, naming each object and what depends
on it. The message carries names only. Without the section (a model built by
hand, or one read before it existed) nothing is checked, and C<RESTRICT> is
what stops the statement.

=head1 METHODS

=head2 refuse

    DBIO::PostgreSQL::Diff::Dependents->refuse(
      { object => 'table app.orders', dependents => \@entries }, ...);

Each argument names an object the diff would drop (C<object>, as the message
says it: kind and name) and the entries of the C<outside_dependents> section
for it (C<kind>, C<name> and, for a foreign key, C<on>). Returns when none has a
dependent; otherwise dies with one message for all of them.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
