package DBIx::QuickORM::Dialect::DuckDB;
use strict;
use warnings;

our $VERSION = '0.000031';

use parent 'DBIx::QuickORM::Dialect';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::DuckDB - DuckDB dialect.

=head1 DESCRIPTION

DuckDB through L<DBD::DuckDB>. It keeps the base defaults of
L<DBIx::QuickORM::Dialect>, but has no savepoints (so transactions cannot
nest), allows no second connection, and classifies errors by message. The
namespace is C<current_schema()>.

DBD::DuckDB exchanges bytes, so this dialect decodes fetched text and
upgrades text it sends.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect->for_dbh($dbh);    # this class for DBD::DuckDB

=head1 PUBLIC METHODS

=over 4

=item $bool = $dialect->supports_savepoints

False.

=item $bool = $dialect->supports_second_connection($dbh)

False: DuckDB holds an exclusive lock on its database file, and an in-memory
database belongs to its one connection.

=item $n = $dialect->bind_limit

7000.

DuckDB sets no limit, but bulk inserts measured about 30% slower at 65535
binds a statement than at 3,000 to 7,000.

=back

=cut

sub supports_savepoints        { 0 }
sub supports_second_connection { 0 }
sub bind_limit                 { 7000 }

=pod

=over 4

=item $dialect->init_session($dbh, $time_zone)

C<SET TimeZone>. DuckDB's sessions are UTF-8 already. The text conversion is
done by C<text_from_db> and C<text_to_db>.

=back

=cut

sub init_session {
    my $self = shift;
    my ($dbh, $time_zone) = @_;
    return $dbh->do('SET TimeZone = ' . $dbh->quote($time_zone));
}

=pod

=over 4

=item $dialect->text_from_db(@values)

Decodes each value holding non-ASCII bytes from UTF-8, in place. DBD::DuckDB
returns text as bytes.

=back

=cut

sub text_from_db {
    my $self = shift;
    for (@_) { utf8::decode($_) if defined($_) && !ref($_) && m/[^\x00-\x7F]/ }
    return;
}

=pod

=over 4

=item $dialect->text_to_db(@values)

Upgrades each value holding non-ASCII characters in place, so its bytes are
UTF-8.

DBD::DuckDB sends a string's internal bytes as they are, which for a Latin-1
string that was never upgraded are not UTF-8.

=back

=cut

sub text_to_db {
    my $self = shift;
    for (@_) { utf8::upgrade($_) if defined($_) && !ref($_) && m/[^\x00-\x7F]/ }
    return;
}

=pod

=over 4

=item $kind = $dialect->error_kind($native, $state, $errstr)

The kind from the error text, since DBD::DuckDB reports the same code and
SQLSTATE for every error.

C<Constraint Error> messages give the constraint kinds, and a
C<TransactionContext Error> naming a conflict gives
C<serialization_failure>. Anything else is undef.

=back

=cut

my @MESSAGE_KIND = (
    [qr/Constraint Error: Duplicate key .* violates (?:primary key|unique) constraint/ => 'unique_violation'],
    [qr/Constraint Error: PRIMARY KEY or UNIQUE constraint violation/                  => 'unique_violation'],
    [qr/Constraint Error: Violates foreign key constraint/                             => 'foreign_key_violation'],
    [qr/Constraint Error: NOT NULL constraint failed/                                  => 'not_null_violation'],
    [qr/Constraint Error: CHECK constraint failed/                                     => 'check_violation'],
    [qr/TransactionContext Error: .*\bconflict\b/i                                     => 'serialization_failure'],
);

sub error_kind {
    my $self = shift;
    my (undef, undef, $errstr) = @_;
    return undef unless defined $errstr;

    for my $pair (@MESSAGE_KIND) {
        return $pair->[1] if $errstr =~ $pair->[0];
    }

    return undef;
}

=pod

=over 4

=item $sql = $dialect->tables_sql

=item $sql = $dialect->fields_sql

=item $sql = $dialect->pk_sql

=item $sql = $dialect->unique_sql

=item $sql = $dialect->fk_sql

The scan queries (see L<C<scan>|DBIx::QuickORM::Dialect/"PUBLIC METHODS">),
over C<duckdb_tables()>, C<duckdb_columns()>, and C<duckdb_constraints()> in
C<current_database()> and C<current_schema()>.

A column the database fills has a default, such as C<nextval('seq')>.
No column is marked as refusing values: the catalog does not mark generated
columns, and DuckDB allows no key on one.

Unique keys come from C<UNIQUE> constraints and from unique indexes (see
C<_unique_rows>).

=back

=cut

my $IN_SCHEMA = <<'EOT';
         WHERE database_name = current_database()
           AND schema_name   = current_schema()
EOT

sub tables_sql {
    return <<"    EOT";
        SELECT table_name
          FROM duckdb_tables()
$IN_SCHEMA
           AND NOT internal
           AND NOT temporary
    EOT
}

sub fields_sql {
    return <<"    EOT";
        SELECT table_name, column_name, data_type, NULL,
               CASE WHEN upper(column_default) <> 'NULL' THEN 1 END,
               NULL
          FROM duckdb_columns()
$IN_SCHEMA
    EOT
}

sub pk_sql {
    return <<"    EOT";
        SELECT table_name, unnest(constraint_column_names)
          FROM duckdb_constraints()
$IN_SCHEMA
           AND constraint_type = 'PRIMARY KEY'
    EOT
}

sub unique_sql {
    return <<"    EOT";
        SELECT table_name, constraint_index, unnest(constraint_column_names)
          FROM duckdb_constraints()
$IN_SCHEMA
           AND constraint_type = 'UNIQUE'
    EOT
}

=pod

=over 4

=item $sql = $dialect->unique_index_sql

The C<(table, index, expressions)> rows of the unique indexes, from
C<duckdb_indexes()>.

=back

=cut

sub unique_index_sql {
    return <<"    EOT";
        SELECT table_name, index_name, expressions
          FROM duckdb_indexes()
$IN_SCHEMA
           AND is_unique
    EOT
}

sub fk_sql {
    return <<"    EOT";
        SELECT table_name, constraint_index, unnest(constraint_column_names), referenced_table, unnest(referenced_column_names)
          FROM duckdb_constraints()
$IN_SCHEMA
           AND constraint_type = 'FOREIGN KEY'
    EOT
}

=head1 PRIVATE METHODS

=over 4

=item \@rows = $dialect->_unique_rows($dbh)

The unique constraints' rows, then a C<(table, "index $name", field)> row for
each field of each unique index.

DuckDB reports an index's fields as a string such as C<[b, a]>, quoting a
name that needs it (C<['"we ird"']>). Only a plain list of such names is
read. Anything else, such as an expression (C<['(lower(c))']>), gives one
undef field, so the scan leaves the index out.

=back

=cut

# A bracketed list of bare names, or names in '"..."' holding no quote or comma.
my $INDEX_FIELDS = qr/^\[((?:\w+|'"[^"',]+"')(?:, (?:\w+|'"[^"',]+"'))*)\]\z/;

sub _unique_rows {
    my $self = shift;
    my ($dbh) = @_;

    my @rows = @{$self->SUPER::_unique_rows($dbh)};
    for my $index (@{$self->_rows($dbh, $self->unique_index_sql)}) {
        my ($table, $name, $expressions) = @$index;
        my @fields = $expressions =~ $INDEX_FIELDS ? map { s/^'"(.*)"'\z/$1/r } split /, / => $1 : (undef);
        push @rows => map { [$table, "index $name", $_] } @fields;
    }

    return \@rows;
}

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
