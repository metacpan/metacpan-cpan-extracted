package DBIx::QuickORM::Dialect::SQLite;
use strict;
use warnings;

our $VERSION = '0.000031';

use DBD::SQLite::Constants qw/DBD_SQLITE_STRING_MODE_UNICODE_STRICT/;

use parent 'DBIx::QuickORM::Dialect';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect::SQLite - SQLite dialect.

=head1 DESCRIPTION

SQLite through L<DBD::SQLite>. It keeps the base defaults of
L<DBIx::QuickORM::Dialect>, with strict UTF-8 sessions, foreign keys
enforced, SQLite's own type affinity rules, and its extended result codes for
error kinds. The namespace is always C<main>. Attached databases and C<temp>
are not part of it. SQLite has no session time zone.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect->for_dbh($dbh);    # this class for DBD::SQLite

=head1 PUBLIC METHODS

=over 4

=item $ns = $dialect->namespace($dbh)

C<main>.

=item ($parser, $formatter) = $dialect->datetime_format

L<DateTime::Format::Pg> parses, and the formatter is undef.

The DateTime type then writes values itself, keeping the colon in an offset
(C<+05:30>) that SQLite's date functions need.

=back

=cut

sub namespace       { 'main' }
sub datetime_format { ('DateTime::Format::Pg', undef) }

=pod

=over 4

=item $dialect->init_session($dbh, $time_zone)

Sets C<sqlite_string_mode> to C<DBD_SQLITE_STRING_MODE_UNICODE_STRICT>,
turns on C<sqlite_extended_result_codes>, and sends
C<PRAGMA foreign_keys = ON>. The time zone is not used.

In strict mode text is UTF-8 in the database and characters in Perl, and
invalid UTF-8 read from the database croaks. Extended result codes tell the
constraint errors apart.

SQLite enforces foreign keys only when a connection asks, so every connection
the ORM opens or is given asks, a forked child's reconnect included. It is a
setting of the connection, not of a transaction: transaction isolation is
still never set at connect.

=back

=cut

sub init_session {
    my $self = shift;
    my ($dbh) = @_;
    $dbh->{sqlite_string_mode}           = DBD_SQLITE_STRING_MODE_UNICODE_STRICT;
    $dbh->{sqlite_extended_result_codes} = 1;
    $dbh->do('PRAGMA foreign_keys = ON');
    return;
}

my %NATIVE_KIND = (
    (map { $_ => 'lock_timeout' } 5, 261, 517, 773, 6, 262, 518),
    2067 => 'unique_violation',
    1555 => 'unique_violation',
    787  => 'foreign_key_violation',
    1299 => 'not_null_violation',
    275  => 'check_violation',
);

=pod

=over 4

=item \%kinds = $dialect->native_error_kinds

The extended result codes:

=for highlighter language=text

    SQLITE_BUSY (5) and its extended codes    lock_timeout
    SQLITE_LOCKED (6) and its extended codes  lock_timeout
    SQLITE_CONSTRAINT_UNIQUE (2067)           unique_violation
    SQLITE_CONSTRAINT_PRIMARYKEY (1555)       unique_violation
    SQLITE_CONSTRAINT_FOREIGNKEY (787)        foreign_key_violation
    SQLITE_CONSTRAINT_NOTNULL (1299)          not_null_violation
    SQLITE_CONSTRAINT_CHECK (275)             check_violation

=back

=cut

sub native_error_kinds { \%NATIVE_KIND }

=pod

=over 4

=item $bool = $dialect->supports_second_connection($dbh)

True only for a database file.

An in-memory database (C<:memory:>, an empty file name, or C<mode=memory>)
belongs to its one connection. Another would open a new, empty database.

=back

=cut

sub supports_second_connection {
    my $self  = shift;
    my ($dbh) = @_;
    my $file  = $dbh->sqlite_db_filename;
    return defined($file) && length($file) ? 1 : 0;
}

=pod

=over 4

=item $sql = $dialect->tables_sql

=item $sql = $dialect->fields_sql

