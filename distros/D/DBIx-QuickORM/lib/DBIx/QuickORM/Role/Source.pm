package DBIx::QuickORM::Role::Source;
use strict;
use warnings;

our $VERSION = '0.000031';

use Role::Tiny;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Role::Source - What a handle reads from.

=head1 DESCRIPTION

A source is what a L<DBIx::QuickORM::Handle> selects from: a table
(L<DBIx::QuickORM::Source::Table>), a query (L<DBIx::QuickORM::Source::Query>),
or tables joined together (L<DBIx::QuickORM::Source::Join>). Most code gets
one from C<< $orm->handle >> and never touches it.

The handle asks a source what to select and has it turn the fetched rows into
results. The SQL builder asks it for the C<FROM> part of a statement. The
Connection asks it which table, if any, its rows belong to and what fields the
names in the SQL stand for.

Rows from a source without a table or without a primary key bypass the lookup
table: they are never canon and cannot be updated, refreshed, or deleted
through the ORM.

=head1 SYNOPSIS

    package My::Source;
    use Object::HashBase qw{<view};
    use Role::Tiny::With qw/with/;
    with 'DBIx::QuickORM::Role::Source';

    sub table          { undef }
    sub pk             { undef }
    sub select_fields  { $_[1] }
    sub field_records  { {} }
    sub query_sql      { () }
    sub from_sql       { my ($self, $dialect) = @_; ($dialect->quote_identifier($self->view), []) }

    sub results {
        my ($self, $orm, $raw, $ingest, @class) = @_;
        ($raw, $orm->_row_builder(undef, @class));
    }

=head1 REQUIRED METHODS

=over 4

=item $name = $source->table

The table the rows belong to, or undef when they belong to none.

=item \@fields = $source->pk

The primary key fields, or undef when there is none.

=item $fields = $source->select_fields($given)

What a select names, for the builder's C<fields> request (see
L<DBIx::QuickORM::Role::SQLBuilder>), given the handle's C<fields>.

C<$given> is undef when the handle has none (the result may be undef too, for
every column), an arrayref of field names (to which a primary key is added),
or a hashref of computed fields, which is used as it is. A table or join
croaks for names it does not have. A query passes them on.

=item \%fields = $source->field_records

The map's field records (see L<DBIx::QuickORM::Map>) by the names the SQL and
the fetched columns use them under, or empty when there are none. They are
used for binding and fetching values by their fields.

The hash may be shared and returned on every call: callers read it and never
change it.

=item ($sql, \@binds) = $source->from_sql($dialect)

What goes after C<FROM>, with its binds as C<[$field, $value]> pairs (the
field undef when there is none).

=item ($sql, \@binds) = $source->query_sql

A complete query to run as it is when the handle adds nothing to it, or an
empty list when the source is not a query.

=item (\@rows, \&build) = $source->results($orm, \@raw, $ingest, @class)

Turns the rows a query fetched (C<\@raw>, hashrefs keyed by column name) into
results: C<\@rows> for the iterator (L<DBIx::QuickORM::Iterator>) and
C<build>, which turns each into what the iterator hands out, or undef to
hand the rows out as they are. C<< $orm->_row_builder >> gives the C<build>
for rows of a table.

Ingesting happens here, at once, through the ORM's Connection
(C<< $orm->connection >>), unless C<$ingest> is false: then rows are kept as
fetched and never enter the lookup table (a C<no_cache> handle's rows).
Building happens as each row is handed out.

C<@class> is the handle's C<row_class> as a one-item list (even undef), or
empty when the handle sets none.

=back

=cut

requires qw/table pk select_fields field_records from_sql query_sql results/;

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
