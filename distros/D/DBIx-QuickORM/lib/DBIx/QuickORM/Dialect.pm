package DBIx::QuickORM::Dialect;
use strict;
use warnings;

our $VERSION = '0.000031';

use Carp qw/croak/;
use DBI();
use POSIX();

use Object::HashBase qw{
    <server_version
};

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Dialect - Base for the per-database facts and session setup.

=head1 DESCRIPTION

A dialect holds what the ORM needs to know about one database: quoting,
savepoints, C<RETURNING>, bind limits, error codes, session setup, and how to
scan the schema. Each supported database has one under
C<DBIx::QuickORM::Dialect::>. C<for_dbh> picks the one for a handle.

C<for_dbh> returns a dialect object for one connection. Its only state is the
server's version (C<server_version>), read once at connect, so a method can
depend on it. Methods that need no server fact also work on the class.

This base class holds the defaults most databases share: double-quoted
identifiers, savepoints, C<RETURNING> on every statement, and
C<current_schema()> as the namespace. A subclass overrides only what differs.

Every dialect provides C<init_session($dbh, $time_zone)>, which turns on
UTF-8 for the session and sets the session time zone where the database has
one. C<$time_zone> is a zone name such as C<UTC> or C<America/New_York>,
passed to the database as given, except that MySQL and MariaDB get C<UTC> as
C<+00:00>.

=head1 SYNOPSIS

    my $dialect = DBIx::QuickORM::Dialect->for_dbh($dbh);
    $dialect->init_session($dbh, 'UTC');

    my $modern = $dialect->server_version >= 110000;    # PostgreSQL 11 or later

    my $sql = 'SELECT * FROM ' . $dialect->quote_identifier('users');

=head1 ATTRIBUTES

=over 4

=item $version = $dialect->server_version

The server's version as one integer, so versions compare with C<< >= >>:

=over 4

=item *

PostgreSQL: its own number, C<pg_server_version> (C<110000> is 11.0, C<90603>
is 9.6.3).

=item *

MySQL, MariaDB, SQLite, DuckDB: C<major * 1_000_000 + minor * 1_000 + patch>,
from the server's version string (C<8.0.36> is C<8000036>).

=back

Undef when the server's version string cannot be read.

=back

=head1 PUBLIC METHODS

=over 4

=item $dialect = DBIx::QuickORM::Dialect->for_dbh($dbh)

The dialect object for a connected handle, chosen by driver name, with the
server's version read from the handle.

The chosen class may refine the choice from the server (C<dialect_for_dbh>).
L<DBD::MariaDB> gives the MariaDB dialect for a MariaDB server, the MySQL one
otherwise. An unsupported driver croaks, naming the supported ones.

=back

=cut

my %DRIVERS = (
    Pg      => 'PostgreSQL',
    MariaDB => 'MySQL',
    SQLite  => 'SQLite',
    DuckDB  => 'DuckDB',
);

sub for_dbh {
    my $class = shift;
    my ($dbh) = @_;

    my $driver = $dbh->{Driver}->{Name};
    my $name   = $DRIVERS{$driver} or croak "Unsupported database driver 'DBD::$driver', supported drivers are: " . join(', ' => map { "DBD::$_" } sort keys %DRIVERS);

    require "DBIx/QuickORM/Dialect/$name.pm";
    my $dialect = "DBIx::QuickORM::Dialect::$name"->dialect_for_dbh($dbh);
    return $dialect->new(server_version => $dialect->_server_version($dbh));
}

=pod

=over 4

=item $name = $dialect->name

The dialect's short name, the last part of its class, such as C<PostgreSQL>,
for messages.

=item $class = $dialect->dialect_for_dbh($dbh)

The dialect to use for this handle: the dialect itself, unless a subclass
looks at the server.

=item $char = $dialect->quote_char

The character that quotes identifiers. C<"> by default.

=item $bool = $dialect->supports_savepoints

Whether the database has savepoints, so transactions can nest. True by
default.

=item $bool = $dialect->supports_isolation

Whether C<begin_sql> can set a transaction isolation level. False by default
(SQLite, DuckDB). Where it is true, a transaction states a level every time it
opens (see L<DBIx::QuickORM::Manual::Transactions/ISOLATION>).

=item $bool = $dialect->supports_returning_insert

=item $bool = $dialect->supports_returning_update

=item $bool = $dialect->supports_returning_delete

Whether C<INSERT>, C<UPDATE>, and C<DELETE> take a C<RETURNING> clause. True
by default.

