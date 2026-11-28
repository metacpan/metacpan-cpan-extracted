package DBIx::QuickORM::Dialect::MySQL;
use strict;
use warnings;

our $VERSION = '0.000031';

use DBI();

use parent 'DBIx::QuickORM::Dialect';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::MySQL - MySQL dialect, and base for MariaDB.

=head1 DESCRIPTION

MySQL through L<DBD::MariaDB>, the only supported driver for the MySQL family.
Backtick quoting, no C<RETURNING>, native error codes, and async queries
through the driver. The namespace is C<DATABASE()>.

Which dialect a handle gets is a server fact: a server whose version names
MariaDB gets L<DBIx::QuickORM::Dialect::MariaDB>. Any other server (MySQL
Community, Percona) gets this one.

=head1 SYNOPSIS

    # this class or MariaDB for DBD::MariaDB
    my $dialect = DBIx::QuickORM::Dialect->for_dbh($dbh);

=head1 PUBLIC METHODS

=over 4

=item $char = $dialect->quote_char

A backtick.

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_delete

All false: MySQL has no C<RETURNING>.

=item $bool = $dialect->supports_isolation

True.

=item @sql = $dialect->begin_sql($level)

C<SET TRANSACTION ISOLATION LEVEL $level> then C<BEGIN> when given a level,
otherwise C<BEGIN>. Without C<SESSION>, the level applies to the next
transaction only.

=item $bool = $dialect->having_uses_alias

True: the server resolves the alias in C<HAVING> and computes the column
once, but it computes a repeated expression a second time.

=item $n = $dialect->bind_limit

65535, the most placeholders a prepared statement may hold.

=item ($parser, $formatter, \%instants) = $dialect->datetime_format

L<DateTime::Format::MySQL> for both. C<TIMESTAMP> stores an instant: the
server converts it from and to the session time zone. C<DATETIME> does not.

=item $bool = $dialect->supports_async

True.

=item $attrs = $dialect->async_prepare_attrs

C<< {mariadb_async => 1} >>.

=item $bool = $dialect->async_ready($dbh, $sth)

=item $dialect->async_result($dbh, $sth)

C<mariadb_async_ready> and C<mariadb_async_result> on the statement. The
C<mariadb_> prefix names the driver, but they work against every server of
the family.

=item $dialect->cancel_async($dbh, $sth)

Waits for the result and discards it: the driver cannot cancel a query on its
own connection.

=back

=cut

sub quote_char                { '`' }
sub supports_returning_insert { 0 }
sub supports_returning_update { 0 }
sub supports_returning_delete { 0 }
sub supports_isolation        { 1 }
sub begin_sql                 { $_[1] ? ("SET TRANSACTION ISOLATION LEVEL $_[1]", 'BEGIN') : ('BEGIN') }
sub having_uses_alias         { 1 }
sub bind_limit                { 65535 }
sub datetime_format           { ('DateTime::Format::MySQL', 'DateTime::Format::MySQL', {timestamp => 1}) }
sub supports_async            { 1 }
sub async_prepare_attrs       { {mariadb_async => 1} }
sub async_ready               { $_[2]->mariadb_async_ready }
sub async_result              { $_[2]->mariadb_async_result }
sub cancel_async              { $_[2]->mariadb_async_result }

=pod

=over 4

=item $class = $dialect->dialect_for_dbh($dbh)

L<DBIx::QuickORM::Dialect::MariaDB> when C<SELECT version()> names MariaDB,
otherwise this class.

=back

=cut

sub dialect_for_dbh {
    my $class = shift;
    my ($dbh) = @_;

    my ($version) = $dbh->selectrow_array('SELECT version()');
    return $class unless $version =~ m/mariadb/i;

    require DBIx::QuickORM::Dialect::MariaDB;
    return 'DBIx::QuickORM::Dialect::MariaDB';
}

=pod

=over 4

=item \%kinds = $dialect->native_error_kinds

The native codes, since MySQL reports a generic SQLSTATE for most errors:

=for highlighter language=text

    1205                    lock_timeout           (lock wait timeout)
    1213                    deadlock
    1062, 1169, 1586        unique_violation       (duplicate key)
    1216, 1217, 1451, 1452  foreign_key_violation  (missing or still-referenced parent row)
    1048, 1364              not_null_violation     (NULL, or no value and no default)
    3819                    check_violation        (failed CHECK)

=back

=cut

my %NATIVE_KIND = (
    1205 => 'lock_timeout',
    1213 => 'deadlock',
    3819 => 'check_violation',
    (map { $_ => 'unique_violation' } 1062,      1169, 1586),
    (map { $_ => 'foreign_key_violation' } 1216, 1217, 1451, 1452),
    (map { $_ => 'not_null_violation' } 1048,    1364),
);

sub native_error_kinds { \%NATIVE_KIND }

=pod

=over 4

=item $ns = $dialect->namespace($dbh)

C<DATABASE()>, or undef when the connection has no database selected.

=back

=cut

sub namespace {
    my $self  = shift;
    my ($dbh) = @_;
    my ($ns)  = $dbh->selectrow_array('SELECT DATABASE()');
    return $ns;
}

