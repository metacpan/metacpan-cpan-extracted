#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::Admin::TableInfo 2.10;

use Lingua::EN::PluralToSingular 'to_singular';

use Text::Table::Manifold ':constants';

# ---------------------

my($attr)              = {};
$$attr{sqlite_unicode} = 1 if ($ENV{DBI_DSN} =~ /SQLite/i);
my($dbh)               = DBI -> connect($ENV{DBI_DSN}, $ENV{DBI_USER}, $ENV{DBI_PASS}, $attr);
my($vendor_name)       = uc $dbh -> get_info(17);
my($info)              = DBIx::Admin::TableInfo -> new(dbh => $dbh) -> info;

$dbh -> do('pragma foreign_keys = on') if ($ENV{DBI_DSN} =~ /SQLite/i);

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
	format => format_internal_github,
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

	unshift @data, $index if ($index);

	$table -> data(\@data);

	print $table -> render_as_string, "\n\n";
}
