package Database::Join::Catalog;

use 5.010001;
use strict;
use warnings;

use Carp qw(croak);
use DBI;
use File::Temp qw(tempfile);
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(blessed);

use version; our $VERSION = version->declare('0.011.1');

# What a caller needs to know about a database before it opens a table of it
# through Database::Abstraction, and the one write it may need: a table of
# rows as a SQLite file.  Database::Abstraction opens a table it is told the
# name of, and Database::Join reads; neither lists the tables a file or a
# server holds, says what a table's columns are in their declared order or
# what its key is, or writes a file.  An application that used DBI for those
# would need a driver of its own beside the ones this distribution requires,
# so they are here.

Readonly my $SQLITE_RE => qr/\Adbi:SQLite:/i;
Readonly my $MYSQL_RE  => qr/\Adbi:(?:MariaDB|mysql):/i;
Readonly my $DRIVER_RE => qr/\A[A-Za-z][A-Za-z0-9_]*\z/;

Readonly::Hash my %MESSAGES => (
	error_source_required	=> 'Give a file (a SQLite database) or a dsn',
	error_source_both	=> 'Give a file or a dsn, not both',
	error_driver_unsupported	=> 'Listing tables is supported for SQLite, MariaDB and MySQL, not "%s"',
	error_table_required	=> 'A table name is required',
	error_columns_required	=> 'At least one column is required',
	error_row_not_hash	=> 'rows[%d] is not a hash of column values',
	error_file_exists	=> '"%s" already exists; write_sqlite makes a new file and never replaces one',
	error_temp_file		=> 'Cannot make a temporary file: %s',
	error_no_reason		=> 'The database driver failed and gave no reason',
);

sub _msg {
	my ($key, @args) = @_;
	return @args ? sprintf($MESSAGES{$key}, @args) : $MESSAGES{$key};
}

# _fail($stage, $why) -- croak a Database::Join::Catalog::Error.
sub _fail {
	my ($stage, $why) = @_;
	$why //= '';
	# RaiseError's form: "DBD::SQLite::db prepare failed: no such table: x at FILE line N."
	# and "DBI connect('dsn','user',...) failed: ...", which names the data source.
	$why =~ s/\A(?:DBD::\w+::\w+ \w+|DBI \w+\(.*?\)) failed: //s;
	$why =~ s/\s+at \S+ line \d+\.?\s*\z//;
	$why = _msg('error_no_reason') unless length $why;
	croak(Database::Join::Catalog::Error->new(stage => $stage, message => $why));
}

# _source(\%args) -> ($dsn, $username, $password, $is_sqlite)
sub _source {
	my ($p) = @_;
	croak _msg('error_source_both') if defined $p->{file} && defined $p->{dsn};
	if (defined $p->{file}) {
		return ("dbi:SQLite:dbname=$p->{file}", '', '', 1);
	}
	croak _msg('error_source_required') unless defined $p->{dsn} && length $p->{dsn};
	return ($p->{dsn}, $p->{username}, $p->{password}, $p->{dsn} =~ $SQLITE_RE ? 1 : 0);
}

# _connect($dsn, $username, $password, $is_sqlite) -> $dbh
#
# A SQLite file is opened read-only: connecting to a name that is not there
# would otherwise make an empty database of it.
sub _connect {
	my ($dsn, $username, $password, $is_sqlite) = @_;
	my %attr = (RaiseError => 1, PrintError => 0, AutoCommit => 1);
	if ($is_sqlite) {
		require DBD::SQLite::Constants;
		$attr{sqlite_open_flags} = DBD::SQLite::Constants::SQLITE_OPEN_READONLY();
	}
	my $dbh = eval { DBI->connect($dsn, $username, $password, \%attr) };
	_fail('connect', $@) unless $dbh;
	return $dbh;
}

# _query($dbh, $code) -> whatever $code returns; disconnects either way.
sub _query {
	my ($dbh, $code) = @_;
	my $got = eval { [ $code->() ] };
	my $why = $@;
	eval { $dbh->disconnect };
	_fail('query', $why) unless $got;
	return wantarray ? @{$got} : $got->[0];
}

sub _params {
	my ($schema, @args) = @_;
	shift @args if @args && !ref $args[0] && $args[0] eq __PACKAGE__;
	return validate_strict(
		schema => {
			file     => { type => 'string', optional => 1 },
			dsn      => { type => 'string', optional => 1 },
			username => { type => 'string', optional => 1 },
			password => { type => 'string', optional => 1 },
			%{$schema},
		},
		input => get_params(undef, \@args) // {},
	);
}

