package DBIx::Admin::TableInfo;

use strict;
use warnings;

use Moo;

has catalog =>
(
	is       => 'rw',
	default  => sub{return undef},
	required => 0,
);

has dbh =>
(
	is       => 'rw',
	isa      => sub{die "The 'dbh' parameter to new() is mandatory\n" if (! $_[0])},
	default  => sub{return ''},
	required => 1,
);

has info =>
(
	is       => 'rw',
	default  => sub{return {} },
	required => 0,
);

has schema =>
(
	is       => 'rw',
	default  => sub{return undef}, # See BUILD().
	required => 0,
);

has table =>
(
	is       => 'rw',
	default  => sub{return '%'},
	required => 0,
);

has type =>
(
	is       => 'rw',
	default  => sub{return 'TABLE'},
	required => 0,
);

our $VERSION = '3.03';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> schema(dbh2schema($self -> dbh) ) if (! defined $self -> schema);
	$self -> _info;

} # End of BUILD.

# -----------------------------------------------

sub columns
{
	my($self, $table, $by_position) = @_;
	my($info) = $self -> info;

	if ($by_position)
	{
		return [sort{$$info{$table}{columns}{$a}{ORDINAL_POSITION} <=> $$info{$table}{columns}{$b}{ORDINAL_POSITION} } keys %{$$info{$table}{columns} }];
	}
	else
	{
		return [sort{$a cmp $b} keys %{$$info{$table}{columns} }];
	}

} # End of columns.

# -----------------------------------------------
# Warning: This is a function, not a method.

sub dbh2schema
{
	my($dbh)    = @_;
	my($vendor) = uc $dbh -> get_info(17); # SQL_DBMS_NAME.
	my(%schema) =
	(
		MYSQL      => undef,
		ORACLE     => uc $$dbh{Username},
		POSTGRESQL => 'public',
		SQLITE     => 'main',
	);

	return $schema{$vendor};

} # End of dbh2schema.

# -----------------------------------------------

