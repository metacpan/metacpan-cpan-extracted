package DBIx::Admin::BackupRestore;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Reference:
#	Object Oriented Perl
#	Damian Conway
#	Manning
#	1-884777-79-1
#	P 114
#
# Note:
#	o Tab = 4 spaces || die.
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html
#
# Licence:
#	Australian copyright (c) 2003 Ron Savage.
#
#	All Programs of mine are 'OSI Certified Open Source Software';
#	you can redistribute them and/or modify them under the terms of
#	The Artistic License, a copy of which is available at:
#	http://www.opensource.org/licenses/index.html

use strict;
use warnings;

use Carp;
use File::Spec;
use XML::Records;

require 5.005_62;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DBIx::Admin::BackupRestore ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(

) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(

);
our $VERSION = '1.17';

my(%_decode_xml) =
(
	'&amp;'		=> '&',
	'&lt;'		=> '<',
	'&gt;'		=> '>',
	'&quot;'	=> '"',
);

my(%_encode_xml) =
(
	'&' => '&amp;',
	'<' => '&lt;',
	'>' => '&gt;',
	'"' => '&quot;',
);

# -----------------------------------------------

# Preloaded methods go here.

# -----------------------------------------------

# Encapsulated class data.

{
	my(%_attr_data) =
	(
		_clean					=> 0,
		_croak_on_error			=> 1,
		_dbh					=> '',
		_dbi_catalog			=> undef,
		_dbi_schema				=> undef,
		_dbi_table				=> '%',
		_dbi_type				=> 'TABLE',
		_fiddle_timestamp		=> 1,
		_odbc					=> 0,
		_output_dir_name		=> '',
		_rename_columns			=> {},
		_rename_tables			=> {},
		_skip_schema			=> [],
		_skip_tables			=> [],
		_transform_tablenames	=> 0,
		_verbose				=> 0,
	);

	sub _default_for
	{
		my($self, $attr_name) = @_;

		$_attr_data{$attr_name};
	}

	sub _standard_keys
	{
		keys %_attr_data;
	}

}	# End of encapsulated class data.

# -----------------------------------------------

sub adjust_case
{
	my($self, $s) = @_;

	$$self{'_dbh'}{'FetchHashKeyName'} eq 'NAME_uc' ? uc $s : $$self{'_dbh'}{'FetchHashKeyName'} eq 'NAME_lc' ? lc $s : $s;

}	# End of adjust_case.

# -----------------------------------------------

sub backup
{
	my($self, $database) = @_;

	Carp::croak('Missing parameter to new(): dbh') if (! $$self{'_dbh'});

	$$self{'_quote'}	= $$self{'_dbh'} ? $$self{'_dbh'} -> get_info(29) : ''; # SQL_IDENTIFIER_QUOTE_CHAR.
	$$self{'_tables'}	= $$self{'_odbc'} ? $self -> odbc_tables() : $self -> tables();
	$$self{'_xml'}		= qq|<?xml version = "1.0"?>\n|;
	$$self{'_xml'}		.= qq|<dbi database = "|. $self -> encode_xml($database) . qq|">\n|;

	my($column_name);
	my($data, $display_sql, $display_table);
	my($field);
	my($i);
	my($output_column_name);
	my($sql, $sth);
	my($table_name);
	my($xml);

	for $table_name (@{$$self{'_tables'} })
	{
		$self -> process_table('backup', $table_name);

		next if ($$self{'_skipping'});

		$display_table	= $self -> adjust_case($$self{'_current_table'});
		$sql			= "select * from $$self{'_current_table'}";
		$display_table	= $$self{'_rename_tables'}{$display_table} ? $$self{'_rename_tables'}{$display_table} : $display_table;
		$display_sql	= "select * from $display_table";
		$display_sql	= $self -> adjust_case($display_sql);
		$display_sql	= $self -> encode_xml($display_sql);
		$$self{'_xml'}	.= qq|\t<resultset statement = "$display_sql">\n|;
		$sth			= $$self{'_dbh'} -> prepare($sql) || Carp::croak("Can't prepare($sql): $DBI::errstr");

		eval{$sth -> execute()};

		if ($@)
		{
			Carp::croak("Can't execute($sql): $DBI::errstr") if ($$self{'_croak_on_error'});

			print STDERR "$@" if ($$self{'_verbose'});

			next;
		}

		$column_name							= $$sth{$$self{'_dbh'}{'FetchHashKeyName'} };
		$$self{'_column_name'}{$display_table}	= [map{$i = $$self{'_rename_columns'}{$_} ? $$self{'_rename_columns'}{$_} : $_; $i =~ tr/ /_/; $i} sort @$column_name];

		while ($data = $sth -> fetch() )
		{
			$i		= - 1;
			$xml	= '';

			for $field (@$data)
			{
				$i++;

				if (defined($field) )
				{
					$field				=~ tr/\x20-\x7E//cd if ($$self{'_clean'});
					$output_column_name	= $$self{'_rename_columns'}{$$column_name[$i]} ? $$self{'_rename_columns'}{$$column_name[$i]} : $$column_name[$i];
					$output_column_name	=~ tr/ /_/;
					$xml				.= "\t\t\t<$output_column_name>" . $self -> encode_xml($field) . '</' . $$column_name[$i] . ">\n";
				}
			}

			$$self{'_xml'} .= "\t\t<row>\n$xml\t\t</row>\n" if ($xml);
		}

		Carp::croak("Can't fetchrow_hashref($sql): $DBI::errstr") if ($DBI::errstr);

		$$self{'_xml'} .= "\t</resultset>\n";
	}

	$$self{'_xml'} .= "</dbi>\n";

}	# End of backup.

