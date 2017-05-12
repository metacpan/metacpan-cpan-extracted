package Business::AU::Ledger::Util::Create;

# Documentation:
#	POD-style documentation is at the end. Extract it with pod2html.*.
#
# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>

use Business::AU::Ledger::Util::Config;

use Carp;

use DBIx::Admin::CreateTable;
use DBIx::Simple;

use Encode;

use FindBin::Real;

use Log::Dispatch;
use Log::Dispatch::DBI;

use Moose;

has config         => (is => 'rw', isa => 'HashRef');
has creator        => (is => 'rw', isa => 'DBIx::Admin::CreateTable');
has edit_types     => (is => 'rw', isa => 'HashRef');
has last_insert_id => (is => 'rw', isa => 'Int');
has logger         => (is => 'rw', isa => 'Log::Dispatch');
has simple         => (is => 'rw', isa => 'DBIx::Simple');
has table_names    => (is => 'rw', isa => 'HashRef');
has time_option    => (is => 'rw', isa => 'Str');
has verbose        => (is => 'rw', isa => 'Int');

use namespace::autoclean;

our $VERSION = '0.88';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> config(Business::AU::Ledger::Util::Config -> new -> config);

	my($config) = $self -> config;
	my($attr)   =
	{
		AutoCommit => $$config{'AutoCommit'},
		RaiseError => $$config{'RaiseError'},
	};

	$self -> simple(DBIx::Simple -> connect($$config{'dsn'}, $$config{'username'}, $$config{'password'}, $attr) );
	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> simple -> dbh, verbose => $self -> verbose) );
	$self -> time_option($self -> creator -> db_vendor =~ /(?:MySQL|Postgres)/i ? '(0) without time zone' : '');
	$self -> logger(Log::Dispatch -> new);
	$self -> logger -> add
	(
		Log::Dispatch::DBI -> new
		(
		 dbh       => $self -> simple -> dbh,
		 min_level => 'info',
		 name      => 'Ledger',
		)
	);

	$self;

}	# End of BUILD.

# -----------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	# Warning: The order is important.

	my($method);
	my($table_name);

	for $table_name (qw/
log
sessions
tx_details
tx_types
category_codes
gst_codes
months
reconciliations
payment_methods
payments
receipts
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

}	# End of create_all_tables.

# --------------------------------------------------

