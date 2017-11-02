package App::Office::CMS::Util::Create;

use strict;
use warnings;

use App::Office::CMS::Database;
use App::Office::CMS::Util::Config;

use DBIx::Admin::CreateTable;
use DBIx::Admin::TableInfo;

use File::Slurper 'read_lines';

use FindBin;

use Moo;

use Types::Standard qw/Any HashRef Str/;

extends 'App::Office::CMS::Database::Base';

has config =>
(
	is  => 'rw',
	isa => HashRef,
);

has creator =>
(
	is  => 'rw',
	isa => Any,
);

has db =>
(
	is  => 'rw',
	isa => Any,
);

has engine =>
(
	is  => 'rw',
	isa => Str,
);

has time_option =>
(
	is  => 'rw',
	isa => Str,
);

has verbose =>
(
	is  => 'rw',
	isa => Any,
);

our $VERSION = '0.93';

# -----------------------------------------------

sub BUILD
{
	my($self)   = @_;
	my($config) = App::Office::CMS::Util::Config -> new -> config;

	$self -> config($config);
	$self -> db(App::Office::CMS::Database -> new(config => $config) );
	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> db -> dbh, verbose => 0) );
	$self -> engine($self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : '');
	$self -> time_option($self -> creator -> db_vendor =~ /(?:Postgres)/i ? '(0) without time zone' : '');

}	# End of BUILD.

# -----------------------------------------------
# Well, all tables except the log table.

sub create_all_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);
	my($table_name);

	for $table_name (qw/
sessions
event_types
events
menu_orientations
os_types
sites
designs
asset_types
pages
menus
contents
assets
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

	return 0;

}	# End of create_all_tables.

# --------------------------------------------------

sub create_assets_table
{
	my($self)          = @_;
	my($table_name)    = 'assets';
	my($primary_key)   = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)        = $self -> engine;
	my($foreign_key_1) = $engine ? ', index (asset_type_id), foreign key (asset_type_id)' : '';
	my($foreign_key_2) = $engine ? ', index (design_id), foreign key (design_id)' : '';
	my($foreign_key_3) = $engine ? ', index (page_id), foreign key (page_id)' : '';
	my($foreign_key_4) = $engine ? ', index (site_id), foreign key (site_id)' : '';
	my($result)        = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
asset_type_id integer not null $foreign_key_1 references asset_types(id),
design_id integer not null $foreign_key_2 references designs(id) on delete cascade,
page_id integer not null $foreign_key_3 references pages(id) on delete cascade,
site_id integer not null $foreign_key_4 references sites(id) on delete cascade
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_assets_table.

# --------------------------------------------------

