package CGI::Application::Demo::Basic::Util::Create;

# Note:
#	o tab = 4 spaces || die
#
# Author:
#	Ron Savage <ron@savage.net.au>
#	Home page: http://savage.net.au/index.html

use strict;
use warnings;

use CGI::Application::Demo::Basic::Util::Config;

use DBI;

use DBIx::Admin::CreateTable;

use File::Slurp; # For read_file.

use FindBin::Real;

use Hash::FieldHash qw(:all);

fieldhash my %config           => 'config';
fieldhash my %config_file_name => 'config_file_name';
fieldhash my %creator          => 'creator';
fieldhash my %db_vendor        => 'db_vendor';
fieldhash my %dbh              => 'dbh';
fieldhash my %sequence         => 'sequence';

our $VERSION = '1.06';

# --------------------------------------------------

sub create_all_tables
{
	my($self) = @_;

	$self -> create_faculty_table;
	$self -> create_log_table;
	$self -> create_sessions_table;

	my($config) = CGI::Application::Demo::Basic::Util::Config -> new($self -> config_file_name) -> config;
	my($dsn)    = $$config{dsn};
	$dsn        =~ s/.+dbname=(.+)/$1/;

	if ($self -> db_vendor eq 'SQLITE')
	{
		`chmod a+w $dsn`;
	}

}	# End of create_all_tables.

# --------------------------------------------------

sub create_faculty_table
{
	my($self)        = @_;
	my($table_name)  = 'faculty';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table faculty
(
faculty_id $primary_key,
faculty_name varchar(255) not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_faculty_table.

# --------------------------------------------------

sub create_log_table
{
	my($self)          = @_;
	my($table_name)    = 'log';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table log
(
id $primary_key,
timestamp timestamp,
lvl varchar(9),
message varchar(255)
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_log_table.

# --------------------------------------------------
# Note: The sessions table is a special case.

sub create_sessions_table
{
	my($self) 		 = @_;
	my($table_name)	 = 'sessions';
	my($type)		 = $self -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($result)      = $self -> creator -> create_table(<<SQL);
create table sessions
(
id char(32) not null primary key,
a_session $type not null
)
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_sessions_table.

# --------------------------------------------------

sub drop_all_tables
{
	my($self) = @_;

	for my $table_name (qw/faculty log sessions/)
	{
		$self -> creator -> drop_table($table_name);
	}

}	# End of drop_all_tables.

# -----------------------------------------------

sub new
{
	my($class, $config_file_name) = @_;
	my($self) = bless({}, $class);

	die __PACKAGE__ . ". You must supply a value for 'config_file_name'" if (! $config_file_name);

	$self -> config_file_name($config_file_name);

	my($config)    = CGI::Application::Demo::Basic::Util::Config -> new($config_file_name) -> config;
	my($db_vendor) = $$config{'dsn'} =~ /[^:]+:([^:]+):/;

	$self -> db_vendor(uc $db_vendor);
	$self -> dbh(DBI -> connect
	(
		$$config{dsn},
		$$config{username},
		$$config{password},
		{
			AutoCommit  => $$config{AutoCommit},
			LongReadLen => $$config{LongReadLen},
			PrintError  => $$config{PrintError},
			RaiseError  => $$config{RaiseError},
		},
	) );

	$self -> creator(DBIx::Admin::CreateTable -> new(dbh => $self -> dbh) );

	return $self;

}	# End of new.

# -----------------------------------------------

sub populate_all_tables
{
	my($self) = @_;

	$self -> populate_faculty_table;

}	# End of populate_all_tables.

# -----------------------------------------------

sub populate_faculty_table
{
	my($self)	= @_;
	my($data)	= $self -> read_a_file('faculty.txt');
	my($sql)	= $self -> db_vendor eq 'ORACLE'
					? 'insert into faculty (faculty_id, faculty_name) values (faculty_seq.nextval, ?)'
					: 'insert into faculty (faculty_name) values (?)';
	my($sth)	= $self -> dbh -> prepare($sql);

	$sth -> execute($_) for @$data;
	$sth -> finish;

}	# End of populate_faculty_table.

# --------------------------------------------------
# Scripts using this will be command line scripts.
# Assumed directory structure:
#	./data/faculty.txt
#	./scripts/populate.pl

sub read_a_file
{
	my($self, $input_file_name)	= @_;
	$input_file_name			= FindBin::Real::Bin . "/../data/$input_file_name";

	return [grep{! /^$/ && ! /^#/} map{s/^\s+//; s/\s+$//; $_} read_file($input_file_name)];

}	# End of read_a_file.

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
		print "Table '$table_name' $message. \n";
	}

} # End of report.

# -----------------------------------------------

1;
