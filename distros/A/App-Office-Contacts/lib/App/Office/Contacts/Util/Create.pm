package App::Office::Contacts::Util::Create;

use strict;
use utf8;
use warnings;
use warnings  qw(FATAL utf8); # Fatalize encoding glitches.

use DBIx::Admin::CreateTable;

use FindBin;

use Moo;

use Perl6::Slurp; # For slurp().

extends 'App::Office::Contacts::Util::Logger';

has creator =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'DBIx::Admin::CreateTable',
	required => 0,
);

has engine =>
(
	default  => sub{return ''},
	is       => 'rw',
	#isa     => 'Str',
	required => 0,
);

has verbose =>
(
	default  => sub{return 0},
	is       => 'rw',
	#isa     => 'Int',
	required => 0,
);

our $VERSION = '2.04';

# -----------------------------------------------

sub BUILD
{
	my($self) = @_;

	$self -> creator
	(
		DBIx::Admin::CreateTable -> new
		(
			dbh     => $self -> simple -> dbh,
			verbose => 0,
		)
	);

	$self -> engine
	(
		$self -> creator -> db_vendor =~ /(?:Mysql)/i ? 'engine=innodb' : ''
	);

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
visibilities
communication_types
genders
report_entities
reports
yes_noes
titles
roles
people
organizations
spouses
email_address_types
phone_number_types
email_addresses
phone_numbers
email_organizations
email_people
phone_organizations
phone_people
occupation_titles
occupations
notes
/)
	{
		$method = "create_${table_name}_table";

		$self -> $method;
	}

	return 0;

}	# End of create_all_tables.

# --------------------------------------------------

sub create_communication_types_table
{
	my($self)        = @_;
	my($table_name)  = 'communication_types';
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

}	# End of create_communication_types_table.

# --------------------------------------------------