sub create_asset_types_table
{
	my($self)        = @_;
	my($table_name)  = 'asset_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
file_name varchar(255) not null,
file_path varchar(255) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_asset_types_table.

# --------------------------------------------------

sub create_contents_table
{
	my($self)          = @_;
	my($table_name)    = 'contents';
	my($primary_key)   = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)        = $self -> engine;
	my($foreign_key_1) = $engine ? ', index (design_id), foreign key (design_id)' : '';
	my($foreign_key_2) = $engine ? ', index (page_id), foreign key (page_id)' : '';
	my($foreign_key_3) = $engine ? ', index (site_id), foreign key (site_id)' : '';
	my($result)        = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
design_id integer not null $foreign_key_1 references designs(id) on delete cascade,
page_id integer not null $foreign_key_2 references pages(id) on delete cascade,
site_id integer not null $foreign_key_3 references sites(id) on delete cascade,
body_text text not null,
head_text text not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_contents_table.

# --------------------------------------------------

sub create_designs_table
{
	my($self)          = @_;
	my($table_name)    = 'designs';
	my($primary_key)   = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)        = $self -> engine;
	my($foreign_key_1) = $engine ? ', index (menu_orientation_id), foreign key (menu_orientation_id)' : '';
	my($foreign_key_2) = $engine ? ', index (os_type_id), foreign key (os_type_id)' : '';
	my($foreign_key_3) = $engine ? ', index (site_id), foreign key (site_id)' : '';
	my($result)        = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
menu_orientation_id integer not null $foreign_key_1 references menu_orientations(id),
os_type_id integer not null $foreign_key_2 references os_types(id) on delete cascade,
site_id integer not null $foreign_key_3 references sites(id) on delete cascade,
name varchar(255) not null,
output_directory varchar(255) not null,
output_doc_root varchar(255) not null,
upper_name varchar(255) not null,
unique (site_id, upper_name)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_designs_table.

# --------------------------------------------------

sub create_event_types_table
{
	my($self)        = @_;
	my($table_name)  = 'event_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_event_types_table.

# --------------------------------------------------

sub create_events_table
{
	my($self)        = @_;
	my($table_name)  = 'events';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
id_list varchar(255) not null,
timestamp timestamp $time_option not null default current_timestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_events_table.

# --------------------------------------------------

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = 'log';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($type)        = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($engine)      = $self -> engine;
	my($time_option) = $self -> time_option;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
level varchar(9) not null,
message $type not null,
timestamp timestamp $time_option not null default current_timestamp
) $engine
SQL

}	# End of create_log_table.

# --------------------------------------------------
# Note: The context for each site's design is stored in the pages table.
# See Tree::DAG_Node::Persist for details.
# Note: page_id can't be a foreign key for the pages table,
# because the root node has no corresponding page to point to.

sub create_menus_table
{
	my($self)        = @_;
	my($table_name)  = 'menus';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
mother_id integer not null,
page_id integer not null,
unique_id integer not null,
context varchar(255) not null,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_menus_table.

# --------------------------------------------------

sub create_menu_orientations_table
{
	my($self)        = @_;
	my($table_name)  = 'menu_orientations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_menu_orientations_table.

# --------------------------------------------------

sub create_os_types_table
{
	my($self)        = @_;
	my($table_name)  = 'os_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_os_types_table.

# --------------------------------------------------

sub create_pages_table
{
	my($self)          = @_;
	my($table_name)    = 'pages';
	my($primary_key)   = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)        = $self -> engine;
	my($foreign_key_1) = $engine ? ', index (design_id), foreign key (design_id)' : '';
	my($foreign_key_2) = $engine ? ', index (site_id), foreign key (site_id)' : '';
	my($result)        = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
design_id integer not null $foreign_key_1 references designs(id) on delete cascade,
site_id integer not null $foreign_key_2 references sites(id) on delete cascade,
context varchar(255) not null,
homepage varchar(3) not null,
name varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_pages_table.

# -----------------------------------------------

sub create_sessions_table
{
	my($self)       = @_;
	my($table_name) = 'sessions';
	my($engine)     = $self -> engine;
	my($type)       = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($result)     = $self -> creator -> create_table(<<SQL, {no_sequence => 1});
create table $table_name
(
id char(32) not null primary key,
a_session $type not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_sessions_table.

# --------------------------------------------------

sub create_sites_table
{
	my($self)        = @_;
	my($table_name)  = 'sites';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null,
upper_name varchar(255) not null,
unique (upper_name)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_sites_table.

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

	my($table_name);

	for $table_name (qw/
assets
contents
menus
pages
asset_types
designs
sites
os_types
menu_orientations
events
event_types
sessions
log
/)
	{
		$self -> drop_table($table_name);
	}

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

	my($record) = $self -> db -> dbh -> selectall_arrayref("select * from $table_name order by id", {Slice => {} });

	print "\t$table_name: \n";

	my($row);

	for $row (@$record)
	{
		print "\t";
		print map{"$_ => $$row{$_}. "} sort keys %$row;
		print "\n";
	}

	print "\n";

} # End of dump.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	# Warning: The order of these calls is important.

	$self -> populate_asset_types_table;
	$self -> populate_event_types_table;
	$self -> populate_menu_orientations_table;
	$self -> populate_os_types_table;

	return 0;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_asset_types_table
{
	my($self)       = @_;
	my($table_name) = 'asset_types';
	my($data)       = $self -> read_a_file("$table_name.txt");
	my($config)     = $self -> config;
	my($path)       = $$config{page_template_path};

	my(@field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);
		$self -> db -> insert_hash_get_id
		(
		 $table_name,
		 {
			 file_name  => $field[0],
			 file_path  => $path,
			 name       => $field[1],
			 upper_name => uc $field[1],
		 }
		);
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_asset_types_table.

# -----------------------------------------------

sub populate_event_types_table
{
	my($self)       = @_;
	my($table_name) = 'event_types';
	my($data)       = $self -> read_a_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> insert_hash_get_id
			(
			 $table_name,
			 {
				 name       => $_,
				 upper_name => uc $_,
			 }
			);
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_event_types_table.

# -----------------------------------------------

sub populate_menu_orientations_table
{
	my($self)       = @_;
	my($table_name) = 'menu_orientations';
	my($data)       = $self -> read_a_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_menu_orientations_table.

# -----------------------------------------------

sub populate_os_types_table
{
	my($self)       = @_;
	my($table_name) = 'os_types';
	my($data)       = $self -> read_a_file("$table_name.txt");

	for (@$data)
	{
		$self -> db -> insert_hash_get_id($table_name, {name => $_});
	}

	$self -> log(debug => "Populated table $table_name");
	$self -> dump($table_name);

}	# End of populate_os_types_table.

# -----------------------------------------------

sub read_a_file
{
	my($self, $input_file_name) = @_;
	$input_file_name = "$FindBin::Bin/../data/$input_file_name";
	my(@line)        = read_lines($input_file_name);

	chomp @line;

	return [grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} @line];

} # End of read_a_file.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Table '$table_name' $result";
	}
	elsif ($self -> verbose)
	{
		$self -> log(info => "Table '$table_name' $message");
	}

}	# End of report.

# -----------------------------------------------

sub report_all_tables
{
	my($self)      = @_;
	my($table_sth) = $self -> db -> dbh -> table_info(undef, 'public', '%', 'TABLE');

	my($count);
	my($table_data, $table_name);

	for $table_data (@{$table_sth -> fetchall_arrayref({})})
	{
		$table_name = $$table_data{'TABLE_NAME'};

		# For Postgres.

		next if ($table_name =~ /^(pg_|sql_)/);

		# For SQLite.

		next if ($table_name eq 'sqlite.sequence');

		$count = $self -> db -> dbh -> selectrow_hashref("select count(*) as count from $table_name");
		$count = defined($count) && $$count{'count'} ? $$count{'count'} : 0;

		print "Table: $table_name. Row count: $count. \n";
	}

}	# End of report_all_tables.

# -----------------------------------------------

1;