sub _info
{
	my($self)      = @_;
	my($info)      = {};
	my($vendor)    = uc $self -> dbh -> get_info(17); # SQL_DBMS_NAME.
	my($table_sth) = $self -> dbh -> table_info($self -> catalog, $self -> schema, $self -> table, $self -> type);

	my($column_data, $column_name, $column_sth, $count);
	my($foreign_table);
	my($primary_key_info);
	my($table_data, $table_name, @table_name);

	while ($table_data = $table_sth -> fetchrow_hashref() )
	{
		$table_name = $$table_data{TABLE_NAME};

		next if ( ($vendor eq 'ORACLE')     && ($table_name =~ /^BIN\$.+\$./) );
		next if ( ($vendor eq 'POSTGRESQL') && ($table_name =~ /^(?:pg_|sql_)/) );
		next if ( ($vendor eq 'SQLITE')     && ($table_name eq 'sqlite_sequence') );

		$$info{$table_name} =
		{
			attributes   => {%$table_data},
			columns      => {},
			foreign_keys => {},
			primary_keys => {},
		};
		$column_sth       = $self -> dbh -> column_info($self -> catalog, $self -> schema, $table_name, '%');
		$primary_key_info = [];

		push @table_name, $table_name;

		while ($column_data = $column_sth -> fetchrow_hashref() )
		{
			$column_name                               = $$column_data{COLUMN_NAME};
			$$info{$table_name}{columns}{$column_name} = {%$column_data};

			push @$primary_key_info, $column_name if ( ($vendor eq 'MYSQL') && $$column_data{mysql_is_pri_key});
		}

		if ($vendor eq 'MYSQL')
		{
			$count = 0;

			for (@$primary_key_info)
			{
				$count++;

				$$info{$table_name}{primary_keys}{$_}              = {} if (! $$info{$table_name}{primary_keys}{$_});
				$$info{$table_name}{primary_keys}{$_}{COLUMN_NAME} = $_;
				$$info{$table_name}{primary_keys}{$_}{KEY_SEQ}     = $count;
			}
		}
		else
		{
			$column_sth = $self -> dbh -> primary_key_info($self -> catalog, $self -> schema, $table_name);

			if (defined $column_sth)
			{
				for $column_data (@{$column_sth -> fetchall_arrayref({})})
				{
					$$info{$table_name}{primary_keys}{$$column_data{COLUMN_NAME} } = {%$column_data};
				}
			}
		}
	}

	my(%referential_action) =
	(
		'CASCADE'     => 0,
		'RESTRICT'    => 1,
		'SET NULL'    => 2,
		'NO ACTION'   => 3,
		'SET DEFAULT' => 4,
	);

	for $table_name (@table_name)
	{
		$$info{$table_name}{foreign_keys} = [];

		for $foreign_table (grep{! /^$table_name$/} @table_name)
		{
			if ($vendor eq 'SQLITE')
			{
				for my $row (@{$self -> dbh -> selectall_arrayref("pragma foreign_key_list($foreign_table)")})
				{
					next if ($$row[2] ne $table_name);

					push @{$$info{$table_name}{foreign_keys} },
					{
						DEFERABILITY      => undef,
						DELETE_RULE       => $referential_action{$$row[6]},
						FK_COLUMN_NAME    => $$row[3],
						FK_DATA_TYPE      => undef,
						FK_NAME           => undef,
						FK_TABLE_CAT      => undef,
						FK_TABLE_NAME     => $foreign_table,
						FK_TABLE_SCHEM    => undef,
						ORDINAL_POSITION  => $$row[1],
						UK_COLUMN_NAME    => $$row[4],
						UK_DATA_TYPE      => undef,
						UK_NAME           => undef,
						UK_TABLE_CAT      => undef,
						UK_TABLE_NAME     => $$row[2],
						UK_TABLE_SCHEM    => undef,
						UNIQUE_OR_PRIMARY => undef,
						UPDATE_RULE       => $referential_action{$$row[5]},
					};
				}
			}
			else
			{
				$table_sth = $self -> dbh -> foreign_key_info($self -> catalog, $self -> schema, $table_name, $self -> catalog, $self -> schema, $foreign_table) || next;

				if ($vendor eq 'MYSQL')
				{
					my($hashref) = $table_sth->fetchall_hashref(['PKTABLE_NAME']);

					push @{$$info{$table_name}{foreign_keys} }, $$hashref{$table_name} if ($$hashref{$table_name});
				}
				else
				{
					for $column_data (@{$table_sth -> fetchall_arrayref({})})
					{
						push @{$$info{$table_name}{foreign_keys} }, {%$column_data};
					}
				}
			}
		}
	}

	$self -> info($info);

} # End of _info.

# -----------------------------------------------

sub refresh
{
	my($self) = @_;

	$self -> _info();

	return $self -> info;

} # End of refresh.

# -----------------------------------------------

sub tables
{
	my($self) = @_;

	return [sort keys %{$self -> info}];

} # End of tables.

# -----------------------------------------------

1;

=head1 NAME

DBIx::Admin::TableInfo - A wrapper for all of table_info(), column_info(), *_key_info()

=head1 Synopsis

