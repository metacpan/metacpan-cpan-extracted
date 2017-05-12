#!/usr/bin/perl

use Class::Easy;

sub record_for {
	my $name = shift;
	my $prefix = shift || '';
	
	DBI::Easy::Helper->r (
		$name,
		prefix => 'Local::DBI::Easy',
		entity => "Local::DBI::Easy::${prefix}Entity"
	);
}

sub collection_for {
	my $name = shift;
	my $prefix = shift || '';
	
	DBI::Easy::Helper->r (
		$name,
		prefix => 'Local::DBI::Easy',
		entity => "Local::DBI::Easy::${prefix}Entity"
	);
	
	DBI::Easy::Helper->c (
		$name,
		prefix => 'Local::DBI::Easy',
		entity => "Local::DBI::Easy::${prefix}Entity::Collection"
	);
}

sub init_db {
	
	unlink "db.sqlite";

	my $db = $ENV{DBD} || 'sqlite';
	
	if ($db eq 'pg') {
	
		$ENV{DBI_DSN}  ||= 'DBI:Pg:dbname=perltests';
		$ENV{DBI_USER} ||= '';
		$ENV{DBI_PASS} ||= '';
	
	} elsif ($db eq 'mysql') {
	
		$ENV{DBI_DSN}  ||= 'DBI:mysql:database=test';
		$ENV{DBI_USER} ||= 'test';
		$ENV{DBI_PASS} ||= 's3kr1t';
	
	} elsif ($db eq 'sqlite') {

		$ENV{DBI_DSN}  ||= 'DBI:SQLite:dbname=db.sqlite';
		$ENV{DBI_USER} ||= '';
		$ENV{DBI_PASS} ||= '';
	
	}
	
	$::dbh = DBI->connect;
	
	my $serial_type   = 'integer';
	my $serial_suffix = 'autoincrement';
	my $date_col_type = 'integer';
	if ($ENV{DBI_DSN} =~ /^DBI:(?:mysql|pg)/i) {
		$serial_type = 'serial'; # 'integer';
		$serial_suffix = ''; # 'auto_increment';
		$date_col_type = 'timestamp';
	}
	
	$::dbh->do ('drop table if exists account');
	# without prefix
	$::dbh->do (qq[
		create table account (
			account_id $serial_type primary key $serial_suffix,
			name text not null,
			pass text,
			meta text,
			created_date $date_col_type
		);
	]);
	
	# prefixed
	
	$::dbh->do ('drop table if exists contact');
	$::dbh->do (qq[create table contact (
			contact_id $serial_type primary key $serial_suffix,
			contact_type text,
			contact_value text,
			contact_active integer default 1,
			account_id integer not null
		);
	]);
	
	$::dbh->do ('drop table if exists passport');
	$::dbh->do (qq[create table passport (
			id $serial_type primary key $serial_suffix,
			passport_type text,
			passport_value text,
			account_id integer not null
		);
	]);

	$::dbh->do ('drop table if exists address');
	$::dbh->do (qq[create table address (
			address_id $serial_type primary key $serial_suffix,
			address_country text,
			address_city text,
			address_line text
		);
	]);
	
	$::dbh->do ('drop table if exists account_address');
	$::dbh->do (qq[create table account_address (
			account_id integer not null,
			address_id integer not null
		);
	]);
	
	$::dbh->do ('drop table if exists smf_users');
	# without prefix
	$::dbh->do (qq[
		create table smf_users (
			id_user $serial_type primary key $serial_suffix,
			name text not null,
			pass text not null,
			meta text
		);
	]);
	
	
	return $::dbh;
}

sub finish_db {
	unlink "db.sqlite"
		unless $ENV{DEBUG};
}

1;


package Local::DBI::Easy::Entity;

use Class::Easy;

use base qw(DBI::Easy::Record);

our $wrapper = 1;

sub _init_db {
	my $self = shift;
	
	$self->dbh ($::dbh);
}

1;

package Local::DBI::Easy::Entity::Collection;

use Class::Easy;

use base qw(DBI::Easy::Record::Collection);

our $wrapper = 1;

sub _init_db {
	my $self = shift;
	
	$self->dbh ($::dbh);
}

1;

package Local::DBI::Easy::ForumEntity;

use Class::Easy;

use base qw(DBI::Easy::Record);

our $wrapper = 1;

sub common_table_prefix {'smf_'}

sub _init_db {
	my $self = shift;
	
	$self->dbh ($::dbh);
}

1;

package Local::DBI::Easy::ForumEntity::Collection;

use Class::Easy;

use base qw(DBI::Easy::Record::Collection);

our $wrapper = 1;

sub common_table_prefix {'smf_'}

sub _init_db {
	my $self = shift;
	
	$self->dbh ($::dbh);
}

1;