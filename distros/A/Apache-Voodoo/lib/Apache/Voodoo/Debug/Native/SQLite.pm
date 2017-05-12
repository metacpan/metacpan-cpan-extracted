package Apache::Voodoo::Debug::Native::SQLite;

$VERSION = "3.0200";

use strict;
use warnings;

use DBI;

use base("Apache::Voodoo::Debug::Native::common");

sub new {
	my $class = shift;
	my $self = {};

	bless $self,$class;

	$self->{version} = '1';

	return $self;
}

sub init_db {
	my $self = shift;

	my $dbh = shift;
	my $ac  = shift;

	# find the name of the connected database file
	my @f = grep {$_->[1] eq "main" } @{$dbh->selectall_arrayref("pragma database_list") || $self->db_error()};

	# make sure it's owned by apache
	chown($ac->apache_uid,$ac->apache_gid,$f[0]->[2]);

	$self->{dbh} = $dbh;

	my $tables = $dbh->selectcol_arrayref("
		SELECT
			name
		FROM
			sqlite_master
		WHERE
			type='table' AND
			name NOT LIKE 'sqlite%'
		") || $self->db_error();

	$self->debug($tables);
	if (grep {$_ eq 'version'} @{$tables}) {
		my $res = $dbh->selectall_arrayref("SELECT version FROM version") || $self->db_error();
		if ($res->[0]->[0] eq $self->{version}) {
			return;
		}
	}

	foreach my $table (@{$tables}) {
		$dbh->do("DROP TABLE $table") || $self->db_error();
	}

	$self->create_schema();
}

sub last_insert_id {
	my $self = shift;

	my $res = $self->{dbh}->selectall_arrayref("SELECT last_insert_rowid()") || $self->db_error();
	return $res->[0]->[0];
}

sub _pkey_syntax {
	return "integer not null primary key autoincrement";
}

1;

################################################################################
# Copyright (c) 2005-2010 Steven Edwards (maverick@smurfbane.org).
# All rights reserved.
#
# You may use and distribute Apache::Voodoo under the terms described in the
# LICENSE file include in this package. The summary is it's a legalese version
# of the Artistic License :)
#
################################################################################