=item $sql = $dialect->pk_sql

=item $sql = $dialect->unique_sql

=item $sql = $dialect->fk_sql

The scan queries (see L<C<scan>|DBIx::QuickORM::Dialect/"PUBLIC METHODS">),
over C<main.sqlite_master> and the table pragmas, leaving out SQLite's own
C<sqlite_*> tables.

Fields come from C<pragma_table_xinfo>, so generated columns are included and
the hidden columns of virtual tables are not.

A column the database fills has a default, is generated, or is the rowid
alias. The alias is a key column of a table with no C<pk> index: that rules
out C<INT PRIMARY KEY>, C<INTEGER PRIMARY KEY DESC>, C<WITHOUT ROWID>
tables, and compound keys, as SQLite does. Generated columns refuse values.

=back

=cut

my $TABLES = <<'EOT';
          FROM main.sqlite_master m
EOT

my $USER_TABLES = <<'EOT';
         WHERE m.type = 'table'
           AND m.name NOT LIKE 'sqlite\_%' ESCAPE '\'
EOT

sub tables_sql { "SELECT m.name\n$TABLES$USER_TABLES" }

# hidden = 1 marks the hidden columns of virtual tables. Generated columns use 2 and 3.
sub fields_sql {
    return <<"    EOT";
        SELECT m.name, x.name, x.type, NULL,
               CASE WHEN x.hidden IN (2, 3)
                      OR upper(x.dflt_value) <> 'NULL'
                      OR (x.pk > 0 AND NOT EXISTS (SELECT 1 FROM pragma_index_list(m.name, 'main') il WHERE il.origin = 'pk'))
                    THEN 1 END,
               CASE WHEN x.hidden IN (2, 3) THEN 1 END
$TABLES
          JOIN pragma_table_xinfo(m.name, 'main') x
$USER_TABLES
           AND x.hidden != 1
    EOT
}

sub pk_sql {
    return <<"    EOT";
        SELECT m.name, x.name
$TABLES
          JOIN pragma_table_xinfo(m.name, 'main') x
$USER_TABLES
           AND x.pk > 0
      ORDER BY m.name, x.pk
    EOT
}

# An expression column has no name.
sub unique_sql {
    return <<"    EOT";
        SELECT m.name, il.name, ii.name
$TABLES
          JOIN pragma_index_list(m.name, 'main') il
          JOIN pragma_index_info(il.name, 'main') ii
$USER_TABLES
           AND il."unique" = 1
           AND il.partial = 0
    EOT
}

sub fk_sql {
    return <<"    EOT";
        SELECT m.name, fk.id, fk."from", fk."table", fk."to"
$TABLES
          JOIN pragma_foreign_key_list(m.name, 'main') fk
$USER_TABLES
      ORDER BY m.name, fk.id, fk.seq
    EOT
}

=pod

=over 4

=item $affinity = $dialect->affinity($db_type)

SQLite's own rules on the declared type, then the inherited lookup, then
C<numeric>. The rules, in order:

    INT                 numeric
    CHAR, CLOB, TEXT    string
    BLOB, or no type    binary
    REAL, FLOA, DOUB    numeric

=back

=cut

sub affinity {
    my $self = shift;
    my ($db_type) = @_;

    my $t = uc($db_type);
    return 'numeric' if $t =~ m/INT/;
    return 'string'  if $t =~ m/CHAR|CLOB|TEXT/;
    return 'binary'  if $t =~ m/BLOB/ || $t !~ m/\S/;
    return 'numeric' if $t =~ m/REAL|FLOA|DOUB/;

    return $self->_known_affinity($db_type) // 'numeric';
}

=head1 PRIVATE METHODS

=over 4

=item $version = $class->_server_version($dbh)

C<SELECT sqlite_version()>, through C<_version_number>.

=back

=cut

sub _server_version {
    my $class     = shift;
    my ($dbh)     = @_;
    my ($version) = $dbh->selectrow_array('SELECT sqlite_version()');
    return $class->_version_number($version);
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