sub available_driver {
	my ($class, @names) = @_;
	local ($@, $!);
	for my $name (@names) {
		next unless defined $name && $name =~ $DRIVER_RE;
		my $module = "DBD/$name.pm";
		return $name if eval { require $module; 1 };
	}
	return undef;
}

sub schema {
	my ($class, @args) = @_;
	local ($@, $!);
	my $p = _params({}, @args);
	my ($dsn, $username, $password, $is_sqlite) = _source($p);
	croak _msg('error_driver_unsupported', ($dsn =~ /\Adbi:([^:]*)/i)[0] // $dsn)
		unless $is_sqlite || $dsn =~ $MYSQL_RE;

	my $dbh = _connect($dsn, $username, $password, $is_sqlite);
	return _query($dbh, sub {
		my @tables;
		if ($is_sqlite) {
			my $names = $dbh->selectcol_arrayref(q{SELECT name FROM sqlite_master }
				. q{WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name});
			for my $name (@{ $names // [] }) {
				my $info = $dbh->selectall_arrayref('PRAGMA table_info(' . $dbh->quote_identifier($name) . ')',
					{ Slice => {} });
				push @tables, { name => $name, columns => [ map { $_->{name} } @{ $info // [] } ] };
			}
		} else {
			my $rows = $dbh->selectall_arrayref(q{SELECT TABLE_NAME, COLUMN_NAME FROM information_schema.COLUMNS }
				. q{WHERE TABLE_SCHEMA = DATABASE() ORDER BY TABLE_NAME, ORDINAL_POSITION});
			my %seen;
			for my $row (@{ $rows // [] }) {
				my ($name, $column) = @{$row};
				push @tables, ($seen{$name} = { name => $name, columns => [] }) unless $seen{$name};
				push @{ $seen{$name}{columns} }, $column;
			}
		}
		return \@tables;
	});
}

sub tables {
	my ($class, @args) = @_;
	local ($@, $!);
	my $p = _params({}, @args);
	my ($dsn, $username, $password, $is_sqlite) = _source($p);
	return [ map { $_->{name} } @{ $class->schema(%{$p}) } ] unless $is_sqlite;

	my $dbh = _connect($dsn, $username, $password, 1);
	return _query($dbh, sub {
		return $dbh->selectcol_arrayref(q{SELECT name FROM sqlite_master }
			. q{WHERE type='table' AND name NOT LIKE 'sqlite_%' ORDER BY name}) // [];
	});
}

sub table_info {
	my ($class, @args) = @_;
	local ($@, $!);
	my $p = _params({ table => { type => 'string', optional => 1 } }, @args);
	croak _msg('error_table_required') unless defined $p->{table} && length $p->{table};
	my ($dsn, $username, $password, $is_sqlite) = _source($p);

	my $dbh = _connect($dsn, $username, $password, $is_sqlite);
	return _query($dbh, sub {
		my $sth = $dbh->prepare('SELECT * FROM ' . $dbh->quote_identifier($p->{table}) . ' WHERE 1=0');
		$sth->execute;
		my @columns = @{ $sth->{NAME} // [] };
		$sth->finish if $sth->can('finish');
		my @primary = grep { defined } eval { $dbh->primary_key(undef, undef, $p->{table}) };
		return { columns => \@columns, primary_key => \@primary };
	});
}

# _write($file, \%args) -- the table and its rows, into a new SQLite file.
sub _write {
	my ($file, $p) = @_;
	my $columns = $p->{columns};
	my $table   = $p->{table} // 'data';
	my $dbh = eval { DBI->connect("dbi:SQLite:dbname=$file", '', '', { RaiseError => 1, PrintError => 0, AutoCommit => 1 }) };
	_fail('connect', $@) unless $dbh;
	my $ok = eval {
		my $t = $dbh->quote_identifier($table);
		my @c = map { $dbh->quote_identifier($_) } @{$columns};
		$dbh->do("CREATE TABLE $t (" . join(', ', map { "$_ TEXT" } @c) . ')');
		if (@{ $p->{rows} }) {
			$dbh->begin_work;
			my $sth = $dbh->prepare("INSERT INTO $t (" . join(', ', @c) . ') VALUES (' . join(', ', ('?') x @c) . ')');
			for my $row (@{ $p->{rows} }) {
				$sth->execute(map { $row->{$_} } @{$columns});
			}
			$dbh->commit;
		}
		1;
	};
	my $why = $@;
	eval { $dbh->rollback } unless $ok || $dbh->{AutoCommit};
	eval { $dbh->disconnect };
	_fail('query', $why) unless $ok;
	return 1;
}

sub _write_params {
	my @args = @_;
	my $p = _params({
		table   => { type => 'string', optional => 1 },
		columns => { type => 'arrayref', optional => 1 },
		rows    => { type => 'arrayref', optional => 1 },
	}, @args);
	croak _msg('error_columns_required') unless ref $p->{columns} eq 'ARRAY' && @{ $p->{columns} };
	croak _msg('error_table_required') if defined $p->{table} && !length $p->{table};
	$p->{rows} //= [];
	for my $i (0 .. $#{ $p->{rows} }) {
		croak _msg('error_row_not_hash', $i) unless ref $p->{rows}[$i] eq 'HASH';
	}
	return $p;
}

sub write_sqlite {
	my ($class, @args) = @_;
	local ($@, $!);
	my $p = _write_params(@args);
	croak _msg('error_source_required') unless defined $p->{file} && length $p->{file};
	croak _msg('error_file_exists', $p->{file}) if -e $p->{file} || -l $p->{file};
	my $ok = eval { _write($p->{file}, $p) };
	my $err = $@;
	unless ($ok) {
		unlink $p->{file};
		croak $err;
	}
	return 1;
}

sub sqlite_bytes {
	my ($class, @args) = @_;
	local ($@, $!);
	my $p = _write_params(@args);
	# EXLOCK => 0: on a BSD, File::Temp's lock stops SQLite writing the file.
	my ($fh, $file) = eval { tempfile('database-join-XXXXXXXX', SUFFIX => '.db', TMPDIR => 1, UNLINK => 0, EXLOCK => 0) };
	croak _msg('error_temp_file', $@ || $!) unless $fh;
	close $fh;
	my $ok = eval { _write($file, $p) };
	my $err = $@;
	unless ($ok) {
		unlink $file;
		croak $err;
	}
	my $bytes = do {
		open(my $in, '<:raw', $file) or do { my $e = $!; unlink $file; croak _msg('error_temp_file', $e) };
		local $/;
		my $b = <$in>;
		close $in;
		$b;
	};
	unlink $file;
	return $bytes;
}

package Database::Join::Catalog::Error;

use strict;
use warnings;
use overload '""' => sub { $_[0]->{message} }, bool => sub { 1 }, fallback => 1;

sub new {
	my ($class, %args) = @_;
	return bless { stage => $args{stage}, message => $args{message} }, $class;
}

sub stage   { return $_[0]->{stage} }
sub message { return $_[0]->{message} }

1;

__END__

=head1 NAME

Database::Join::Catalog - List a database's tables and columns, and write a table as SQLite

=head1 VERSION

0.011.1

=head1 SYNOPSIS

    use Database::Join::Catalog;

    my $names = Database::Join::Catalog->tables(file => 'store.db');   # [ 'customers', 'orders' ]
    my $all   = Database::Join::Catalog->schema(file => 'store.db');
    # [ { name => 'customers', columns => [ 'entry', 'name' ] }, ... ]

    my $info = Database::Join::Catalog->table_info(
        dsn => 'dbi:MariaDB:database=shop;host=db', username => 'ro', password => '...',
        table => 'orders',
    );
    # { columns => [ 'entry', 'item', 'qty' ], primary_key => [ 'entry' ] }

    my $bytes = Database::Join::Catalog->sqlite_bytes(
        table => 'data', columns => [ 'id', 'name' ], rows => [ { id => 1, name => 'a' } ],
    );

    my $driver = Database::Join::Catalog->available_driver('MariaDB', 'mysql');   # or undef

=head1 DESCRIPTION

L<Database::Abstraction> opens a table it is told the name of, and
L<Database::Join> reads across such tables.  Neither says which tables a
database holds, what a table's columns are in their declared order, or what
its key is, and neither writes a file.  This module does those, so that an
application reads and describes its data through this distribution and needs
no database driver of its own.

Every method is a class method.  A database is named either by C<file>, a
SQLite file, which is opened read-only (so a name that is not there is not
made into an empty database), or by C<dsn> with optional C<username> and
C<password>.  Listing tables works for SQLite, MariaDB and MySQL.

A database that cannot be reached, or a query it refuses, croaks with a
L</Database::Join::Catalog::Error>, which says which of the two it was.
Arguments that are wrong croak with a plain message.

=head1 METHODS

=head2 tables

    my $names = Database::Join::Catalog->tables(file => $path);

=head3 API SPECIFICATION

=head4 INPUT

    file:     string, a SQLite file; or
    dsn:      string, a DBI data source (SQLite, MariaDB, MySQL)
    username: string, optional (dsn only)
    password: string, optional (dsn only)

=head4 OUTPUT

An arrayref of the table names, sorted by name.  For SQLite, the user tables
(not C<sqlite_*>); for MariaDB and MySQL, those of the connection's database.
A file that is not a SQLite database croaks at stage C<query>; one that is not
there, at stage C<connect>.

=head2 schema

    my $tables = Database::Join::Catalog->schema(dsn => $dsn, username => $u, password => $p);

=head3 API SPECIFICATION

=head4 INPUT

As L</tables>.

=head4 OUTPUT

An arrayref of C<< { name => $table, columns => [ $column, ... ] } >>, sorted by
table name, each table's columns in their declared order.  Croaks as
L</tables>, and with C<error_driver_unsupported> for another driver.

=head2 table_info

    my $info = Database::Join::Catalog->table_info(dsn => $dsn, table => 'orders');

=head3 API SPECIFICATION

=head4 INPUT

    file or dsn, username, password: as tables
    table:    string, required

=head4 OUTPUT

C<< { columns => [ ... ], primary_key => [ ... ] } >>: the columns in the
table's declared order (L<Database::Abstraction>'s C<columns()> is
alphabetical), and the primary key's columns, empty when it has none or the
driver does not say.  A database that cannot be reached croaks at stage
C<connect>; a table it does not have, at stage C<query>.

=head2 write_sqlite

    Database::Join::Catalog->write_sqlite(file => 'out.db', table => 'data',
        columns => [ 'id', 'name' ], rows => \@rows);

=head3 API SPECIFICATION

=head4 INPUT

    file:    string, required; a name that does not exist yet
    table:   string, optional (default 'data')
    columns: arrayref of strings, required, at least one
    rows:    arrayref of hashrefs, optional; each row's values by column name

=head4 OUTPUT

1.  Makes a SQLite file with one table whose columns are TEXT, in the order
given, and one row for each element of C<rows> (a missing value is NULL).
Names are quoted, so any column name is safe.  The rows go in one transaction.
Croaks with C<error_file_exists> rather than replace a file, and leaves no
file behind when the write fails.

=head2 sqlite_bytes

    my $bytes = Database::Join::Catalog->sqlite_bytes(columns => \@columns, rows => \@rows);

=head3 API SPECIFICATION

=head4 INPUT

As L</write_sqlite>, without C<file>.

=head4 OUTPUT

The SQLite file's contents, made in a temporary file that is removed
afterwards, whether or not the write succeeds.

=head2 available_driver

    my $driver = Database::Join::Catalog->available_driver('MariaDB', 'mysql');

=head3 API SPECIFICATION

=head4 INPUT

    @names: DBD driver names, in order of preference

=head4 OUTPUT

The first whose C<DBD::> module loads, or undef.  A name that is not a
driver name is skipped, never loaded.

=head1 Database::Join::Catalog::Error

What a failed C<connect> or C<query> croaks with.  It reads as the driver's
message (C<"$err">), and:

    $err->stage     # 'connect' or 'query'
    $err->message   # the driver's message

=head1 MESSAGES

    error_source_required    -- neither file nor dsn (or write_sqlite without file)
    error_source_both        -- both file and dsn
    error_driver_unsupported -- schema() or tables() for a driver other than SQLite, MariaDB, MySQL
    error_table_required     -- table_info() without a table, or an empty table name
    error_columns_required   -- write_sqlite() or sqlite_bytes() without columns
    error_row_not_hash       -- an element of rows is not a hashref
    error_file_exists        -- write_sqlite() to a name that exists
    error_temp_file          -- sqlite_bytes() could not make its temporary file
    error_no_reason          -- the driver failed without a message (connect returned undef)

=head1 SEE ALSO

L<Database::Join>, L<Database::Abstraction>

=head1 AUTHOR

Nigel Horne, C<< <njh@nigelhorne.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it, please let me know.

=cut
