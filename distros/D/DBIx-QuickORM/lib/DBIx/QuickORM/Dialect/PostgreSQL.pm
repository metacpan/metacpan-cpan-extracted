package DBIx::QuickORM::Dialect::PostgreSQL;
use strict;
use warnings;

our $VERSION = '0.000031';

use parent 'DBIx::QuickORM::Dialect';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::PostgreSQL - PostgreSQL dialect.

=head1 DESCRIPTION

PostgreSQL through L<DBD::Pg>. It keeps the base defaults of
L<DBIx::QuickORM::Dialect> and adds a 65535 bind limit, async queries, and
C<bytea> binding. The namespace is C<current_schema()>.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect->for_dbh($dbh);    # this class for DBD::Pg

=head1 PUBLIC METHODS

=over 4

=item $n = $dialect->bind_limit

65535, the most parameters the wire protocol can number in one statement.

=item $bool = $dialect->supports_isolation

True.

=item @sql = $dialect->begin_sql($level)

C<BEGIN ISOLATION LEVEL $level> when given a level, otherwise C<BEGIN>.

=item $bool = $dialect->supports_async

True.

=item $attrs = $dialect->async_prepare_attrs

C<< {pg_async => PG_ASYNC} >>.

Each async statement is prepared fresh and executed once: DBD::Pg 3.21.2 can
skip the execute of a re-executed server-prepared async statement, losing its
rows (L<https://github.com/bucardo/dbdpg/issues/217>).

=item $bool = $dialect->async_ready($dbh, $sth)

=item $dialect->async_result($dbh, $sth)

=item $dialect->cancel_async($dbh, $sth)

C<pg_ready>, C<pg_result>, and C<pg_cancel> on the database handle.

Cancelling a query inside a transaction makes PostgreSQL abort that
transaction.

=back

=cut

sub supports_isolation  { 1 }
sub begin_sql           { $_[1] ? ("BEGIN ISOLATION LEVEL $_[1]") : ('BEGIN') }
sub bind_limit          { 65535 }
sub supports_async      { 1 }
sub async_prepare_attrs { {pg_async => DBD::Pg::PG_ASYNC()} }
sub async_ready         { $_[1]->pg_ready }
sub async_result        { $_[1]->pg_result }
sub cancel_async        { $_[1]->pg_cancel }

=pod

=over 4

=item $attrs = $dialect->binary_bind_attrs

C<< {pg_type => PG_BYTEA} >>.

=back

=cut

sub binary_bind_attrs {
    require DBD::Pg;
    return {pg_type => DBD::Pg::PG_BYTEA()};
}

=pod

=over 4

=item $dialect->release_inherited($dbh)

Points the child's copy of the handle's socket at F</dev/null> when the handle
is active, then sets C<InactiveDestroy>.

DBD::Pg can still read the socket from a child: freeing a handle with an
async query pending, in the wrong order at exit, waits for the query's
result, taking it from the parent.

=back

=cut

sub release_inherited {
    my $self = shift;
    my ($dbh) = @_;
    $self->_null_socket($dbh->{pg_socket}) if $dbh->{Active};
    return $self->SUPER::release_inherited($dbh);
}

=pod

=over 4

=item $dialect->init_session($dbh, $time_zone)

Sets C<client_encoding> to C<UTF8> and turns on C<pg_enable_utf8>, then
C<SET TIME ZONE> and C<DateStyle> C<ISO, YMD>, so dates and times come back in
the form L<DateTime::Format::Pg> reads.

=back

=cut

sub init_session {
    my $self = shift;
    my ($dbh, $time_zone) = @_;

    $dbh->do("SET client_encoding TO 'UTF8'");
    $dbh->{pg_enable_utf8} = 1;

    $dbh->do('SET TIME ZONE ' . $dbh->quote($time_zone));
    return $dbh->do("SET DateStyle TO 'ISO, YMD'");
}

=pod

=over 4

=item $sql = $dialect->tables_sql

=item $sql = $dialect->fields_sql

=item $sql = $dialect->pk_sql

=item $sql = $dialect->unique_sql

=item $sql = $dialect->fk_sql

The scan queries (see L<C<scan>|DBIx::QuickORM::Dialect/"PUBLIC METHODS">),
over the system catalogs for ordinary and partitioned tables in
C<current_schema()>.

A field whose type is a domain also reports the domain's base type.

A column the database fills has a default (C<serial> included), a domain
default, or an identity. One that refuses values is C<GENERATED ALWAYS AS
IDENTITY> or generated. Identity needs PostgreSQL 10, generated columns 12.

Unique
keys come from unique indexes, without C<INCLUDE> columns (PostgreSQL 11 and
later, by C<server_version>). A foreign key to a
table in another schema names that table without its schema.

=back

=cut

my $IN_SCHEMA = <<'EOT';
          JOIN pg_namespace n ON n.oid = c.relnamespace AND n.nspname = current_schema()
EOT

sub tables_sql {
    return <<"    EOT";
        SELECT c.relname
          FROM pg_class c
$IN_SCHEMA
         WHERE c.relkind IN ('r', 'p')
    EOT
}

# attidentity is PostgreSQL 10 and later, attgenerated 12 and later.
sub fields_sql {
    my $self = shift;
    my $v    = $self->server_version;

    my ($identity, $always) = $v >= 100000 ? ("a.attidentity <> ''", "a.attidentity = 'a'") : ('FALSE', 'FALSE');
    my $generated = $v >= 120000 ? "a.attgenerated <> ''" : 'FALSE';

    return <<"    EOT";
        SELECT c.relname, a.attname, format_type(a.atttypid, a.atttypmod),
               CASE WHEN t.typtype = 'd' THEN format_type(t.typbasetype, t.typtypmod) END,
               CASE WHEN a.atthasdef OR t.typdefault IS NOT NULL OR $identity THEN 1 END,
               CASE WHEN $always OR $generated THEN 1 END
          FROM pg_attribute a
          JOIN pg_class     c ON c.oid = a.attrelid
$IN_SCHEMA
          JOIN pg_type      t ON t.oid = a.atttypid
         WHERE c.relkind IN ('r', 'p')
           AND a.attnum > 0
           AND NOT a.attisdropped
    EOT
}

sub pk_sql {
    return <<"    EOT";
        SELECT c.relname, a.attname
          FROM pg_constraint con
          JOIN pg_class      c ON c.oid = con.conrelid
$IN_SCHEMA
          JOIN generate_subscripts(con.conkey, 1) s(i) ON TRUE
          JOIN pg_attribute  a ON a.attrelid = con.conrelid AND a.attnum = con.conkey[s.i]
         WHERE con.contype = 'p'
      ORDER BY c.relname, s.i
    EOT
}

# indnkeyatts (PostgreSQL 11) leaves out INCLUDE columns. Older servers have none.
sub unique_sql {
    my $self  = shift;
    my $natts = $self->server_version >= 110000 ? 'indnkeyatts' : 'indnatts';

    return <<"    EOT";
        SELECT c.relname, i.indexrelid, a.attname
          FROM pg_index     i
          JOIN pg_class     c ON c.oid = i.indrelid
$IN_SCHEMA
          JOIN generate_series(0, i.$natts - 1) s(i) ON TRUE
          JOIN pg_attribute a ON a.attrelid = i.indrelid AND a.attnum = i.indkey[s.i]
         WHERE i.indisunique
           AND NOT i.indisprimary
           AND i.indpred IS NULL
           AND i.indexprs IS NULL
    EOT
}

sub fk_sql {
    return <<"    EOT";
        SELECT c.relname, con.oid, a.attname, oc.relname, oa.attname
          FROM pg_constraint con
          JOIN pg_class      c  ON c.oid  = con.conrelid
$IN_SCHEMA
          JOIN pg_class      oc ON oc.oid = con.confrelid
          JOIN generate_subscripts(con.conkey, 1) s(i) ON TRUE
          JOIN pg_attribute  a  ON a.attrelid  = con.conrelid  AND a.attnum  = con.conkey[s.i]
          JOIN pg_attribute  oa ON oa.attrelid = con.confrelid AND oa.attnum = con.confkey[s.i]
         WHERE con.contype = 'f'
      ORDER BY c.relname, con.oid, s.i
    EOT
}

=head1 PRIVATE METHODS

=over 4

=item $version = $class->_server_version($dbh)

C<pg_server_version>, PostgreSQL's own number.

=back

=cut

sub _server_version { $_[1]->{pg_server_version} }

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