This is scripts/synopsis.pl:

	#!/usr/bin/env perl

	use strict;
	use warnings;

	use DBI;
	use DBIx::Admin::TableInfo 3.02;

	use Lingua::EN::PluralToSingular 'to_singular';

	use Text::Table::Manifold ':constants';

	# ---------------------

	my($attr)              = {};
	$$attr{sqlite_unicode} = 1 if ($ENV{DBI_DSN} =~ /SQLite/i);
	my($dbh)               = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, $attr);
	my($vendor_name)       = uc $dbh -> get_info(17);
	my($info)              = DBIx::Admin::TableInfo -> new(dbh => $dbh) -> info;

	$dbh -> do('pragma foreign_keys = on') if ($ENV{DBI_DSN} =~ /SQLite/i);

	my($temp_1, $temp_2, $temp_3);

	if ($vendor_name eq 'MYSQL')
	{
		$temp_1 = 'PKTABLE_NAME';
		$temp_2 = 'FKTABLE_NAME';
		$temp_3 = 'FKCOLUMN_NAME';
	}
	else # ORACLE && POSTGRESQL && SQLITE (at least).
	{
		$temp_1 = 'UK_TABLE_NAME';
		$temp_2 = 'FK_TABLE_NAME';
		$temp_3 = 'FK_COLUMN_NAME';
	}

	my(%special_fk_column) =
	(
		spouse_id => 'person_id',
	);

	my($destination_port);
	my($fk_column_name, $fk_table_name, %foreign_key);
	my($pk_table_name, $primary_key_name);
	my($singular_name, $source_port);

	for my $table_name (sort keys %$info)
	{
		for my $item (@{$$info{$table_name}{foreign_keys} })
		{
			$pk_table_name  = $$item{$temp_1};
			$fk_table_name  = $$item{$temp_2};
			$fk_column_name = $$item{$temp_3};

			if ($pk_table_name)
			{
				$singular_name = to_singular($pk_table_name);

				if ($special_fk_column{$fk_column_name})
				{
					$primary_key_name = $special_fk_column{$fk_column_name};
				}
				elsif (defined($$info{$table_name}{columns}{$fk_column_name}) )
				{
					$primary_key_name = $fk_column_name;
				}
				elsif (defined($$info{$table_name}{columns}{id}) )
				{
					$primary_key_name = 'id';
				}
				else
				{
					die "Primary table '$pk_table_name'. Foreign table '$fk_table_name'. Unable to find primary key name for foreign key '$fk_column_name'\n"
				}

				$foreign_key{$fk_table_name}                               = {} if (! $foreign_key{$fk_table_name});
				$foreign_key{$fk_table_name}{$fk_column_name}              = {} if (! $foreign_key{$fk_table_name}{$fk_column_name});
				$primary_key_name                                          =~ s/${singular_name}_//;
				$foreign_key{$fk_table_name}{$fk_column_name}{$table_name} = $primary_key_name;
			}
		}
	}

	my(@header) =
	(
		'Name',
		'Type',
		'Null',
		'Key',
		'Auto-increment',
	);

	my($table) = Text::Table::Manifold -> new
	(
		alignment =>
		[
			align_left,
			align_left,
			align_left,
			align_left,
			align_left,
		],
		format => format_text_unicodebox_table,
		headers => \@header,
		join   => "\n",
	);
	my(%type) =
	(
		'character varying' => 'varchar',
		'int(11)'           => 'integer',
		'"timestamp"'       => 'timestamp',
	);

	my($auto_increment);
	my(@data);
	my($index);
	my($nullable);
	my($primary_key);
	my($type);

	for my $table_name (sort keys %$info)
	{
		print "Table: $table_name.\n\n";

		@data  = ();
		$index = undef;

		for my $column_name (keys %{$$info{$table_name}{columns} })
		{
			$type           = $$info{$table_name}{columns}{$column_name}{TYPE_NAME};
			$type           = $type{$type} ? $type{$type} : $type;
			$nullable       = $$info{$table_name}{columns}{$column_name}{IS_NULLABLE} eq 'NO';
			$primary_key    = $$info{$table_name}{primary_keys}{$column_name};
			$auto_increment = $primary_key; # Database server-independent kludge :-(.

			push @data,
			[
				$column_name,
				$type,
				$nullable       ? 'not null'       : '',
				$primary_key    ? 'primary key'    : '',
				$auto_increment ? 'auto_increment' : '',
			];

			$index = pop @data if ($column_name eq 'id');
		}

		@data = sort{$$a[0] cmp $$b[0]} @data;

		unshift @data, $index if ($index);

		$table -> data(\@data);

		print $table -> render_as_string, "\n\n";
	}