=pod

=over 4

=item $dialect->init_session($dbh, $time_zone)

C<SET NAMES utf8mb4>, then C<SET time_zone>. Also records the pid that owns
the handle, for C<release_inherited>.

C<UTC> is sent as C<+00:00>, which works without the server's time zone
tables. Any other zone name needs them.

=back

=cut

sub init_session {
    my $self = shift;
    my ($dbh, $time_zone) = @_;

    $dbh->do('SET NAMES utf8mb4');
    $dbh->{private_DBIx_QuickORM_pid} = $$;

    $time_zone = '+00:00' if $time_zone eq 'UTC';
    return $dbh->do('SET time_zone = ' . $dbh->quote($time_zone));
}

=pod

=over 4

=item $dialect->release_inherited($dbh)

Points the child's copy of the handle's socket at F</dev/null>, then
disconnects, so the parent's session is untouched. Does nothing for an
inactive handle.

DBD::MariaDB closes every handle it holds when a process exits,
C<InactiveDestroy> or not, so a forked child that exits normally would
otherwise end the parent's session. At exit this runs for every still-active
handle whose recorded pid is not this process.

=back

=cut

sub release_inherited {
    my $self = shift;
    my ($dbh) = @_;

    return unless $dbh->{Active};

    $self->_null_socket($dbh->{mariadb_sockfd});

    # Statements still open on the handle are the parent's.
    $dbh->{Warn} = 0;
    $dbh->disconnect;
    return;
}

=pod

=over 4

=item $sql = $dialect->tables_sql

=item $sql = $dialect->fields_sql

=item $sql = $dialect->pk_sql

=item $sql = $dialect->unique_sql

=item $sql = $dialect->fk_sql

The scan queries (see L<C<scan>|DBIx::QuickORM::Dialect/"PUBLIC METHODS">),
over C<information_schema> for base tables in C<DATABASE()>.

Field types are C<COLUMN_TYPE>.

A column the database fills is auto-increment, generated, or has a default.
Generated columns refuse values.

MariaDB reports the default of a nullable column without one as the text
C<NULL>, which is not a default. On MySQL that text is also how a string
default C<'NULL'> appears, so such a nullable column misses C<db_fills>.
Key columns are never nullable.

A unique index over a column prefix or an
expression is left out.

=back

=cut

sub tables_sql {
    return <<"    EOT";
        SELECT TABLE_NAME
          FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_TYPE   = 'BASE TABLE'
    EOT
}

sub fields_sql {
    return <<"    EOT";
        SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE, NULL,
               CASE WHEN EXTRA LIKE '%auto_increment%'
                      OR COALESCE(GENERATION_EXPRESSION, '') <> ''
                      OR (COLUMN_DEFAULT IS NOT NULL AND NOT (COLUMN_DEFAULT = 'NULL' AND IS_NULLABLE = 'YES'))
                    THEN 1 END,
               CASE WHEN COALESCE(GENERATION_EXPRESSION, '') <> '' THEN 1 END
          FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
    EOT
}

sub pk_sql {
    return <<"    EOT";
        SELECT TABLE_NAME, COLUMN_NAME
          FROM information_schema.STATISTICS
         WHERE TABLE_SCHEMA = DATABASE()
           AND INDEX_NAME   = 'PRIMARY'
      ORDER BY TABLE_NAME, SEQ_IN_INDEX
    EOT
}

sub unique_sql {
    return <<"    EOT";
        SELECT TABLE_NAME, INDEX_NAME, CASE WHEN SUB_PART IS NULL THEN COLUMN_NAME END
          FROM information_schema.STATISTICS
         WHERE TABLE_SCHEMA = DATABASE()
           AND NON_UNIQUE   = 0
           AND INDEX_NAME  <> 'PRIMARY'
    EOT
}

sub fk_sql {
    return <<"    EOT";
        SELECT TABLE_NAME, CONSTRAINT_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME
          FROM information_schema.KEY_COLUMN_USAGE
         WHERE TABLE_SCHEMA = DATABASE()
           AND REFERENCED_TABLE_NAME IS NOT NULL
      ORDER BY TABLE_NAME, CONSTRAINT_NAME, ORDINAL_POSITION
    EOT
}

=pod

=over 4

=item \%field = $dialect->field_facts($db_type)

As inherited, but a type whose name ends in C<int> has no C<size>:
C<int(11)> is a display width.

=back

=cut

sub field_facts {
    my $self  = shift;
    my $field = $self->SUPER::field_facts(@_);
    delete $field->{size} if $field->{type} =~ m/int$/;
    return $field;
}

# Runs before DBI's END block (DBI is loaded first), which would close the parent's session.
END {
    local ($?, $@, $!);
    my %drivers = DBI->installed_drivers;
    my $drh     = $drivers{MariaDB};
    for my $dbh (grep { $_ && $_->{Active} } $drh ? @{$drh->{ChildHandles} // []} : ()) {
        my $pid = $dbh->{private_DBIx_QuickORM_pid};
        __PACKAGE__->release_inherited($dbh) if $pid && $pid != $$;
    }
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
