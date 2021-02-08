#!/usr/bin/env perl

use strict;
use warnings;

use DBI;
use DBIx::Admin::TableInfo 3.02;

use Lingua::EN::PluralToSingular 'to_singular';

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

print qq|"table_name","foreign_key","primary_table","primary_key"\n|;

my($column_name);
my($table_name);

for $fk_table_name (sort keys %foreign_key)
{
	for $fk_column_name (sort keys %{$foreign_key{$fk_table_name} })
	{
		for $table_name (sort keys %{$foreign_key{$fk_table_name}{$fk_column_name} })
		{
			$column_name = $foreign_key{$fk_table_name}{$fk_column_name}{$table_name};

			print qq|"$fk_table_name","$fk_column_name","$table_name","$column_name"\n|;
		}
	}
}