sub create_category_codes_table
{
	my($self)        = @_;
	my($table_name)  = 'category_codes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
tx_type_id integer references tx_types(id),
code varchar(255) not null,
name varchar(255) not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_category_codes_table.

# --------------------------------------------------

sub create_gst_codes_table
{
	my($self)        = @_;
	my($table_name)  = 'gst_codes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
tx_type_id integer references tx_types(id),
code varchar(255) not null,
name varchar(255) not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_gst_codes_table.

# --------------------------------------------------

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = 'log';
	my($time_option) = $self -> time_option;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
level varchar(9) not null,
message varchar(255) not null,
timestamp timestamp $time_option not null default current_timestamp
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_log_table.

# --------------------------------------------------

sub create_months_table
{
	my($self)        = @_;
	my($table_name)  = 'months';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
code varchar(255) not null,
name varchar(255) not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_months_table.

# --------------------------------------------------

sub create_payment_methods_table
{
	my($self)        = @_;
	my($table_name)  = 'payment_methods';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
code varchar(255) not null,
name varchar(255) not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_payment_methods_table.

# --------------------------------------------------

sub create_payments_table
{
	my($self)        = @_;
	my($table_name)  = 'payments';
	my($time_option) = $self -> time_option;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
category_code_id integer not null references category_codes(id),
gst_code_id integer not null references gst_codes(id),
month_id integer not null references months(id),
payment_method_id integer not null references payment_methods(id),
tx_detail_id integer not null references tx_details(id),
amount numeric(10, 2) not null,
comment varchar(255) not null,
gst_amount numeric(10, 2) not null,
petty_cash_in numeric(10, 2) not null,
petty_cash_out numeric(10, 2) not null,
private_use_amount numeric(10, 2) not null,
private_use_percent numeric(6, 2) not null,
reference varchar(255) not null,
timestamp timestamp $time_option not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_payments_table.

# --------------------------------------------------

sub create_receipts_table
{
	my($self)        = @_;
	my($table_name)  = 'receipts';
	my($time_option) = $self -> time_option;
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
category_code_id integer not null references category_codes(id),
gst_code_id integer not null references gst_codes(id),
month_id integer not null references months(id),
tx_detail_id integer not null references tx_details(id),
amount numeric(10, 2) not null,
bank_amount numeric(10, 2) not null,
comment varchar(255) not null,
gst_amount numeric(10, 2) not null,
reference varchar(255) not null,
timestamp timestamp $time_option not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_receipts_table.

# --------------------------------------------------

sub create_reconciliations_table
{
	my($self)        = @_;
	my($table_name)  = 'reconciliations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
code varchar(255) not null,
name varchar(255) not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_reconciliations_table.

# -----------------------------------------------

sub create_sessions_table
{
	my($self)       = @_;
	my($table_name) = 'sessions';
	my($type)       = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';

	$self -> creator -> create_table(<<SQL, {no_sequence => 1});
create table $table_name
(
id char(32) not null primary key,
a_session $type not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_sessions_table.

# --------------------------------------------------

sub create_tx_details_table
{
	my($self)        = @_;
	my($table_name)  = 'tx_details';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_tx_details_table.

# --------------------------------------------------

sub create_tx_types_table
{
	my($self)        = @_;
	my($table_name)  = 'tx_types';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);

	$self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
name varchar(255) not null
)
SQL
	$self -> log("Created table $table_name");

}	# End of create_tx_types_table.

# -----------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	my($table_name);

	for $table_name (qw/
split_cheques
receipts
payments
payment_methods
reconciliations
months
gst_codes
category_codes
tx_types
tx_details
sessions
log
/)
	{
		$self -> drop_table($table_name);
	}

}	# End of drop_all_tables.

# -----------------------------------------------

sub drop_table
{
	my($self, $table_name) = @_;

	$self -> creator -> drop_table($table_name);

} # End of drop_table.

# -----------------------------------------------

sub get_last_insert_id
{
	my($self, $table_name) = @_;

	$self -> last_insert_id($self -> simple -> dbh -> last_insert_id(undef, undef, $table_name, undef) );

}	# End of get_last_insert_id.

# -----------------------------------------------

sub log
{
	my($self, $s) = @_;

	$self -> logger -> log(level => 'info', message => $s ? $s : '');

}	# End of log.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	# Warning: The order of these calls is important.

	$self -> populate_tx_details_table;
	$self -> populate_tx_types_table;
	$self -> populate_category_codes_table;
	$self -> populate_gst_codes_table;
	$self -> populate_months_table;
	$self -> populate_payment_methods_table;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_category_codes_table
{
	my($self)       = @_;
	my($table_name) = 'category_codes';
	my($data)       = $self -> read_file("$table_name.txt");
	my($sql)        = "insert into $table_name";
	my(@type)       = $self -> read_tx_types_table;

	my(%id);

	for (@type)
	{
		$id{$$_{'name'} } = $$_{'id'};
	}

	my(@field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);

		$self -> transaction($table_name, $sql, {code => $field[1], name => $field[2], tx_type_id => $id{$field[0]} });
	}

	$self -> log("Populated table $table_name");

}	# End of populate_category_codes_table.

# -----------------------------------------------

sub populate_gst_codes_table
{
	my($self)       = @_;
	my($table_name) = 'gst_codes';
	my($data)       = $self -> read_file("$table_name.txt");
	my($sql)        = "insert into $table_name";
	my(@type)       = $self -> read_tx_types_table;

	my(%id);

	for (@type)
	{
		$id{$$_{'name'} } = $$_{'id'};
	}

	my(@field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);

		$self -> transaction($table_name, $sql, {code => $field[1], name => $field[2], tx_type_id => $id{$field[0]} });
	}

	$self -> log("Populated table $table_name");

}	# End of populate_gst_codes_table.

# -----------------------------------------------

sub populate_months_table
{
	my($self)       = @_;
	my($table_name) = 'months';
	my($data)       = $self -> read_file("$table_name.txt");
	my($sql)        = "insert into $table_name";

	my(@field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);

		$self -> transaction($table_name, $sql, {code => $field[0], name => $field[1]});
	}

	$self -> log("Populated table $table_name");

}	# End of populate_months_table.

# -----------------------------------------------

sub populate_payment_methods_table
{
	my($self)       = @_;
	my($table_name) = 'payment_methods';
	my($data)       = $self -> read_file("$table_name.txt");
	my($sql)        = "insert into $table_name";

	my(@field);

	for (@$data)
	{
		@field = split(/\s*,\s*/, $_);

		$self -> transaction($table_name, $sql, {code => $field[0], name => $field[1]});
	}

	$self -> log("Populated table $table_name");

}	# End of populate_payment_methods_table.

# -----------------------------------------------

sub populate_tx_details_table
{
	my($self)       = @_;
	my($table_name) = 'tx_details';
	my($data)       = $self -> read_file("$table_name.txt");
	my($sql)        = "insert into $table_name";

	for (@$data)
	{
		$self -> transaction($table_name, $sql, {name => $_});
	}

	$self -> log("Populated table $table_name");

}	# End of populate_tx_details_table.

# -----------------------------------------------

sub populate_tx_types_table
{
	my($self)       = @_;
	my($table_name) = 'tx_types';
	my($data)       = $self -> read_file("$table_name.txt");
	my($sql)        = "insert into $table_name";

	for (@$data)
	{
		$self -> transaction($table_name, $sql, {name => $_});
	}

	$self -> log("Populated table $table_name");

}	# End of populate_tx_types_table.

# --------------------------------------------------

sub read_file
{
	my($self, $input_file_name) = @_;
	$input_file_name            = FindBin::Real::Bin . "/../data/$input_file_name";

	open(INX, $input_file_name) || Carp::croak("Can't open($input_file_name): $!");
	my(@line) = grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} <INX>;
	close INX;
	chomp @line;

	return [@line];

}	# End of read_file.

# --------------------------------------------------

sub read_tx_types_table
{
	my($self) = @_;

	return $self -> simple -> query('select * from tx_types') -> hashes;

} # End of read_tx_types_table.

# --------------------------------------------------

sub transaction
{
	my($self, $table_name, $sql, $value) = @_;

	eval
	{
		$self -> simple -> begin;
		$self -> simple -> iquery($sql, $value);
		$self -> get_last_insert_id($table_name);
		$self -> simple -> commit;
	};

	if ($@)
	{
		eval{$self -> simple -> rollback};

		die $@;
	}

}	# End of transaction.

# -----------------------------------------------

__PACKAGE__ -> meta -> make_immutable;

1;