# -----------------------------------------------

sub decode_xml
{
	my($self, $s) = @_;

	for my $key (keys %_decode_xml)
	{
		$s =~ s/$key/$_decode_xml{$key}/eg;
	}

	$s;

}	# End of decode_xml.

# -----------------------------------------------

sub encode_xml
{
	my($self, $str)	= @_;
	$str			=~ s/([&<>"])/$_encode_xml{$1}/eg;

	$str;

}	# End of encode_xml.

# -----------------------------------------------

sub get_column_names
{
	my($self) = @_;

	$$self{'_column_name'};

}	# End of get_column_names.

# -----------------------------------------------

sub new
{
	my($class, %arg)	= @_;
	my($self)			= bless({}, $class);

	for my $attr_name ($self -> _standard_keys() )
	{
		my($arg_name) = $attr_name =~ /^_(.*)/;

		if (exists($arg{$arg_name}) )
		{
			$$self{$attr_name} = $arg{$arg_name};
		}
		else
		{
			$$self{$attr_name} = $self -> _default_for($attr_name);
		}
	}

	$$self{'_column_name'}		= {};
	$$self{'_current_schema'}	= '';
	$$self{'_current_table'}	= '';
	$$self{'_database'}			= [];
	$$self{'_key'}				= [];
	$$self{'_output_is_open'}	= 0;
	$$self{'_quote'}			= '';
	$$self{'_restored'}			= {};
	$$self{'_skipped'}			= {};
	$$self{'_skipping'}			= 0;
	@{$$self{'_skip_schema_name'} }{@{$$self{'_skip_schema'} } }	= (1) x @{$$self{'_skip_schema'} };
	@{$$self{'_skip_table_name'} }{@{$$self{'_skip_tables'} } }		= (1) x @{$$self{'_skip_tables'} };
	$$self{'_value'}			= [];
	$$self{'_xml'}				= '';

	return $self;

}	# End of new.

# -----------------------------------------------

sub odbc_tables
{
	my($self) = @_;

	[
		map{s/^$$self{'_quote'}.+?$$self{'_quote'}\.$$self{'_quote'}(.+)$$self{'_quote'}/$1/; $_}
		grep{! /^BIN\$.+\$./}	# Discard 'funny' Oracle table names, like BIN$C544WGedCuHgRAADuk1i5g==$0.
		sort $$self{'_dbh'} -> tables()
	];

}	# End of odbc_tables.

# -----------------------------------------------

sub process_table
{
	my($self, $action, $table_name) = @_;
	$$self{'_current_table'} = $self -> decode_xml($table_name);

	if ( ($$self{'_transform_tablenames'} == 1) && ($$self{'_current_table'} =~ /^(.+?)\.(.+)$/) )
	{
		$$self{'_current_schema'}	= $1;
		$$self{'_current_table'}	= $2;
	}

	if ($$self{'_skip_schema_name'}{$$self{'_current_schema'} } || $$self{'_skip_table_name'}{$$self{'_current_table'} })
	{
		# With restore_in_order we read the input file N times,
		# but we don't want to _report_ the same table N times.
		# Hence the hash $$self{'_skipped'}.

		print STDERR "Skip table: $$self{'_current_table'}. \n" if ($$self{'_verbose'} && ! $$self{'_skipped'}{$$self{'_current_table'} });

		$$self{'_skipping'}								= 1;
		$$self{'_skipped'}{$$self{'_current_table'} }	= 1;
	}
	else
	{
		# With restore_in_order we read the input file N times,
		# but we don't want to _report_ or _restore_ the same table N times.
		# Hence the hash $$self{'_restored'}.

		print STDERR "$action table: $$self{'_current_table'}. \n" if ($$self{'_verbose'} && ! $$self{'_restored'}{$$self{'_current_table'} });

		$$self{'_skipping'}								= 0;
		$$self{'_restored'}{$$self{'_current_table'} }	= 1;
	}

}	# End of process_table.

# -----------------------------------------------

sub restore
{
	my($self, $file_name) = @_;

	Carp::croak('Missing parameter to new(): dbh') if (! $$self{'_dbh'});

	open(INX, $file_name) || Carp::croak("Can't open($file_name): $!");

	my($line);

	while ($line = <INX>)
	{
		next if ($line =~ m!^(<\?xml|<dbi|</dbi)!i);

		if ($line =~ m!<resultset .+? from (.+)">!i)
		{
			$self -> process_table('Restore', $1);
		}
		elsif ( (! $$self{'_skipping'}) && ($line =~ m!<row>!i) )
		{
			# There may be a different number of fields from one row to the next.
			# Remember, only non-null fields are output by method backup().

			$$self{'_key'}		= [];
			$$self{'_value'}	= [];

			while ( ($line = <INX>) !~ m!</row>!i)
			{
				if ($line =~ m!^\s*<(.+?)>(.*?)</\1>!i)
				{
					push @{$$self{'_key'} }, $1;

					$self -> transform($1, $self -> decode_xml($2) );
				}
			}

			$self -> write_row();
		}
	}

	close INX;

	[sort keys %{$$self{'_restored'} }];

}	# End of restore.

# -----------------------------------------------

sub restore_in_order
{
	my($self, $input_file_name, $table) = @_;

	Carp::croak('Missing parameter to new(): dbh') if (! $$self{'_dbh'});

	my($table_name, $parser, $type, $record, $candidate_table, $row);

	for $table_name (@$table)
	{
		$parser = XML::Records -> new($input_file_name);

		$parser -> set_records('resultset');

		for (;;)
		{
			($type, $record) = $parser -> get_record();

			# Exit if no data found.

			last if (! $record);

			$candidate_table = $1 if ($$record{'statement'} =~ m!select \* from (.+)!);

			# Skip if the data is not for the 'current' table.

			next if ($candidate_table ne $table_name);

			# Skip if the data is not wanted.

			next if ($$self{'_skipping'});

			$self -> process_table('Restore', $candidate_table);

			# Warning: At this point, if the input file has no data for a table,
			# $$record{'row'} will be undef, so don't access @{$$record{'row'} }.

			next if (! $$record{'row'});

			# Warning. If the XML file contains 1 'record', XML::Records
			# returns text or a hash ref, not an array ref containing one element.
			# Due to the nature of our data, we can ignore the case of textual data.

			$$record{'row'} = [$$record{'row'}] if (ref $$record{'row'} ne 'ARRAY');

			for $row (@{$$record{'row'} })
			{
				# There may be a different number of fields from one row to the next.
				# Remember, only non-null fields are output by method backup().

				@{$$self{'_key'} }	= keys %$row;
				$$self{'_value'}	= [];

				$self -> transform($_, $$row{$_}) for @{$$self{'_key'} };
				$self -> write_row();
			}

			# Exit if table restored.

			last;
		}
	}

}	# End of restore_in_order.

# -----------------------------------------------

sub split
{
	my($self, $file_name) = @_;

	open(INX, $file_name) || Carp::croak("Can't open($file_name): $!");

	my($line, $table_name, $output_file_name);

	while ($line = <INX>)
	{
		next if ($line =~ m!^(<\?xml|</dbi)!i);

		if ($line =~ m!^<dbi database = "(.+)">!i)
		{
			$$self{'_database'} = $1;

			next;
		}

		if ($line =~ m!<resultset .+? from (.+)">!i)
		{
			$table_name = $1;

			$self -> process_table('Split', $table_name);

			# Close off the previous output file, if any.

			if ($$self{'_output_is_open'})
			{
				$$self{'_output_is_open'} = 0;

				print OUT qq|\t</resultset>\n|;
				print OUT qq|</dbi>\n|;

				close OUT;
			}

			if (! $$self{'_skipping'})
			{
				# Start the next output file.

				$output_file_name			= "$$self{'_current_table'}.xml";
				$output_file_name			= "$$self{'_current_schema'}.$output_file_name" if ($$self{'_current_schema'});
				$output_file_name			= File::Spec -> catdir($$self{'_output_dir_name'}, $output_file_name);
				$$self{'_output_is_open'}	= 1;

				open(OUT, "> $output_file_name") || Carp::croak("Can't open($output_file_name): $!");

				print OUT qq|<?xml version = "1.0"?>\n|;
				print OUT qq|<dbi database = "$$self{'_database'}">\n|;
				print OUT qq|\t<resultset statement = "select * from $table_name">\n|;
			}
		}
		elsif ( (! $$self{'_skipping'}) && ($line =~ m!<row>!i) )
		{
			# There may be a different number of fields from one row to the next.
			# Remember, only non-null fields are output by method backup().

			print OUT qq|\t\t<row>\n|;

			while ( ($line = <INX>) !~ m!</row>!i)
			{
				print OUT $line;
			}

			print OUT qq|\t\t</row>\n|;
		}
	}

	close INX;

	# Close off the previous file, if any.

	if ($$self{'_output_is_open'})
	{
		print OUT qq|\t</resultset>\n|;
		print OUT qq|</dbi>\n|;

		close OUT;
	}

	[sort keys %{$$self{'_restored'} }];

}	# End of split.

# -----------------------------------------------

sub tables
{
	my($self) = @_;

	[
		sort
		map{s/$$self{'_quote'}//g; $_}
		grep{! /^BIN\$.+\$./}	# Discard 'funny' Oracle table names, like BIN$C544WGedCuHgRAADuk1i5g==$0.
		map{$$_{'TABLE_NAME'} }
		@{$$self{'_dbh'}
		-> table_info($$self{'_dbi_catalog'}, $$self{'_dbi_schema'}, $$self{'_dbi_table'}, $$self{'_dbi_type'})
		-> fetchall_arrayref({})}
	];

}	# End of tables.

# -----------------------------------------------

sub transform
{
	my($self, $key, $value) = @_;

	if ($key =~ /timestamp/)
	{
		if ($$self{'_fiddle_timestamp'} & 0x01)
		{
			$value = '19700101' if ($value =~ /^0000/);
			$value = substr($value, 0, 4) . '-' . substr($value, 4, 2) . '-' . substr($value, 6, 2) . ' 00:00:00';
		}
		elsif ($$self{'_fiddle_timestamp'} & 0x02)
		{
			$value = '1970-01-01 00:00:00' if ($value =~ /^0000/);
		}

		if ($$self{'_fiddle_timestamp'} & 0x80)
		{
			$value = '1970-01-01 00:00:01' if ($value eq '1970-01-01 00:00:00');
		}
	}

	push @{$$self{'_value'} }, $value;

}	# End of transform.

# -----------------------------------------------

sub write_row
{
	my($self) = @_;

	if ($$self{'_skip_schema_name'}{$$self{'_current_schema'} } || $$self{'_skip_table_name'}{$$self{'_current_table'} })
	{
	}
	else
	{
		my($sql) = "insert into $$self{'_current_table'} (" . join(', ', @{$$self{'_key'} }) . ') values (' . join(', ', ('?') x @{$$self{'_key'} }) . ')';
		my($sth) = $$self{'_dbh'} -> prepare($sql) || Carp::croak("Can't prepare($sql): $DBI::errstr");

		$sth -> execute(@{$$self{'_value'} }) || Carp::croak("Can't execute($sql): $DBI::errstr");
		$sth -> finish();
	}

}	# End of write_row.

# -----------------------------------------------

1;

__END__

=head1 NAME

C<DBIx::Admin::BackupRestore> - Backup all tables in a database to XML, and restore them

=head1 Synopsis

	use DBIx::Admin::BackupRestore;

	# Backup.

	open(OUT, "> $file_name") || die("Can't open(> $file_name): $!");
	print OUT DBIx::Admin::BackupRestore -> new(dbh => $dbh) -> backup('db_name');
	close OUT;

	# Restore.

	DBIx::Admin::BackupRestore -> new(dbh => $dbh) -> restore($file_name);

=head1 Description

C<DBIx::Admin::BackupRestore> is a pure Perl module.

It exports all data - except nulls - in all tables from one database to one or more
XML files.

Actually, not all tables. Table names which match /^BIN\$.+\$./ are discarded.
This is for Oracle.

Then these files can be imported into another database, possibly under a different
database server, using methods C<restore()> or C<restore_in_order()>.

Note: Importing into Oracle does not handle sequences at all.

In the output, all table names and column names containing spaces have those spaces
converted to underscores. This is A Really Good Idea.

Also, the case of the output table and column names is governed by the database handle
attribute FetchHashKeyName.

Warning: This module is designed on the assumption you have a stand-alone script which
creates an appropriate set of empty tables on the destination database server.
You run that script, and then run this module in 'restore' mode.

Such a stand-alone script is trivial, by getting the output of method
C<get_column_names()> and feeding it into the constructor of
C<DBIx::Admin::CreateTrivialSchema>.

Of course, you would only use this feature as a crude way of dumping the data into a
database for quick inspection before processing the XML properly.

This module is used daily to transfer a MySQL database under MS Windows to a Postgres
database under GNU/Linux.

Similar modules are discussed below.

See also: http://savage.net.au/Ron/html/msaccess2rdbms.html

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules.html for details.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Constructor and initialization

new(...) returns an object of type C<DBIx::Admin::BackupRestore>.

This is the class's contructor.

Usage: DBIx::Admin::BackupRestore -> new().

This method takes a set of parameters. Only the dbh parameter is mandatory.

For each parameter you wish to use, call new as new(param_1 => value_1, ...).

=over 4

=item clean

The default value is 0.

If new is called as new(clean => 1), the backup phase deletes any characters outside
the range 20 .. 7E (hex).

The restore phase ignores this parameter.

This parameter is optional.

=item croak_on_error

This parameter takes one of these values: 0 or 1.

The default value is 1, for backwards compatibility.

During backup(), the $sth -> execute() is now wrapped in eval{}, and if
an error occurs, and croak_on_error is 1, we Carp::croak.

If croak_on_error is 0, we continue. Not only that, but if verbose is 1,
the error is printed to STDERR.

This parameter is optional.

=item dbh

This is a database handle.

This parameter is mandatory when calling methods C<backup()> and C<restore*()>,
but is not required when calling method C<split()>, since the latter is just a
file-to-file operation.

=item dbi_catalog, dbi_schema, dbi_table, dbi_type

These 4 parameters are passed to DBI's C<table_info()> method, to get a list of table
names.

The default values suit MySQL:

=over 4

=item dbi_catalog = undef

=item dbi_schema = undef

=item dbi_table = '%'

=item dbi_type = 'TABLE'

=back

For Oracle, use:

=over 4

=item dbi_catalog = undef

=item dbi_schema = uc $user

=item dbi_table = '%'

=item dbi_type = 'TABLE'

=back

That is, for Oracle you would call this module's constructor like so:

	$user = 'The user name used in the call to DBI -> connect(...)';
	new(dbh => $dbh, dbi_schema => uc $user);

For Postgres use:

=over 4

=item dbi_catalog = undef

=item dbi_schema = 'public'

=item dbi_table = '%'

=item dbi_type = 'TABLE'

=back

That is, for Postgres you would call this module's constructor like so:

	new(dbh => $dbh, dbi_schema => 'public');

=item fiddle_timestamp

This parameter takes one of these values: 0, 1 or 2, or any of those values + 128.

The 128 means the top (left-most) bit in the byte value of this parameter is set.

The default value is 1.

If the value of this parameter is 0, then C<restore()> does not fiddle the value of
fields whose names match /timestamp/.

If the value of the parameter is 1, then C<restore()> fiddles the value of fields
whose names match /timestamp/ in this manner:

	All values are assumed to be of the form /^YYYYMMDD/ (fake reg exps are nice!).
	Hours, minutes and seconds, if present, are ignored.
	Timestamps undergo either 1 or 2 transformations.
	Firstly, if the value matches /^0000/, convert it to 19700101.
	Then, all values are converted to YYYY-MM-DD 00:00:00.
	Eg: This - 00000000 - is converted to 1970-01-01 00:00:00
	and today - 20050415 - is converted to 2005-04-15 00:00:00.
	You would use this option when transferring data from MySQL's 'timestamp' type
	to Postgres' 'timestamp' type, and MySQL output values match /^(\d{8})/.

If the value of the parameter is 2, then C<restore()> fiddles the value of fields
whose names match /timestamp/ in this manner:

	Timestamps undergo either 0 or 1 transformations.
	If the value matches /^0000/, hours, minutes and seconds, if present, are ignored.
	If the value matches /^0000/, convert it to 1970-01-01 00:00:00.
	Values not matching that pattern are not converted.
	Eg: This - 0000-00-00 00:00:00 - is converted to 1970-01-01 00:00:00
	and today - 2005-04-15 09:34:00 - is not converted.
	You would use this option when transferring data from MySQL's 'datetime' type
	to Postgres' 'datetime' type, and some MySQL output values match
	0000-00-00 00:00:00/ and some values are real dates, such as 2005-04-15 09:34:00.

If the top bit is set, another fiddle takes place, after any of the above have occurred:

The timestamp is checked against 1970-01-01 00:00:00, and if they match, the timestamp
is changed to 1970-01-01 00:00:01. This extra second means the timestamp is now valid
under the strict option for MySQL V 5, whereas 1970-01-01 00:00:00 is invalid.

This parameter is optional.

=item odbc

This parameter takes one of these values: 0 or 1.

The default value is 0.

During backup, if odbc is 1 we use the simplified call $dbh -> tables()
to get the list of table names. This list includes what MS Access calls
Queries, which are possibly equivalent to views. MS Access does not
support the syntax used in the non-ODBC situation:
$dbh -> tables('%', '%', '%', 'table').

This parameter is optional.

=item rename_columns

This parameter takes a hash href.

You specify a hash ref in the form:

	rename_columns => {'old name' => 'new name', ...}.

For example, 'order' is a reserved word under MySQL, so you might use:

	rename_columns => {order => 'orders'}.

The option affects all tables.

The database handle attribute FetchHashKeyName affects this option.
Renaming takes place after the effect of FetchHashKeyName.

This parameter is optional.

=item rename_tables

This parameter takes a hash href.

You specify a hash ref in the form:

	rename_tables => {'old name' => 'new name', ...}.

The database handle attribute FetchHashKeyName affects this option.
Renaming takes place after the effect of FetchHashKeyName.

This parameter is optional.

=item skip_schema

The default value is [].

If new is called as new(skip_schema => ['some_schema_name']), the restore phase
does not restore any tables in the named schema.

Here, 'schema' is defined to be the prefix on a table name,
and to be separated from the table name by a '.'.

Note: You would normally use these options to port data from Postgres to MySQL:
new(skip_schema => ['information_schema', 'pg_catalog'], transform_tablenames => 1).

=item skip_tables

The default value is [].

If new is called as new(skip_tables => ['some_table_name', ...]), the restore phase
does not restore the tables named in the call to C<new()>.

This option is designed to work with CGI scripts using the module CGI::Sessions.

Now, the CGI script can run with the current CGI::Session data, and stale CGI::Session
data is not restored from the XML file.

See examples/backup-db.pl for a list of MS Access tables names which you are unlikely
to want to transfer to an RDBMS.

This parameter is optional.

=item transform_tablenames

The default value is 0.

The only other value currently recognized by this option is 1.

Now, new(transform_tablenames => 1) chops the schema, up to and including the first '.',
off table names. Thus a table exported from Postgres as 'public.service' can be
renamed 'service' when being imported into another database, eg MySQL.

Here, 'schema' is defined to be the prefix on a table name,
and to be separated from the table name by a '.'.

Note: You would normally use these options to port data from Postgres to MySQL:
new(skip_schema => ['information_schema', 'pg_catalog'], transform_tablenames => 1).

This parameter is optional.

=item verbose

The default value is 0.

If new is called as new(verbose => 1), the backup and restore phases both print the
names of the tables to STDERR.

When beginning to use this module, you are strongly encouraged to use the verbose option
as a progress monitor.

This parameter is optional.

=back

=head1 Method: backup($database_name)

Returns a potentially-huge string of XML.

You would normally write this straight to disk.

The database name is passed in here to help decorate the XML.

As of version 1.06, the XML tags are in lower case.

Method restore() will read a file containing upper or lower case tags.
Method restore_in_order() won't.

=head1 Method: get_column_names

This returns a hash ref, where the keys are table names, possibly transformed according
to the database handle attribute FetchHashKeyName, and the values are array refs of
column names, also converted according to FetchHashKeyName.

Note: All spaces in table names are converted to underscores.

Further, these column names are sorted, and all spaces in column names are converted
to underscores.

This hashref is acceptable to the module DBIx::Admin::CreateTrivialSchema :-).

=head1 Method: C<restore($file_name)>

Returns an array ref of imported table names. They are sorted by name.

Opens and reads the given file, presumably one output by a previous call to backup().

The data read in is used to populate database tables. Use method C<split()>
to output to disk files.

=head1 Method: C<restore_in_order($file_name, [array ref of table names])>

Returns nothing.

Opens and reads the given file, presumably one output by a previous call to backup().

The data read in is used to populate database tables. Use method C<split()>
to output to disk files.

Restores the tables in the order given in the array ref parameter.

This allows you to define a column with a clause such as 'references foreign_table
(foreign_column)', and to populate the foreign_table before the dependent table.

And no, mutually-dependent and self-referential tables are still not catered for.

And yes, it does read the file once per table. Luckily, XML::Records is fast.

But if this seems like too much overhead, see method C<split()>.

=head1 Method C<split($file_name)>

Returns an array ref of imported table names. They are sorted by name.

Opens and reads the given file, presumably one output by a previous call to backup().

Each table not being skipped is output to a separate disk file, with headers and footers
the same as output by method C<backup()>.

This means each file can be input to methods C<restore()> and C<restore_in_order()>.

The tables' schema names and table names are used to construct the file names, together
with an extension of '.xml'.

See examples/split-xml.pl and all-tables.xml for a demo.

Lastly, method C<split()> uses lower-case XML tags.

=head1 Example code

See the examples/ directory in the distro.

There are 2 demo programs:

=over 4

=item backup-db.pl

=item restore-db.pl

=back

=head1 FAQ

=over 4

=item Are there any known problems with this module?

Yes, two so far.

=over 4

=item Columns containing newline characters

The code ignores the column.

If newline characters were encoded as the 2 characters '\n', say, then when reading
the data back in, there would be the danger of that character sequence occurring
naturally in the data, but not when it represented a newline character. Hence the
program would wrongly decode '\n' as a newline in such cases.

So, escaping any character is always problematic.

=item Columns containing XML closing tags

The XML parser fails to handle such cases. So don't do that.

=back

=item Why do I get 'duplicate key' errors after restoring?

Most likely because:

=over 4

=item You are using Postgres or equivalent

=item You created a sequence

Eg: create sequence t_seq.

=item You created a table with the primary key referring to the sequence

Eg: create table t (t_id integer primary key default nextval('t_seq'), ...).

=item You populated the table

Let's say with 10 records, so the sequence is now at 10.

And the primary key field now contains the values 1 .. 10.

=item You exported the table with this module

Note: The export file contains the values 1 .. 10 in the primary key field.

=item You recreated the sequence

So the sequence is now at 1.

=item You recreated the table

=item You imported the data with this module

Note: Since the import file contains the values 1 .. 10 in the primary key field,
these values are used to populate the table, and the sequence's nextval() is never
called.

So the sequence is still at 1.

=item You tried to insert a record, which triggered a call to nextval()

But this call returns 1 (or perhaps 2), which is already in the table.

Hence the error about 'duplicate key'.

=back

=back

=head1 Related Modules

On CPAN I can see 4 modules which obviously offer similar features - there may be
others.

=over 4

=item DBIx::Copy

=item DBIx::Dump

=item DBIx::Migrate

=item DBIx::XML_RDB

=back

Of these, DBIx::XML_RDB is the only one I have experimented with. My thanks to Matt
Sergeant for that module.

I have effectively extended his module to automatically handle all tables, and to
handle importing too.

=head1 Author

C<DBIx::Admin::BackupRestore> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>>
in 2004.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2004, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