If the environment vaiables DBI_DSN, DBI_USER and DBI_PASS are set (the latter 2 are optional [e.g.
for SQLite), then this demonstrates extracting a lot of information from a database schema.

Also, for Postgres, you can set DBI_SCHEMA to a list of schemas, e.g. when processing the
MusicBrainz database.

For details, see L<http://blogs.perl.org/users/ron_savage/2013/03/graphviz2-and-the-dread-musicbrainz-db.html>.

See also xt/author/fk.t, xt/author/mysql.fk.pl and xt/author/person.spouse.t.

=head1 Description

C<DBIx::Admin::TableInfo> is a pure Perl module.

It is a convenient wrapper around all of these DBI methods:

=over 4

=item o table_info()

=item o column_info()

=item o primary_key_info()

=item o foreign_key_info()

=back

=over 4

=item o MySQL

Warning:

To get foreign key information in the output, the create table statement has to:

=over 4

=item o Include an index clause

=item o Include a foreign key clause

=item o Include an engine clause

As an example, a column definition for Postgres and SQLite, which looks like:

	site_id integer not null references sites(id),

has to, for MySql, look like:

	site_id integer not null, index (site_id), foreign key (site_id) references sites(id),

Further, the create table statement, which for Postgres and SQLite looks like:

	create table designs (...)

has to, for MySql, look like:

	create table designs (...) engine=innodb

=back

=item o Oracle

See the L</FAQ> for which tables are ignored under Oracle.

=item o Postgres

The latter now takes '%' as the value of the 'table' parameter to new(), whereas
older versions of DBD::Pg required 'table' to be set to 'table'.

See the L</FAQ> for which tables are ignored under Postgres.

=item o SQLite

See the L</FAQ> for which tables are ignored under SQLite.

=back

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns a C<DBIx::Admin::TableInfo> object.

This is the class contructor.

Usage: DBIx::Admin::TableInfo -> new().

This method takes a set of parameters. Only the dbh parameter is mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item o catalog

This is the value passed in as the catalog parameter to table_info() and column_info().

The default value is undef.

undef was chosen because it given the best results with MySQL.

Note: The MySQL driver DBD::mysql V 2.9002 has a bug in it, in that it aborts if an empty string is
used here, even though the DBI docs say an empty string can be used for the catalog parameter to
C<table_info()>.

This parameter is optional.

=item o dbh

This is a database handle.

This parameter is mandatory.

=item o schema

This is the value passed in as the schema parameter to table_info() and column_info().

The default value is undef.

Note: If you are using Oracle, call C<new()> with schema set to uc $user_name.

Note: If you are using Postgres, call C<new()> with schema set to 'public'.

Note: If you are using SQLite, call C<new()> with schema set to 'main'.

This parameter is optional.

=item o table

This is the value passed in as the table parameter to table_info().

The default value is '%'.

Note: If you are using an 'old' version of DBD::Pg, call C<new()> with table set to 'table'.

Sorry - I cannot tell you exactly what 'old' means. As stated above, the default value (%)
works fine with DBD::Pg V 2.17.1.

This parameter is optional.

=item o type

This is the value passed in as the type parameter to table_info().

The default value is 'TABLE'.

This parameter is optional.

=back

=head1 Methods

=head2 columns($table_name, $by_position)

Returns an array ref of column names.

By default they are sorted by name.

However, if you pass in a true value for $by_position, they are sorted by the column attribute
ORDINAL_POSITION. This is Postgres-specific.

=head2 dbh2schema($dbh)

Warning: This is a function, not a method. It is called like this:

	my($schema) = DBIx::Admin::TableInfo::dbh2schema($dbh);

The code is just:

	my($dbh)    = @_;
	my($vendor) = uc $dbh -> get_info(17); # SQL_DBMS_NAME.
	my(%schema) =
	(
		MYSQL      => undef,
		ORACLE     => uc $$dbh{Username},
		POSTGRESQL => 'public',
		SQLITE     => 'main',
	);

	return $schema{$vendor};

=head2 info()

Returns a hash ref of all available data.

The structure of this hash is described next:

=over 4

=item o First level: The keys are the names of the tables

	my($info)       = $obj -> info();
	my(@table_name) = sort keys %$info;

I use singular names for my arrays, hence @table_name rather than @table_names.

=item o Second level: The keys are 'attributes', 'columns', 'foreign_keys' and 'primary_keys'

	my($table_attributes) = $$info{$table_name}{attributes};

This is a hash ref of the attributes of the table.
The keys of this hash ref are determined by the database server.

	my($columns) = $$info{$table_name}{columns};

This is a hash ref of the columns of the table. The keys of this hash ref are the names of the
columns.

	my($foreign_keys) = $$info{$table_name}{foreign_keys};

This is a hash ref of the foreign keys of the table. The keys of this hash ref are the names of the
tables which contain foreign keys pointing to $table_name.

For MySQL, $foreign_keys will be the empty hash ref {}, as explained above.

	my($primary_keys) = $$info{$table_name}{primary_keys};

This is a hash ref of the primary keys of the table. The keys of this hash ref are the names of the
columns which make up the primary key of $table_name.

For any database server, if there is more than 1 column in the primary key, they will be numbered
(ordered) according to the hash key 'KEY_SEQ'.

For MySQL, if there is more than 1 column in the primary key, they will be artificially numbered
according to the order in which they are returned by C<column_info()>, as explained above.

=item o Third level, after 'attributes': Table attributes

	my($table_attributes) = $$info{$table_name}{attributes};

	while ( ($name, $value) = each(%$table_attributes) )
	{
		Use...
	}

For the attributes of the tables, there are no more levels in the hash ref.

=item o Third level, after 'columns': The keys are the names of the columns.

	my($columns) = $$info{$table_name}{columns};

	my(@column_name) = sort keys %$columns;

=over 4

=item o Fourth level: Column attributes

	for $column_name (@column_name)
	{
	    while ( ($name, $value) = each(%{$columns{$column_name} }) )
	    {
		    Use...
	    }
	}

=back

=item o Third level, after 'foreign_keys': An arrayref contains the details (if any)

But beware slightly differing spellings depending on the database server. This is documented in
L<https://metacpan.org/pod/DBI#foreign_key_info>. Look closely at the usage of the '_' character.

	my($vendor) = uc $dbh -> get_info(17); # SQL_DBMS_NAME.

	for $item (@{$$info{$table_name}{foreign_keys} })
	{
		# Get the name of the table pointed to.

		$primary_table = ($vendor eq 'MYSQL') ? $$item{PKTABLE_NAME} : $$item{UK_TABLE_NAME};
	}

=item o Third level, after 'primary_keys': The keys are the names of columns

These columns make up the primary key of the current table.

	my($primary_keys) = $$info{$table_name}{primary_keys};

	for $primary_key (sort{$$a{KEY_SEQ} <=> $$b{KEY_SEQ} } keys %$primary_keys)
	{
		$primary = $$primary_keys{$primary_key};

		for $attribute (sort keys %$primary)
		{
			Use...
		}
	}

=back

=head2 refresh()

Returns the same hash ref as info().

Use this after changing the database schema, when you want this module to re-interrogate
the database server.

=head2 tables()

Returns an array ref of table names.

They are sorted by name.

See the L</FAQ> for which tables are ignored under which databases.

=head1 Example code

Here are tested parameter values for various database vendors:

=over 4

=item o MS Access

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

=item o MySQL

	my($admin) = DBIx::Admin::TableInfo -> new(dbh => $dbh);

	In other words, the default values for catalog, schema, table and type will Just Work.

=item o Oracle

	my($dbh)   = DBI -> connect($dsn, $username, $password);
	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => uc $username, # Yep, upper case.
	);

	See the FAQ for which tables are ignored under Oracle.