=item $bool = $dialect->having_uses_alias

Whether a C<having> naming a computed column sends that name to the database.
False by default: the SQL builder writes the column's SQL in its place, which
works everywhere (PostgreSQL rejects a select alias in C<HAVING>, and SQLite
lets a table column of the same name win over it).

=item $n = $dialect->bind_limit

The most binds one statement may hold. 999 by default, the lowest limit of
the supported databases (SQLite before 3.32.0).

=item ($parser, $formatter, \%instants) = $dialect->datetime_format

The L<DateTime::Format> classes that parse the database's date and timestamp
values and format values for it. L<DateTime::Format::Pg> for both by default.

A formatter of undef means L<DBIx::QuickORM::Type::DateTime> formats values
itself.

C<%instants> holds the base types without a zone in their name that still
store an instant, such as C<< {timestamp => 1} >>. None by default.

=back

=cut

sub name                      { ((ref($_[0]) || $_[0]) =~ m/(\w+)$/)[0] }
sub dialect_for_dbh           { $_[0] }
sub quote_char                { '"' }
sub supports_savepoints       { 1 }
sub supports_isolation        { 0 }
sub supports_returning_insert { 1 }
sub supports_returning_update { 1 }
sub supports_returning_delete { 1 }
sub having_uses_alias         { 0 }
sub bind_limit                { 999 }
sub datetime_format           { ('DateTime::Format::Pg', 'DateTime::Format::Pg') }

=pod

=over 4

=item @sql = $dialect->begin_sql

=item @sql = $dialect->begin_sql($level)

The statements that open a root transaction: C<BEGIN> by default.

C<$level> is an upper-case isolation level, such as C<SERIALIZABLE>. The
Connection passes one for every root transaction where the dialect
C<supports_isolation>, and none for C<< isolation => 'server' >>. The base
croaks when one is given: the database has no level to set (SQLite, DuckDB).

=back

=cut

sub begin_sql {
    my $self = shift;
    my ($level) = @_;
    croak "The " . $self->name . " dialect cannot set a transaction isolation level" if $level;
    return ('BEGIN');
}

=pod

=over 4

=item $sql = $dialect->quote_identifier($name)

C<$name> quoted with C<quote_char>, doubling any quote character inside it.

=back

=cut

sub quote_identifier {
    my $self = shift;
    my ($name) = @_;

    my $q = $self->quote_char;
    $name =~ s/\Q$q\E/$q$q/g;
    return "$q$name$q";
}

=pod

=over 4

=item $ns = $dialect->namespace($dbh)

The namespace the connection works in, or undef when it has none.
C<current_schema()> by default.

=back

=cut

sub namespace {
    my $self  = shift;
    my ($dbh) = @_;
    my ($ns)  = $dbh->selectrow_array('SELECT current_schema()');
    return $ns;
}

=pod

=over 4

=item $dialect->release_inherited($dbh)

Lets go of a handle a forked child inherited without closing the parent's
session. Sets C<InactiveDestroy> by default.

=back

=cut

sub release_inherited {
    my $self = shift;
    my ($dbh) = @_;
    $dbh->{InactiveDestroy} = 1;
    return;
}

=pod

=over 4

=item $bool = $dialect->supports_second_connection($dbh)

Whether another connection, from this process or a forked child, reaches the
same data as this handle. True by default.

=item $bool = $dialect->supports_async

Whether a query can run on the handle without waiting for it. False by
default.

A dialect that says true also provides C<async_prepare_attrs> (the C<prepare>
attributes for such a statement, which is executed once),
C<async_ready($dbh, $sth)>, C<async_result($dbh, $sth)> (waits for the
result), and C<cancel_async($dbh, $sth)>.

=back

=cut

sub supports_second_connection { 1 }
sub supports_async             { 0 }

=pod

=over 4

=item $dialect->text_from_db(@values)

=item $dialect->text_to_db(@values)

Convert text in place, as it is fetched from the database and before it is
sent, for drivers that do not exchange character strings themselves. Both do
nothing by default.

Callers pass only text, never values of binary fields.

=back

=cut

sub text_from_db { }
sub text_to_db   { }

=pod

=over 4

=item $attrs = $dialect->binary_bind_attrs

The C<bind_param> attributes for a binary value. C<< {TYPE => SQL_BLOB} >> by
default.

=back

=cut

sub binary_bind_attrs { {TYPE => DBI::SQL_BLOB()} }

=pod

=over 4

=item $attrs = $dialect->bind_attrs(\%field)

