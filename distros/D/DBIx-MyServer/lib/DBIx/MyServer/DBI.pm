package DBIx::MyServer::DBI;
@ISA = qw(DBIx::MyServer);

use warnings;
use strict;
use DBI;
use DBIx::MyServer;

use constant MYSERVER_SQLTYPES => 30;

#
# During handshake, we may still issue SQL commands however we do not send the responses back to the client
#

use constant IN_HANDSHAKE => 1;

1;

sub comQuery {
### DBIx-MyServer-DBI-comQuery...
	my ($myserver, $query_text, $in_handshake) = @_;
#### $query_text
	my $dbh = $myserver->getDbh();

	my $sth = $dbh->prepare($query_text);

	return $myserver->sendErrorFromDBI($dbh) if not defined $sth;

	my $affected_rows = $sth->execute();
	$affected_rows = 0 if defined $affected_rows && $affected_rows eq '0E0';
	my $err = $sth->err();
	if (defined $err) {
		my $send_result = $myserver->sendErrorFromDBI($sth);
		return (defined $send_result) ? $query_text : undef;
	} elsif ((not defined $sth->{NUM_OF_FIELDS}) || ($sth->{NUM_OF_FIELDS} == 0)) {
		my $send_result = (not $in_handshake) ? $myserver->sendOK($dbh->{'mysql_info'}, $affected_rows, $sth->{mysql_insertid}, $sth->{'mysql_warning_count'}) : 1;
		return (defined $send_result) ? $query_text : undef;
	} else {
		my @definitions = map {
			my $flags = 0;
			$flags = $flags | DBIx::MyServer::NOT_NULL_FLAG if not $sth->{NULLABLE}->[$_];
			$flags = $flags | DBIx::MyServer::BLOB_FLAG if $sth->{mysql_is_blob}->[$_];
			$flags = $flags | DBIx::MyServer::UNIQUE_KEY_FLAG if $sth->{mysql_is_key}->[$_];
			$flags = $flags | DBIx::MyServer::PRI_KEY_FLAG if $sth->{mysql_is_pri_key}->[$_];
			$flags = $flags | DBIx::MyServer::AUTO_INCREMENT_FLAG if $sth->{mysql_is_auto_increment}->[$_];

			$myserver->newDefinition(
				name => $sth->{NAME}->[$_],
				type => $myserver->getSQLType($sth->{TYPE}->[$_]),
				length => $sth->{mysql_length}->[$_],
				flags => $flags
			);
		} (0..$sth->{NUM_OF_FIELDS}-1);

		return ($query_text, \@definitions, $sth->fetchall_arrayref());
	}
}

#
# comFieldList() converts the information provided from $dbh->column_info() into the format required by DBIx::MyServer
#


sub comFieldList {
### DBIx-MyServer-DBI-comFieldList()...
	my ($myserver, $table_name) = @_;
#### $table_name

	my $dbh = $myserver->[DBIx::MyServer::MYSERVER_DBH];
	my $sth = $dbh->column_info(undef, undef, $table_name, '%');

	return $myserver->sendErrorFromDBI($dbh) if not defined $sth;
	return $myserver->sendErrorFromDBI($sth) if $sth->err();

	my @definitions;
	while (my $hash_ref = $sth->fetchrow_hashref()) {
		push @definitions, $myserver->newDefinition(
			catalog => $hash_ref->{TABLE_CAT},
			database => $hash_ref->{TABLE_SCHEM},
			table => $hash_ref->{TABLE_NAME},
			org_table => $hash_ref->{TABLE_NAME},
			name => $hash_ref->{COLUMN_NAME},
			org_name => $hash_ref->{COLUMN_NAME},
			length => $hash_ref->{COLUMN_SIZE},
			type => $myserver->getSQLType($hash_ref->{DATA_TYPE}),
			decimals => $hash_ref->{DECIMAL_DIGITS},
			default => $hash_ref->{COLUMN_DEF}
		);
	};

	#
	# Please note we manually send the definitions here without header and with EOF
	#

	$myserver->sendDefinitions(\@definitions,1);
	return $myserver->sendEOF();
}

#
# authorise() calls the default authorization handler from DBIx::MyServer. If a DBI handle is available at connection
# establishment time and the client requested a connection to a specific database, we issue a USE statement to switch
# to that database. If the client has requested a utf8 character set, we set the DBI server accordingly.
#

sub authorize {
        my ($myserver, $remote_host, $username, $database) = @_;

	if (DBIx::MyServer::authorize(@_)) {
		my $dbh = $myserver->getDbh();
		return 1 if not defined $dbh;
		if ($dbh->{Driver}->{Name} eq 'mysql') {
			return undef if defined $database && not defined $myserver->comQuery("USE $database", IN_HANDSHAKE);
			return undef if $myserver->getClientCharset() == 33 && not defined $myserver->comQuery("SET NAMES utf8", IN_HANDSHAKE);
		}
	} else {
		return undef;
	}
}

sub new {
	my $myserver = DBIx::MyServer::new(@_);

	my $dbh = $myserver->getDbh();

	$myserver->setupSQLTypes() if defined $dbh;

	return $myserver;
}

sub setupSQLTypes {
	my $myserver = shift;
	my $dbh = $myserver->getDbh();
	if (defined $dbh) {
		my @type_info = @{$dbh->type_info_all()};

		my $sql_col = $type_info[0]->{DATA_TYPE};
		my $mysql_col = $type_info[0]->{mysql_native_type};
	
		foreach my $type (@type_info[1..$#type_info]) {
			my $sql_value = $type->[$sql_col];
			my $mysql_value = $type->[$mysql_col];
	
			# We use hash rather than array here because $sql_value may be negative
			$myserver->[MYSERVER_SQLTYPES]->{$sql_value} = $mysql_value;
		}
		return 1;
	} else {
		return 0;
	}
}

sub getSQLType {
	my ($myserver, $type) = @_;
	$myserver->setupSQLTypes() if not defined $myserver->[MYSERVER_SQLTYPES];
	return $myserver->[MYSERVER_SQLTYPES]->{$type};
}

sub sendErrorFromDBI {
	my ($myserver, $h) = @_;
	$myserver->sendError($h->errstr(), $h->err(), $h->state());

}

1;

__END__

=head1 NAME

DBIx::MyServer::DBI - Perl server that speaks the MySQL protocol and then executes the received queries via DBI

=head1 SYNOPSIS

	Please see the examples/dbi.pl file for a working demonstration

=head1 DESCRIPTION

This module inherits from L<DBIx::MyServer> and allows one to create a "fake" MySQL server that accepts queries, which
are then forwarded to another server via DBI. The query results are then sent back to the client.

This module serves as an example on how to create useful L<DBIx::MyServer> servers and can be used to make any DBI data
source available to applications which can connect to or import from a MySQL data source, which includes all ODBC-enabled
applications.

Please note that if you L<fork()> children, you will need an individual DBI handle for each one. You can obtain such a handle
by calling C<clone()> on the parent DBI handle. A new database connection will probably be established for each clone.