=item o PostgreSQL

	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => 'public',
	);

	For PostgreSQL, you probably want to ignore table names matching /^(pg_|sql_)/.

	As stated above, for 'old' versions of DBD::Pg, use:

	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => 'public',
		table  => 'table', # Yep, lower case.
	);

	See the FAQ for which tables are ignored under Postgres.

=item o SQLite

	my($admin) = DBIx::Admin::TableInfo -> new
	(
		dbh    => $dbh,
		schema => 'main',
	);

	In other words, the default values for catalog, table and type will Just Work.

	See the FAQ for which tables are ignored under SQLite.

=back

See the examples/ directory in the distro.

=head1 FAQ

=head2 Which versions of the servers did you test?

	Versions as at 2014-08-06:
	+----------|-------------+
	|  Vendor  |      V      |
	+----------|-------------+
	|  MariaDB |   5.5.38    |
	+----------|-------------+
	|  Oracle  | 10.2.0.1.0  | (Not tested for years)
	+----------|-------------+
	| Postgres |    9.1.3    |
	+----------|-------------+
	|  SQLite  |   3.8.4.1   |
	+----------|-------------+

But see these L<warnings|https://metacpan.org/pod/DBIx::Admin::TableInfo#Description> when using
MySQL/MariaDB.

=head2 Which tables are ignored for which databases?