The C<bind_param> attributes for a value going to the field (a map field
record, or undef): C<binary_bind_attrs> for a field of C<binary> affinity,
otherwise undef.

=back

=cut

sub bind_attrs {
    my $self = shift;
    my ($field) = @_;
    return undef unless $field && ($field->{affinity} // '') eq 'binary';
    return $self->binary_bind_attrs;
}

=pod

=over 4

=item $id = $dialect->last_insert_id($dbh, $table, $field)

The value the database generated for the field by the last insert.

=back

=cut

sub last_insert_id {
    my $self = shift;
    my ($dbh, $table, $field) = @_;
    return $dbh->last_insert_id(undef, undef, $table, $field);
}

=pod

=over 4

=item \%kinds = $dialect->native_error_kinds

Native error codes mapped to error kinds. Empty by default.

=back

=cut

my %STATE_KIND = (
    '40001' => 'serialization_failure',
    '40P01' => 'deadlock',
    '55P03' => 'lock_timeout',
    '23505' => 'unique_violation',
    '23503' => 'foreign_key_violation',
    '23502' => 'not_null_violation',
    '23514' => 'check_violation',
);

sub native_error_kinds { {} }

=pod

=over 4

=item $kind = $dialect->error_kind($native, $state, $errstr)

The kind of a database error (see L<DBIx::QuickORM::Exception::DB>), or undef.

The native code is looked up in C<native_error_kinds> first, then the
SQLSTATE. C<$errstr> is unused here. The SQLSTATEs known:

=for highlighter language=text

    40001  serialization_failure
    40P01  deadlock
    55P03  lock_timeout
    23505  unique_violation
    23503  foreign_key_violation
    23502  not_null_violation
    23514  check_violation

=back

=cut

sub error_kind {
    my $self = shift;
    my ($native, $state) = @_;

    my $kind = defined($native) ? $self->native_error_kinds->{$native} : undef;
    $kind //= $STATE_KIND{$state} if defined $state;
    return $kind;
}

=pod

=over 4

=item \%tables = $dialect->scan($dbh)

Scans the tables of the connection's namespace and returns them as plain map
data:

=for highlighter language=perl

    {
        users => {
            fields => {
                id => {
                    table    => 'users',
                    name     => 'id',
                    affinity => 'numeric',
                    db_type  => 'integer',
                    type     => 'integer',
                },
                ...
            },
            pk     => ['id'],                  # key order, or undef when there is none
            unique => [['email'], ['a', 'b']], # each sorted, and the primary key is not repeated
            fk     => {orgs => [{org_id => 'id'}]},
        },
    }

Views, temporary tables, and system tables are left out. So are partial and
expression unique indexes, since they do not make their columns unique across
all rows.

The scan runs one query per kind of metadata (DuckDB two for unique keys).
Each dialect provides the SQL through these methods, each given the handle
but C<unique_sql>:

=over 4

=item C<tables_sql>: C<(table)> rows.

=item C<fields_sql>: C<(table, field, db_type, base_db_type, db_fills, db_refuses_value)> rows. C<base_db_type> is the type a user-defined type stands for, or undef. The last two are true or undef (see C<field_facts>).

=item C<pk_sql>: C<(table, field)> rows in key order.

=item C<unique_sql>: C<(table, key, field)> rows, with an undef field for a key that does not cover whole columns.

=item C<fk_sql>: C<(table, key, field, other_table, other_field)> rows in key order, with an undef other field for a key on the other table's primary key.

=back

=back

=cut

sub scan {
    my $self = shift;
    my ($dbh) = @_;

    my %tables = map { $_->[0] => {fields => {}, pk => undef, unique => [], fk => {}} } @{$self->_rows($dbh, $self->tables_sql($dbh))};

    for my $row (@{$self->_rows($dbh, $self->fields_sql($dbh))}) {
        my ($table, $field, @types) = @$row;
        my $t = $tables{$table} or next;
        $t->{fields}->{$field} = {%{$self->field_facts(@types)}, table => $table, name => $field};
    }

    for my $row (@{$self->_rows($dbh, $self->pk_sql($dbh))}) {
        my ($table, $field) = @$row;
        my $t = $tables{$table} or next;
        push @{$t->{pk} //= []} => $field;
    }

    $self->_add_unique(\%tables, $self->_keys_by_table($self->_unique_rows($dbh)));
    $self->_add_fks(\%tables, $self->_keys_by_table($self->_rows($dbh, $self->fk_sql($dbh))));

    return \%tables;
}

=pod

=over 4

=item \%field = $dialect->field_facts($db_type, $base_db_type, $db_fills, $db_refuses_value)

The map's facts about a field:

=over 4

=item C<db_type>: as given.

=item C<type>: the lowercased base name, without sizes, array markers, C<unsigned>, or C<zerofill>.

=item C<size>: the number the first parentheses start with, when they do.

=item C<affinity>: from C<$base_db_type> when given, otherwise from C<$db_type>.

=item C<db_fills>: 1 when the database fills the column when an insert leaves it out (a default, identity, serial, auto-increment, rowid alias, or generated column). Absent otherwise.

=item C<db_refuses_value>: 1 when the database rejects an explicit value for the column (PostgreSQL C<GENERATED ALWAYS AS IDENTITY>, generated columns). Absent otherwise.

=back

=back

=cut

sub field_facts {
    my $self = shift;
    my ($db_type, $base, $fills, $refuses) = @_;

    my ($type, $size) = $self->_base_type($db_type);
    my %field = (db_type => $db_type, type => $type, affinity => $self->affinity(defined($base) ? $base : $db_type));
    $field{size}             = $size if defined $size;
    $field{db_fills}         = 1     if $fills;
    $field{db_refuses_value} = 1     if $refuses;

    return \%field;
}

my %AFFINITY = (
    (map { $_ => 'string' } qw/bit char character string text bpchar clob nchar nvarchar enum set json jsonb money uuid xml citext name/),
    (map { $_ => 'string' } 'character varying', 'national character', 'national character varying'),
    (map { $_ => 'string' } qw/date datetime interval time timestamp timestamptz timetz year/),
    (map { $_ => 'string' } 'time with time zone', 'time without time zone', 'timestamp with time zone', 'timestamp without time zone'),
    (map { $_ => 'binary' } qw/binary blob bytea/),
    (map { $_ => 'numeric' } qw/dec decimal double float float4 float8 hugeint int int2 int4 int8 integer tinyint smallint mediumint bigint number numeric real serial serial4 serial8 uhugeint/),
    (map { $_ => 'numeric' } 'double precision'),
    (map { $_ => 'boolean' } qw/bool boolean/),
);

=pod

=over 4

=item $affinity = $dialect->affinity($db_type)

C<string>, C<numeric>, C<binary>, or C<boolean>.

Dates, times, JSON, and UUIDs are C<string>, and so is any type this does not
know. C<bit> is C<string>: PostgreSQL returns bit strings and MySQL raw
bytes, neither of which compares as a number.

=back

=cut

sub affinity {
    my $self = shift;
    my ($db_type) = @_;
    return $self->_known_affinity($db_type) // 'string';
}

=head1 PRIVATE METHODS

=over 4

=item $version = $class->_server_version($dbh)

The server's version for C<server_version>. By default C<SELECT version()>,
through C<_version_number>.

=item $version = $class->_version_number($string)

The first C<major.minor[.patch]> in the string as
C<major * 1_000_000 + minor * 1_000 + patch>, or undef when it has none, so
an unreadable version string does not refuse the connection.

=back

=cut

sub _server_version {
    my $class     = shift;
    my ($dbh)     = @_;
    my ($version) = $dbh->selectrow_array('SELECT version()');
    return $class->_version_number($version);
}

sub _version_number {
    my $class = shift;
    my ($string) = @_;
    my ($major, $minor, $patch) = ($string // '') =~ m/(\d+)\.(\d+)(?:\.(\d+))?/ or return undef;
    return $major * 1_000_000 + $minor * 1_000 + ($patch // 0);
}

=pod

=over 4

=item $dialect->_null_socket($fd)

Points the file descriptor at F</dev/null>, so nothing this process does with
an inherited socket reaches the parent's session. Does nothing for undef or a
negative descriptor.

=back

=cut

sub _null_socket {
    my $self = shift;
    my ($fd) = @_;
    return unless defined($fd) && $fd >= 0;
    open(my $null, '+<', '/dev/null') or die "Could not open /dev/null: $!";
    POSIX::dup2(fileno($null), $fd) // die "Could not redirect the inherited database socket: $!";
}

=pod

=over 4

=item $affinity = $dialect->_known_affinity($db_type)

The affinity of a known type, ignoring case, sizes, and a C<tiny>, C<small>,
C<medium>, C<big>, C<long>, C<var>, or C<u> prefix, or undef for any other.

=back

=cut

sub _known_affinity {
    my $self = shift;
    my ($db_type) = @_;

    my ($type) = $self->_base_type($db_type);
    return $AFFINITY{$type} if $AFFINITY{$type};
    return $AFFINITY{$1}    if $type =~ m/^(?:tiny|small|medium|big|long|var|u)(.+)$/ && $AFFINITY{$1};
    return undef;
}

=pod

=over 4

=item \@rows = $dialect->_rows($dbh, $sql)

Every row of a scan query, as arrayrefs, each value passed through
C<text_from_db>.

=back

=cut

sub _rows {
    my $self = shift;
    my ($dbh, $sql) = @_;
    my $rows = $dbh->selectall_arrayref($sql);
    $self->text_from_db(@$_) for @$rows;
    return $rows;
}

=pod

=over 4

=item ($type, $size) = $dialect->_base_type($db_type)

The C<type> and C<size> of C<field_facts>.

=back

=cut

sub _base_type {
    my $self = shift;
    my ($db_type) = @_;

    my $type   = lc($db_type);
    my ($size) = $type =~ m/^[^(]*\(\s*(\d+)/;
    1 while $type =~ s/\([^()]*\)//g;
    $type         =~ s/\[\d*\]//g;
    $type         =~ s/\b(?:unsigned|zerofill)\b//g;
    $type         =~ s/\s+/ /g;
    $type         =~ s/^ | $//g;

    return ($type, defined($size) ? $size + 0 : undef);
}

=pod

=over 4

=item \@rows = $dialect->_unique_rows($dbh)

The C<(table, key, field)> rows of the unique keys: C<unique_sql>'s rows by
default.

=back

=cut

sub _unique_rows {
    my $self = shift;
    my ($dbh) = @_;
    return $self->_rows($dbh, $self->unique_sql);
}

=pod

=over 4

=item \%keys = $dialect->_keys_by_table(\@rows)

Groups C<(table, key, ...)> rows as C<< {table => {key => [[...], ...]}} >>,
keeping row order within each key.

=back

=cut

sub _keys_by_table {
    my $self = shift;
    my ($rows) = @_;

    my %keys;
    for my $row (@$rows) {
        my ($table, $key, @rest) = @$row;
        push @{$keys{$table}->{$key}} => \@rest;
    }

    return \%keys;
}

=pod

=over 4

=item $dialect->_add_unique(\%tables, \%keys)

=item $dialect->_add_fks(\%tables, \%keys)

Turn grouped C<unique_sql> and C<fk_sql> rows into each table's C<unique> and
C<fk>, sorted and without duplicates.

A unique key with an undef field, or a field the table does not have, is left
out. A foreign key with undef other fields is used only when the other table
was scanned and its primary key has as many fields. It then points at that
key.

=back

=cut

sub _add_unique {
    my $self = shift;
    my ($tables, $keys) = @_;

    for my $table (keys %$keys) {
        my $t    = $tables->{$table} or next;
        my %seen = $t->{pk} ? (join("\0" => sort @{$t->{pk}}) => 1) : ();

        my @unique;
        for my $rows (values %{$keys->{$table}}) {
            my @fields = map { $_->[0] } @$rows;
            next if grep { !defined($_) || !$t->{fields}->{$_} } @fields;
            @fields = sort @fields;
            push @unique => \@fields unless $seen{join "\0" => @fields}++;
        }

        $t->{unique} = [sort { join("\0" => @$a) cmp join("\0" => @$b) } @unique];
    }
}

sub _add_fks {
    my $self = shift;
    my ($tables, $keys) = @_;

    for my $table (keys %$keys) {
        my $t = $tables->{$table} or next;

        my %links;
        for my $rows (values %{$keys->{$table}}) {
            my $other = $rows->[0]->[1];

            # An undef other field means the other table's primary key, in key order.
            # A key on a table with none is unusable.
            my $other_pk = $tables->{$other} ? $tables->{$other}->{pk} : undef;
            my $usable   = !grep { !defined $_->[2] } @$rows;
            $usable ||= $other_pk && @$other_pk == @$rows;
            next unless $usable;

            my %link = map { $rows->[$_]->[0] => $rows->[$_]->[2] // $other_pk->[$_] } 0 .. $#$rows;
            $links{$other}->{join "\0" => map { "$_\0$link{$_}" } sort keys %link} = \%link;
        }

        $t->{fk} = {map { my $l = $links{$_}; ($_ => [@{$l}{sort keys %$l}]) } keys %links};
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