sub create_email_addresses_table
{
	my($self)        = @_;
	my($table_name)  = 'email_addresses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
email_address_type_id integer not null references email_address_types(id),
address varchar(255) not null,
upper_address varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_email_addresses_table.

# --------------------------------------------------

sub create_email_address_types_table
{
	my($self)        = @_;
	my($table_name)  = 'email_address_types';
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

}	# End of create_email_address_types_table.

# --------------------------------------------------

sub create_email_organizations_table
{
	my($self)        = @_;
	my($table_name)  = 'email_organizations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
email_address_id integer not null references email_addresses(id),
organization_id integer not null references organizations(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_email_organizations_table.

# --------------------------------------------------

sub create_email_people_table
{
	my($self)        = @_;
	my($table_name)  = 'email_people';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
email_address_id integer not null references email_addresses(id),
person_id integer not null references people(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_email_people_table.

# --------------------------------------------------

sub create_genders_table
{
	my($self)        = @_;
	my($table_name)  = 'genders';
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

}	# End of create_genders_table.

# --------------------------------------------------

sub create_log_table
{
	my($self)        = @_;
	my($table_name)  = 'log';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($type)        = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
level varchar(9) not null,
message $type not null,
timestamp timestamp not null default localtimestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_log_table.

# --------------------------------------------------

sub create_notes_table
{
	my($self)        = @_;
	my($table_name)  = 'notes';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
creator_id integer not null,
entity_id integer not null,
body text not null,
entity_type varchar(255) not null,
timestamp timestamp not null default localtimestamp
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_notes_table.

# --------------------------------------------------

sub create_occupation_titles_table
{
	my($self)        = @_;
	my($table_name)  = 'occupation_titles';
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

}	# End of create_occupation_titles_table.

# --------------------------------------------------

sub create_occupations_table
{
	my($self)        = @_;
	my($table_name)  = 'occupations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
creator_id integer not null,
occupation_title_id integer not null references occupation_titles(id),
organization_id integer not null references organizations(id),
person_id integer not null references people(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_occupations_table.

# --------------------------------------------------

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
communication_type_id integer not null references communication_types(id),
creator_id integer not null,
role_id integer not null references roles(id),
visibility_id integer not null references visibilities(id),
deleted integer not null,
facebook_tag varchar(255) not null,
homepage varchar(255) not null,
name varchar(255) not null,
timestamp timestamp not null default localtimestamp,
twitter_tag varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL

	$self -> simple -> query("create index ${table_name}_upper_name on $table_name (upper_name)");
	$self -> report($table_name, 'created', $result);

}	# End of create_organizations_table.

# --------------------------------------------------

sub create_people_table
{
	my($self)        = @_;
	my($table_name)  = 'people';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
communication_type_id integer not null references communication_types(id),
creator_id integer not null,
gender_id integer not null references genders(id),
role_id integer not null references roles(id),
title_id integer not null references titles(id),
visibility_id integer not null references visibilities(id),
date_of_birth timestamp not null default localtimestamp,
deleted integer not null,
facebook_tag varchar(255) not null,
given_names varchar(255) not null,
homepage varchar(255) not null,
name varchar(255) not null,
preferred_name varchar(255) not null,
surname varchar(255) not null,
timestamp timestamp not null default localtimestamp,
twitter_tag varchar(255) not null,
upper_given_names varchar(255) not null,
upper_name varchar(255) not null
) $engine
SQL

	$self -> simple -> query("create index ${table_name}_upper_name on $table_name (upper_name)");
	$self -> report($table_name, 'created', $result);

}	# End of create_people_table.

# --------------------------------------------------

sub create_phone_numbers_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_numbers';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
phone_number_type_id integer not null references phone_number_types(id),
number varchar(255) not null,
upper_number varchar(255) not null
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_phone_numbers_table.

# --------------------------------------------------

sub create_phone_number_types_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_number_types';
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

}	# End of create_phone_number_types_table.

# --------------------------------------------------

sub create_phone_organizations_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_organizations';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
organization_id integer not null references organizations(id),
phone_number_id integer not null references phone_numbers(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_phone_organizations_table.

# --------------------------------------------------

sub create_phone_people_table
{
	my($self)        = @_;
	my($table_name)  = 'phone_people';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
person_id integer not null references people(id),
phone_number_id integer not null references phone_numbers(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_phone_people_table.

# --------------------------------------------------

sub create_report_entities_table
{
	my($self)        = @_;
	my($table_name)  = 'report_entities';
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

}	# End of create_report_entities_table.

# --------------------------------------------------

sub create_reports_table
{
	my($self)        = @_;
	my($table_name)  = 'reports';
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

}	# End of create_reports_table.

# --------------------------------------------------

sub create_roles_table
{
	my($self)        = @_;
	my($table_name)  = 'roles';
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

}	# End of create_roles_table.

# -----------------------------------------------

sub create_sessions_table
{
	my($self)       = @_;
	my($table_name) = 'sessions';
	my($type)       = $self -> creator -> db_vendor eq 'ORACLE' ? 'long' : 'text';
	my($engine)      = $self -> engine;
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

sub create_spouses_table
{
	my($self)        = @_;
	my($table_name)  = 'spouses';
	my($primary_key) = $self -> creator -> generate_primary_key_sql($table_name);
	my($engine)      = $self -> engine;
	my($result)      = $self -> creator -> create_table(<<SQL);
create table $table_name
(
id $primary_key,
person_id integer not null references people(id),
spouse_id integer not null references people(id)
) $engine
SQL
	$self -> report($table_name, 'created', $result);

}	# End of create_spouses_table.

# --------------------------------------------------

sub create_titles_table
{
	my($self)        = @_;
	my($table_name)  = 'titles';
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

}	# End of create_titles_table.

# --------------------------------------------------

sub create_visibilities_table
{
	my($self)        = @_;
	my($table_name)  = 'visibilities';
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

}	# End of create_visibilities_table.

# --------------------------------------------------

sub create_yes_noes_table
{
	my($self)        = @_;
	my($table_name)  = 'yes_noes';
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

}	# End of create_yes_noes_table.

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
email_organizations
email_people
phone_organizations
phone_people
email_addresses
phone_numbers
occupations
occupation_titles
email_address_types
phone_number_types
notes
spouses
organizations
people
visibilities
communication_types
genders
reports
report_entities
titles
yes_noes
roles
sessions
log
/)
	{
		$self -> drop_table($table_name);
	}

	return 0;

}	# End of drop_all_tables.

# -----------------------------------------------

sub report
{
	my($self, $table_name, $message, $result) = @_;

	if ($result)
	{
		die "Error: Table '$table_name' $result. \n";
	}
	elsif ($self -> verbose)
	{
		$self -> log(info => "Table '$table_name' $message");
	}

}	# End of report.

# -----------------------------------------------

1;

=head1 NAME

App::Office::Contacts::Util::Create - A web-based contacts manager

=head1 Synopsis

See L<App::Office::Contacts/Synopsis>.

=head1 Description

L<App::Office::Contacts> implements a utf8-aware, web-based, private and group contacts manager.

=head1 Distributions

See L<App::Office::Contacts/Distributions>.

=head1 Installation

See L<App::Office::Contacts/Installation>.

=head1 Object attributes

Each instance of this class is a L<Moo>-based object, with these attributes:

=over 4

=item o creator

Is an object of type L<DBIx::Admin::CreateTable>.

=item o engine

Is a string holding - for MySQL - 'engine=innodb' and otherwise holding ''.

=item o verbose

Is a Boolean.

Further, each attribute name is also a method name.

=back

=head1 Methods

=head2 create_all_tables()

Calls create_*_table() for each table, in a special order so that foreign key relationships just work.

=head2 create_communication_types_table()

=head2 create_email_address_types_table()

=head2 create_email_addresses_table()

=head2 create_email_organizations_table()

=head2 create_email_people_table()

=head2 create_genders_table()

=head2 create_log_table()

=head2 create_notes_table()

=head2 create_occupation_titles_table()

=head2 create_occupations_table()

=head2 create_organizations_table()

=head2 create_people_table()

=head2 create_phone_number_types_table()

=head2 create_phone_numbers_table()

=head2 create_phone_organizations_table()

=head2 create_phone_people_table()

=head2 create_report_entities_table()

=head2 create_reports_table()

=head2 create_roles_table()

=head2 create_sessions_table()

=head2 create_spouses_table()

=head2 create_titles_table()

=head2 create_visibilities_table()

=head2 create_yes_noes_table()

=head2 creator()

Returns an object of type L<DBIx::Admin::CreateTable>.

=head2 drop_all_tables()

Calls drop_table($table_name) for all tables, in a special order, so foreign key relationships just work.

=head2 drop_table($table_name)

Drops the named table.

=head2 engine()

Returns a string, being 'engine=innodb' for MySQL and '' otherwise.

=head2 report($table_name, $message, $result)

Dies with an error message if there is one, otherwise prints a message (if verbose is 1).

=head2 verbose()

Returns a Boolean.

=head1 FAQ

See L<App::Office::Contacts/FAQ>.

=head1 Support

See L<App::Office::Contacts/Support>.

=head1 Author

C<App::Office::Contacts> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2013.

L<Home page|http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2013, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License V 2, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