Here is the code which skips some tables:

	next if ( ($vendor eq 'ORACLE')     && ($table_name =~ /^BIN\$.+\$./) );
	next if ( ($vendor eq 'POSTGRESQL') && ($table_name =~ /^(?:pg_|sql_)/) );
	next if ( ($vendor eq 'SQLITE')     && ($table_name eq 'sqlite_sequence') );

=head2 How do I identify foreign keys?

Note: The table names here come from xt/author/person.spouse.t.

See L<DBIx::Admin::CreateTable/FAQ> for database server-specific create statements to activate
foreign keys.

Then try:

	my($info) = DBIx::Admin::TableInfo -> new(dbh => $dbh) -> info;

	print Data::Dumper::Concise::Dumper($$info{people}{foreign_keys}), "\n";

Output follows.

But beware slightly differing spellings depending on the database server. This is documented in
L<https://metacpan.org/pod/DBI#foreign_key_info>. Look closely at the usage of the '_' character.

=over 4

=item o MySQL

	[
	  {
	    DEFERABILITY => undef,
	    DELETE_RULE => undef,
	    FKCOLUMN_NAME => "spouse_id",
	    FKTABLE_CAT => "def",
	    FKTABLE_NAME => "spouses",
	    FKTABLE_SCHEM => "testdb",
	    FK_NAME => "spouses_ibfk_2",
	    KEY_SEQ => 1,
	    PKCOLUMN_NAME => "id",
	    PKTABLE_CAT => undef,
	    PKTABLE_NAME => "people",
	    PKTABLE_SCHEM => "testdb",
	    PK_NAME => undef,
	    UNIQUE_OR_PRIMARY => undef,
	    UPDATE_RULE => undef
	  }
	]

Yes, there is just 1 element in this arrayref. MySQL can sliently drop an index if another index
can be used.

=item o Postgres

	[
	  {
	    DEFERABILITY => 7,
	    DELETE_RULE => 3,
	    FK_COLUMN_NAME => "person_id",
	    FK_DATA_TYPE => "int4",
	    FK_NAME => "spouses_person_id_fkey",
	    FK_TABLE_CAT => undef,
	    FK_TABLE_NAME => "spouses",
	    FK_TABLE_SCHEM => "public",
	    ORDINAL_POSITION => 1,
	    UK_COLUMN_NAME => "id",
	    UK_DATA_TYPE => "int4",
	    UK_NAME => "people_pkey",
	    UK_TABLE_CAT => undef,
	    UK_TABLE_NAME => "people",
	    UK_TABLE_SCHEM => "public",
	    UNIQUE_OR_PRIMARY => "PRIMARY",
	    UPDATE_RULE => 3
	  },
	  {
	    DEFERABILITY => 7,
	    DELETE_RULE => 3,
	    FK_COLUMN_NAME => "spouse_id",
	    FK_DATA_TYPE => "int4",
	    FK_NAME => "spouses_spouse_id_fkey",
	    FK_TABLE_CAT => undef,
	    FK_TABLE_NAME => "spouses",
	    FK_TABLE_SCHEM => "public",
	    ORDINAL_POSITION => 1,
	    UK_COLUMN_NAME => "id",
	    UK_DATA_TYPE => "int4",
	    UK_NAME => "people_pkey",
	    UK_TABLE_CAT => undef,
	    UK_TABLE_NAME => "people",
	    UK_TABLE_SCHEM => "public",
	    UNIQUE_OR_PRIMARY => "PRIMARY",
	    UPDATE_RULE => 3
	  }
	]

