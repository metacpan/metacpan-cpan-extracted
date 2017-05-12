package DBIx::Tree::Persist::Create;

use strict;
use warnings;

use DBI;

use DBIx::Admin::CreateTable;

use DBIx::Tree::Persist::Config;

use File::Slurp; # For read_file.

use FindBin;

use Hash::FieldHash ':all';

fieldhash my %creator => 'creator';
fieldhash my %dbh     => 'dbh';
fieldhash my %verbose => 'verbose';

our $VERSION = '1.04';

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	$self -> create_one_table;
	$self -> create_two_table;

	return 0;

}	# End of create_all_tables.

# --------------------------------------------------
# Note: parent_id is not 'not null', because Tree::Persist
# stores a null as the parent of the root.
# Note: If parent_id is 'references two(id)', then it cannot
# be set to 0 for the root, because id 0 does not exist.
# However, by omitting 'references two(id)', the parent_id
# of the root can be (manually) set to 0, and Tree::Persist
# still reads in the tree properly.

sub create_one_table
{
	my($self)        = @_;
	my($table_name)  = 'one';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
parent_id integer,
class varchar(255) not null,
value varchar(255)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_one_table.

# --------------------------------------------------
# Note: parent_id is not 'not null', because Tree::Persist
# stores a null as the parent of the root.
# Note: If parent_id is 'references two(id)', then it cannot
# be set to 0 for the root, because id 0 does not exist.
# However, by omitting 'references two(id)', the parent_id
# of the root can be (manually) set to 0, and Tree::Persist
# still reads in the tree properly.

sub create_two_table
{
	my($self)        = @_;
	my($table_name)  = 'two';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
parent_id integer not null,
class varchar(255) not null,
value varchar(255)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_two_table.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);

} # End of drop_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	$self -> drop_table('one');
	$self -> drop_table('two');

	return 0;

}	# End of drop_all_tables.

# -----------------------------------------------

sub dump
{
	my($self, $table_name) = @_;

	if (! $self -> verbose)
	{
		return;
	}

	my($record) = $self -> dbh -> selectall_arrayref("select * from $table_name order by id", {Slice => {} });

	print "$table_name: \n";

	my($row);

	for $row (@$record)
	{
		print map{"$_ => $$row{$_}. "} sort keys %$row;
		print "\n";
	}

	print "\n";

} # End of dump.

# -----------------------------------------------

sub insert_hash
{
	my($self, $table_name, $field_values) = @_;

	my(@fields) = sort keys %$field_values;
	my(@values) = @{$field_values}{@fields};
	my($sql)    = sprintf 'insert into %s (%s) values (%s)', $table_name, join(',', @fields), join(',', ('?') x @fields);

	$self -> dbh -> do($sql, {}, @values);

} # End of insert_hash.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;
	$s = $s || '';

	if ($self -> verbose)
	{
		print "$s\n";
	}

} # End of log.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;
	$arg{verbose}    ||= 0;
	my($self)        = from_hash(bless({}, $class), \%arg);
	my($config)      = DBIx::Tree::Persist::Config -> new -> config;
	my(@dsn)         = ($$config{dsn}, $$config{username}, $$config{password});
	my($attr)        = {};

	$self -> dbh(DBI -> connect(@dsn, $attr) );
	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> dbh, verbose => 0) );

	return $self;

}	# End of new.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	# Warning: The order of these calls is important.

	$self -> populate_two_table;

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------
# Note: We use 0, not null, as the parent of the root.
# See comments to sub create_one_table() for more detail.

sub populate_two_table
{
	my($self)       = @_;
	my($table_name) = 'two';
	my($data)       = $self -> read_a_file("$table_name.txt");

	my(@field);
	my($id);
	my($parent_id);

	for (@$data)
	{
		@field     = split(/\s+/, $_);
		$parent_id = pop @field;
		$id        = pop @field;
		$self -> insert_hash
			(
			 $table_name,
			 {
				 class     => 'Tree',
				 id        => $id,
				 parent_id => $parent_id eq 'NULL' ? 0 : $parent_id,
				 value     => join(' ', @field),
			 }
			);
	}

	$self -> log("Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_two_table.

# -----------------------------------------------

sub read_a_file
{
	my($self, $input_file_name) = @_;
	$input_file_name = "$FindBin::Bin/../data/$input_file_name";
	my(@line)        = read_file($input_file_name);

	chomp @line;

	return [grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} @line];

} # End of read_a_file.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Table '$table_name' $result\n";
	}
	else
	{
		$self -> log("Table '$table_name' $message");
	}

}	# End of report.

# -----------------------------------------------

sub report_all_tables
{
	my($self)      = @_;
	my($table_sth) = $self -> dbh -> table_info(undef, 'public', '%', 'TABLE');

	my($count);
	my($table_data, $table_name);

	for $table_data (@{$table_sth -> fetchall_arrayref({})})
	{
		$table_name = $$table_data{'TABLE_NAME'};

		# For Postgres.

		next if ($table_name =~ /^(pg_|sql_)/);

		# For SQLite.

		next if ($table_name eq 'sqlite.sequence');

		$count = $self -> dbh -> selectrow_hashref("select count(*) as count from $table_name");
		$count = defined($count) && $$count{'count'} ? $$count{'count'} : 0;

		print "Table: $table_name. Row count: $count. \n";
	}

}	# End of report_all_tables.

# -----------------------------------------------

1;
