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
