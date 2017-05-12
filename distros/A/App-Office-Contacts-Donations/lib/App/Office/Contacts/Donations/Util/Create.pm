package App::Office::Contacts::Donations::Util::Create;

use File::Slurp; # For read_file().

use FindBin::Real;

use Moose;

extends 'App::Office::Contacts::Util::Create';

use namespace::autoclean;

our $VERSION = '1.10';

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);
	my($table_name);

	for $table_name (qw/
currencies
donation_motives
donation_projects
donations
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

	return 0;

}	# End of create_all_tables.

# --------------------------------------------------

sub create_currencies_table
{
	my($self)        = @_;
	my($table_name)  = 'currencies';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
code varchar(255) not null,
name varchar(255) not null
)
SQL
	$self -> log(debug => "Created table $table_name");

}	# End of create_currencies_table.

# --------------------------------------------------

sub create_donation_motives_table
{
	my($self)        = @_;
	my($table_name)  = 'donation_motives';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> log(debug => "Created table $table_name");

}	# End of create_donation_motives_table.

# --------------------------------------------------

sub create_donation_projects_table
{
	my($self)        = @_;
	my($table_name)  = 'donation_projects';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> log(debug => "Created table $table_name");

}	# End of create_donation_projects_table.

# --------------------------------------------------

sub create_donations_table
{
	my($self)        = @_;
	my($table_name)  = 'donations';
	my($time_option) = $self -> time_option;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	# Note:
	# o currency_id_1 is input via menu. See amount_input.
	# o currency_id_2 is after any conversion. See amount_local.

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
creator_id integer not null,
currency_id_1 integer not null references currencies(id),
currency_id_2 integer not null references currencies(id),
donation_motive_id integer not null references donation_motives(id),
donation_project_id integer not null references donation_projects(id),
table_id integer not null,
table_name_id integer not null references table_names(id),
amount_input varchar(10) not null,
amount_local varchar(10) not null,
motive_text text,
project_text text,
timestamp timestamp $time_option not null default current_timestamp
)
SQL
	$self -> log(debug => "Created table $table_name");

}	# End of create_donations_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name (qw/
donations
currencies
donation_projects
donation_motives
/)
	{
		$self -> drop_table($table_name);
	}

	return 0;

}	# End of drop_all_tables.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	# Warning: The order of these calls is important.

	$self -> populate_currencies_table;
	$self -> populate_donation_motives_table;
	$self -> populate_donation_projects_table;
	$self -> populate_reports_table;
	$self -> populate_table_names_table; # Calls parent sub, uses local data file!

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_currencies_table
{
	my($self)       = @_;
	my($table_name) = 'currencies';
	my($data)       = $self -> read_a_file("$table_name.txt");
	my($sql)        = "insert into $table_name";

	my(@field, %field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);
		%field = map{($_ => shift @field)} (qw/code name/);

		$self -> db -> util -> insert_hash_get_id($table_name, \%field);
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_currencies_table.

# -----------------------------------------------

sub populate_donation_motives_table
{
	my($self)       = @_;
	my($table_name) = 'donation_motives';
	my($data)       = $self -> read_a_file("$table_name.txt");
	my($sql)        = "insert into $table_name";

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_donation_motives_table.

# -----------------------------------------------

sub populate_donation_projects_table
{
	my($self)       = @_;
	my($table_name) = 'donation_projects';
	my($data)       = $self -> read_a_file("$table_name.txt");
	my($sql)        = "insert into $table_name";

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_donation_projects_table.

# -----------------------------------------------

sub populate_reports_table
{
	my($self)       = @_;
	my($table_name) = 'reports';
	my($data)       = $self -> read_a_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> util -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_reports_table.

# -----------------------------------------------

sub read_a_file
{
	my($self, $input_file_name) = @_;
	$input_file_name = FindBin::Real::Bin . "/../data/$input_file_name";
	my(@line)        = read_file($input_file_name);

	chomp @line;

	return [grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} @line];

} # End of read_a_file.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