=item o SQLite

	[
	  {
	    DEFERABILITY => undef,
	    DELETE_RULE => 3,
	    FK_COLUMN_NAME => "spouse_id",
	    FK_DATA_TYPE => undef,
	    FK_NAME => undef,
	    FK_TABLE_CAT => undef,
	    FK_TABLE_NAME => "spouses",
	    FK_TABLE_SCHEM => undef,
	    ORDINAL_POSITION => 0,
	    UK_COLUMN_NAME => "id",
	    UK_DATA_TYPE => undef,
	    UK_NAME => undef,
	    UK_TABLE_CAT => undef,
	    UK_TABLE_NAME => "people",
	    UK_TABLE_SCHEM => undef,
	    UNIQUE_OR_PRIMARY => undef,
	    UPDATE_RULE => 3
	  },
	  {
	    DEFERABILITY => undef,
	    DELETE_RULE => 3,
	    FK_COLUMN_NAME => "person_id",
	    FK_DATA_TYPE => undef,
	    FK_NAME => undef,
	    FK_TABLE_CAT => undef,
	    FK_TABLE_NAME => "spouses",
	    FK_TABLE_SCHEM => undef,
	    ORDINAL_POSITION => 0,
	    UK_COLUMN_NAME => "id",
	    UK_DATA_TYPE => undef,
	    UK_NAME => undef,
	    UK_TABLE_CAT => undef,
	    UK_TABLE_NAME => "people",
	    UK_TABLE_SCHEM => undef,
	    UNIQUE_OR_PRIMARY => undef,
	    UPDATE_RULE => 3
	  }
	]

=back

You can also play with xt/author/fk.t and xt/author/dsn.ini (especially the 'active' option).

fk.t does not delete the tables as it exits. This is so xt/author/mysql.fk.pl has something to play
with.

See also xt/author/person.spouse.t.

=head2 Does DBIx::Admin::TableInfo work with SQLite databases?

Yes. As of V 2.08, this module uses the SQLite code "pragma foreign_key_list($table_name)" to
emulate the L<DBI> call to foreign_key_info(...).

=head2 What is returned by the SQLite "pragma foreign_key_list($table_name)" call?

An arrayref is returned. Indexes and their interpretations:

	0: COUNT   (0, 1, ...)
	1: KEY_SEQ (0, or column # (1, 2, ...) within multi-column key)
	2: PK_TABLE_NAME
	3: FK_COLUMN_NAME
	4: PK_COLUMN_NAME
	5: UPDATE_RULE
	6: DELETE_RULE
	7: 'NONE' (Constant string)

As these are stored in an arrayref, I use $$row[$i] just below to refer to the elements of the
array.

=head2 How are these values mapped into the output?

See also the next point.

	my(%referential_action) =
	(
		'CASCADE'     => 0,
		'RESTRICT'    => 1,
		'SET NULL'    => 2,
		'NO ACTION'   => 3,
		'SET DEFAULT' => 4,
	);

The hashref returned for foreign keys contains these key-value pairs:

	{
		DEFERABILITY      => undef,
		DELETE_RULE       => $referential_action{$$row[6]},
		FK_COLUMN_NAME    => $$row[3],
		FK_DATA_TYPE      => undef,
		FK_NAME           => undef,
		FK_TABLE_CAT      => undef,
		FK_TABLE_NAME     => $table_name,
		FK_TABLE_SCHEM    => undef,
		ORDINAL_POSITION  => $$row[1],
		UK_COLUMN_NAME    => $$row[4],
		UK_DATA_TYPE      => undef,
		UK_NAME           => undef,
		UK_TABLE_CAT      => undef,
		UK_TABLE_NAME     => $$row[2],
		UK_TABLE_SCHEM    => undef,
		UNIQUE_OR_PRIMARY => undef,
		UPDATE_RULE       => $referential_action{$$row[5]},
	}

This list of keys matches what is returned when processing a Postgres database.

=head2 Have you got FK and PK backwards?

I certainly hope not. To me the FK_TABLE_NAME points to the UK_TABLE_NAME.

The "pragma foreign_key_list($table_name)" call for SQLite returns data from the create statement,
and thus it reports what the given table points to. The DBI call to foreign_key_info(...) returns
data about foreign keys referencing (pointing to) the given table. This can be confusing.

Here is a method from the module L<App::Office::Contacts::Util::Create>, part of
L<App::Office::Contacts>.

	sub create_organizations_table
	{
		my($self)        = @_;
		my($table_name)  = 'organizations';
		my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
		my($engine)      = $self -> engine;
		my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
	id $primary_key,
	visibility_id integer not null references visibilities(id),
	communication_type_id integer not null references communication_types(id),
	creator_id integer not null,
	role_id integer not null references roles(id),
	deleted integer not null,
	facebook_tag varchar(255) not null,
	homepage varchar(255) not null,
	name varchar(255) not null,
	timestamp timestamp not null default localtimestamp,
	twitter_tag varchar(255) not null,
	upper_name varchar(255) not null
) $engine
SQL

		$self -> dbh -> do("create index ${table_name}_upper_name on $table_name (upper_name)");

		$self -> report($table_name, 'created', $result);

	}	# End of create_organizations_table.

Consider this line:

	visibility_id integer not null references visibilities(id),

That means, for the 'visibilities' table, the info() method in the current module will return a
hashref like:

	{
		visibilities =>
		{
			...
			foreign_keys =>
			{
				...
				organizations =>
				{
					UK_COLUMN_NAME    => 'id',
					DEFERABILITY      => undef,
					ORDINAL_POSITION  => 0,
					FK_TABLE_CAT      => undef,
					UK_NAME           => undef,
					UK_DATA_TYPE      => undef,
					UNIQUE_OR_PRIMARY => undef,
					UK_TABLE_SCHEM    => undef,
					UK_TABLE_CAT      => undef,
					FK_COLUMN_NAME    => 'visibility_id',
					FK_TABLE_NAME     => 'organizations',
					FK_TABLE_SCHEM    => undef,
					FK_DATA_TYPE      => undef,
					UK_TABLE_NAME     => 'visibilities',
					DELETE_RULE       => 3,
					FK_NAME           => undef,
					UPDATE_RULE       => 3
				},
			},
	}

This is saying that for the table 'visibilities', there is a foreign key in the 'organizations'
table. That foreign key is called 'visibility_id', and it points to the key called 'id' in the
'visibilities' table.

=head2 How do I use schemas in Postgres?

You may need to do something like this:

	$dbh -> do("set search_path to $ENV{DBI_SCHEMA}") if ($ENV{DBI_SCHEMA});

$ENV{DBI_SCHEMA} can be a comma-separated list, as in:

	$dbh -> do("set search_path to my_schema, public");

See L<DBD::Pg> for details.

=head2 See Also

L<DBIx::Admin::CreateTable>.

L<DBIx::Admin::DSNManager>.

=head1 Version Numbers

Version numbers < 1.00 represent development versions. From 1.00 up, they are production versions.

=head1 Repository

L<https://github.com/ronsavage/DBIx-Admin-TableInfo>

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-Admin-TableInfo>.

=head1 Author

C<DBIx::Admin::TableInfo> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2004.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2004, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Perl License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
