package DBD::mysqlPP;
use strict;

use DBI;
use Carp;
use vars qw($VERSION $err $errstr $state $drh);

$VERSION = '0.07';
$err = 0;
$errstr = '';
$state = undef;
$drh = undef;

sub driver
{
	return $drh if $drh;

	my $class = shift;
	my $attr  = shift;
	$class .= '::dr';

	$drh = DBI::_new_drh($class, {
		Name        => 'mysqlPP',
		Version     => $VERSION,
		Err         => \$DBD::mysqlPP::err,
		Errstr      => \$DBD::mysqlPP::errstr,
		State       => \$DBD::mysqlPP::state,
		Attribution => 'DBD::mysqlPP by Hiroyuki OYAMA',
	}, {});
}


sub _parse_dsn
{
	my $class = shift;
	my ($dsn, $args) = @_;
	my($hash, $var, $val);
	return if ! defined $dsn;

	while (length $dsn) {
		if ($dsn =~ /([^:;]*)[:;](.*)/) {
			$val = $1;
			$dsn = $2;
		}
		else {
			$val = $dsn;
			$dsn = '';
		}
		if ($val =~ /([^=]*)=(.*)/) {
			$var = $1;
			$val = $2;
			if ($var eq 'hostname' || $var eq 'host') {
				$hash->{'host'} = $val;
			}
			elsif ($var eq 'db' || $var eq 'dbname') {
				$hash->{'database'} = $val;
			}
			else {
				$hash->{$var} = $val;
			}
		}
		else {
			for $var (@$args) {
				if (!defined($hash->{$var})) {
					$hash->{$var} = $val;
					last;
				}
			}
		}
	}
	return $hash;
}


sub _parse_dsn_host
{
	my($class, $dsn) = @_;
	my $hash = $class->_parse_dsn($dsn, ['host', 'port']);
	($hash->{'host'}, $hash->{'port'});
}



package DBD::mysqlPP::dr;

$DBD::mysqlPP::dr::imp_data_size = 0;

use Net::MySQL;
use strict;


sub connect
{
	my $drh = shift;
	my ($dsn, $user, $password, $attrhash) = @_;

	my $data_source_info = DBD::mysqlPP->_parse_dsn(
		$dsn, ['database', 'host', 'port'],
	);
	$user     ||= '';
	$password ||= '';

	my $dbh = DBI::_new_dbh($drh, {
		Name         => $dsn,
		USER         => $user,
		CURRENT_USRE => $user,
	}, {});
	eval {
		my $mysql = Net::MySQL->new(
			hostname => $data_source_info->{host},
			port     => $data_source_info->{port},
			database => $data_source_info->{database},
			user     => $user,
			password => $password,
			debug    => $attrhash->{protocol_dump},
		);
		$dbh->STORE(mysqlpp_connection => $mysql);
		$dbh->STORE(thread_id => $mysql->{server_thread_id});
	};
	if ($@) {
		return $dbh->DBI::set_err(1, $@);
	}
	return $dbh;
}


sub data_sources
{
	return ("dbi:mysqlPP:");
}


sub disconnect_all {}



package DBD::mysqlPP::db;

$DBD::mysqlPP::db::imp_data_size = 0;
use strict;


# Patterns referred to 'mysql_sub_escape_string()' of libmysql.c
sub quote
{
	my $dbh = shift;
	my ($statement, $type) = @_;
	return 'NULL' unless defined $statement;

	for ($statement) {
		s/\\/\\\\/g;
		s/\0/\\0/g;
		s/\n/\\n/g;
		s/\r/\\r/g;
		s/'/\\'/g;
		s/"/\\"/g;
		s/\x1a/\\Z/g;
	}
	return "'$statement'";
}

sub _count_param
{
	my @statement = split //, shift;
	my $num = 0;

	while (defined(my $c = shift @statement)) {
		if ($c eq '"' || $c eq "'") {
			my $end = $c;
			while (defined(my $c = shift @statement)) {
				last if $c eq $end;
				@statement = splice @statement, 2 if $c eq '\\';
			}
		}
		elsif ($c eq '?') {
			$num++;
		}
	}
	return $num;
}

sub prepare
{
	my $dbh = shift;
	my ($statement, @attribs) = @_;

	my $sth = DBI::_new_sth($dbh, {
		Statement => $statement,
	});
	$sth->STORE(mysqlpp_handle => $dbh->FETCH('mysqlpp_connection'));
	$sth->STORE(mysqlpp_params => []);
	$sth->STORE(NUM_OF_PARAMS => _count_param($statement));
	$sth;
}


sub commit
{
	my $dbh = shift;
	if ($dbh->FETCH('Warn')) {
		warn 'Commit ineffective while AutoCommit is on';
	}
	1;
}


sub rollback
{
	my $dbh = shift;
	if ($dbh->FETCH('Warn')) {
		warn 'Rollback ineffective while AutoCommit is on';
	}
	1;
}


sub tables
{
	my $dbh = shift;
	my @args = @_;
	my $mysql = $dbh->FETCH('mysqlpp_connection');

	my @database_list;
	eval {
		$mysql->query('show tables');
		die $mysql->get_error_message if $mysql->is_error;
		if ($mysql->has_selected_record) {
			my $record = $mysql->create_record_iterator;
			while (my $db_name = $record->each) {
				push @database_list, $db_name->[0];
			}
		}
	};
	if ($@) {
		warn $mysql->get_error_message;
	}
	return $mysql->is_error
		? undef
		: @database_list;
}


sub _ListDBs
{
	my $dbh = shift;
	my @args = @_;
	my $mysql = $dbh->FETCH('mysqlpp_connection');

	my @database_list;
	eval {
		$mysql->query('show databases');
		die $mysql->get_error_message if $mysql->is_error;
		if ($mysql->has_selected_record) {
			my $record = $mysql->create_record_iterator;
			while (my $db_name = $record->each) {
				push @database_list, $db_name->[0];
			}
		}
	};
	if ($@) {
		warn $mysql->get_error_message;
	}
	return $mysql->is_error
		? undef
		: @database_list;
}


sub _ListTables
{
	my $dbh = shift;
	return $dbh->tables;
}


sub disconnect
{
	return 1;
}


sub FETCH
{
	my $dbh = shift;
	my $key = shift;

	return 1 if $key eq 'AutoCommit';
	return $dbh->{$key} if $key =~ /^(?:mysqlpp_.*|thread_id|mysql_insertid)$/;
	return $dbh->SUPER::FETCH($key);
}


sub STORE
{
	my $dbh = shift;
	my ($key, $value) = @_;

	if ($key eq 'AutoCommit') {
		die "Can't disable AutoCommit" unless $value;
		return 1;
	}
	elsif ($key =~ /^(?:mysqlpp_.*|thread_id|mysql_insertid)$/) {
		$dbh->{$key} = $value;
		return 1;
	}
	return $dbh->SUPER::STORE($key, $value);
}


sub DESTROY
{
	my $dbh = shift;
	my $mysql = $dbh->FETCH('mysqlpp_connection');
	$mysql->close;
}


package DBD::mysqlPP::st;

$DBD::mysqlPP::st::imp_data_size = 0;
use strict;


sub bind_param
{
	my $sth = shift;
	my ($index, $value, $attr) = @_;
	my $type = (ref $attr) ? $attr->{TYPE} : $attr;
	if ($type) {
		my $dbh = $sth->{Database};
		$value = $dbh->quote($sth, $type);
	}
	my $params = $sth->FETCH('mysqlpp_param');
	$params->[$index - 1] = $value;
}



sub execute
{
	my $sth = shift;
	my @bind_values = @_;
	my $params = (@bind_values) ?
		\@bind_values : $sth->FETCH('mysqlpp_params');
	my $num_param = $sth->FETCH('NUM_OF_PARAMS');
	if (@$params != $num_param) {
		# ...
	}
    my $statement = _mysqlpp_bind_statement($sth, $params);
    #warn $statement;

	my $mysql = $sth->FETCH('mysqlpp_handle');
	my $result = eval {
		$sth->{mysqlpp_record_iterator} = undef;
		$mysql->query($statement);
		die if $mysql->is_error;

		my $dbh = $sth->{Database};
		$dbh->STORE(mysqlpp_insertid => $mysql->get_insert_id);
		$dbh->STORE(mysql_insertid => $mysql->get_insert_id);

		$sth->{mysqlpp_rows} = $mysql->get_affected_rows_length;
		if ($mysql->has_selected_record) {
			my $record = $mysql->create_record_iterator;
			$sth->{mysqlpp_record_iterator} = $record;
			$sth->STORE(NUM_OF_FIELDS => $record->get_field_length);
			$sth->STORE(NAME => [ $record->get_field_names ]);
		}
		$mysql->get_affected_rows_length;
	};
	if ($@) {
		$sth->DBI::set_err(
			$mysql->get_error_code, $mysql->get_error_message
		);
		return undef;
	}

	return $mysql->is_error
		? undef : $result
			? $result : '0E0';
}


sub fetch
{
	my $sth = shift;

	my $iterator = $sth->FETCH('mysqlpp_record_iterator');
	my $row = $iterator->each;
	return undef unless $row;

	if ($sth->FETCH('ChopBlanks')) {
		map {s/\s+$//} @$row;
	}
	return $sth->_set_fbav($row);
}
*fetchrow_arrayref = \&fetch;


sub rows
{
	my $sth = shift;
	$sth->FETCH('mysqlpp_rows');
}


sub FETCH
{
	my $dbh = shift;
	my $key = shift;

	return 1 if $key eq 'AutoCommit';
	return $dbh->{NAME} if $key eq 'NAME';
	return $dbh->{$key} if $key =~ /^mysqlpp_/;
	return $dbh->SUPER::FETCH($key);
}


sub STORE
{
	my $dbh = shift;
	my ($key, $value) = @_;

	if ($key eq 'AutoCommit') {
		die "Can't disable AutoCommit" unless $value;
		return 1;
	}
	elsif ($key eq 'NAME') {
		$dbh->{NAME} = $value;
		return 1;
	}
	elsif ($key =~ /^mysqlpp_/) {
		$dbh->{$key} = $value;
		return 1;
	}
	return $dbh->SUPER::STORE($key, $value);
}

sub _mysqlpp_bind_statement {
    my ($sth, $params) = @_;

    my @splitted = split qr/((?:\?)|(?:\bLIMIT\b))/i, $sth->{Statement};
    my $param_idx = 0;
    my $limit_found = 0;
    for (my $i=0; $i<@splitted; $i++ ) {
        my $dbh = $sth->{Database};
        if ( $splitted[$i] eq '?' && exists $params->[$param_idx] ) {
            my $value = $limit_found  && $params->[$param_idx] =~ qr/^\d+$/  ? $params->[$param_idx++]  #bind for LIMIT isn't need quote
                                                                             : $dbh->quote($params->[$param_idx++]);
            $splitted[$i] = $value;
            if ( exists $splitted[$i + 1] 
                   && $splitted[$i + 1] !~ qr/,/ # qr/,/ is for LIMIT ?, ?
                   && $splitted[$i + 1] !~ qr/\bOFFSET\b/i  ) {
                $limit_found = 0;
            }
        }
        elsif( $splitted[$i] =~ qr/\bLIMIT\b/i ) {
            $limit_found = 1;
        }
	}
    return join '', @splitted;
}

sub DESTROY
{
	my $dbh = shift;

}


1;
__END__

=head1 NAME

DBD::mysqlPP - Pure Perl MySQL driver for the DBI

=head1 SYNOPSIS

    use DBI;

    $dsn = "dbi:mysqlPP:database=$database;host=$hostname";

    $dbh = DBI->connect($dsn, $user, $password);

    $drh = DBI->install_driver("mysqlPP");

    $sth = $dbh->prepare("SELECT * FROM foo WHERE bla");
    $sth->execute;
    $numRows = $sth->rows;
    $numFields = $sth->{'NUM_OF_FIELDS'};
    $sth->finish;

=head1 EXAMPLE

  #!/usr/bin/perl

  use strict;
  use DBI;

  # Connect to the database.
  my $dbh = DBI->connect("dbi:mysqlPP:database=test;host=localhost",
                         "joe", "joe's password",
                         {'RaiseError' => 1});

  # Drop table 'foo'. This may fail, if 'foo' doesn't exist.
  # Thus we put an eval around it.
  eval { $dbh->do("DROP TABLE foo") };
  print "Dropping foo failed: $@\n" if $@;

  # Create a new table 'foo'. This must not fail, thus we don't
  # catch errors.
  $dbh->do("CREATE TABLE foo (id INTEGER, name VARCHAR(20))");

  # INSERT some data into 'foo'. We are using $dbh->quote() for
  # quoting the name.
  $dbh->do("INSERT INTO foo VALUES (1, " . $dbh->quote("Tim") . ")");

  # Same thing, but using placeholders
  $dbh->do("INSERT INTO foo VALUES (?, ?)", undef, 2, "Jochen");

  # Now retrieve data from the table.
  my $sth = $dbh->prepare("SELECT id, name FROM foo");
  $sth->execute();
  while (my $ref = $sth->fetchrow_arrayref()) {
    print "Found a row: id = $ref->[0], name = $ref->[1]\n";
  }
  $sth->finish();

  # Disconnect from the database.
  $dbh->disconnect();


=head1 DESCRIPTION

DBD::mysqlPP is a Pure Perl client interface for the MySQL database. This module implements network protool between server and client of MySQL, thus you don't need external MySQL client library like libmysqlclient for this module to work. It means this module enables you to connect to MySQL server from some operation systems which MySQL is not ported. How nifty!

From perl you activate the interface with the statement

    use DBI;

After that you can connect to multiple MySQL database servers
and send multiple queries to any of them via a simple object oriented
interface. Two types of objects are available: database handles and
statement handles. Perl returns a database handle to the connect
method like so:

  $dbh = DBI->connect("dbi:mysqlPP:database=$db;host=$host",
		      $user, $password, {RaiseError => 1});

Once you have connected to a database, you can can execute SQL
statements with:

  my $query = sprintf("INSERT INTO foo VALUES (%d, %s)",
		      $number, $dbh->quote("name"));
  $dbh->do($query);

See L<DBI(3)> for details on the quote and do methods. An alternative
approach is

  $dbh->do("INSERT INTO foo VALUES (?, ?)", undef,
	   $number, $name);

in which case the quote method is executed automatically. See also
the bind_param method in L<DBI(3)>. See L<DATABASE HANDLES> below
for more details on database handles.

If you want to retrieve results, you need to create a so-called
statement handle with:

  $sth = $dbh->prepare("SELECT id, name FROM $table");
  $sth->execute();

This statement handle can be used for multiple things. First of all
you can retreive a row of data:

  my $row = $sth->fetchow_arrayref();

If your table has columns ID and NAME, then $row will be array ref with
index 0 and 1. See L<STATEMENT HANDLES> below for more details on
statement handles.

I's more formal approach:


=head2 Class Methods

=over

=item B<connect>

    use DBI;

    $dsn = "dbi:mysqlPP:$database";
    $dsn = "dbi:mysqlPP:database=$database;host=$hostname";
    $dsn = "dbi:mysqlPP:database=$database;host=$hostname;port=$port";

    $dbh = DBI->connect($dsn, $user, $password);

A C<database> must always be specified.

=over

=item host

The hostname, if not specified or specified as '', will default to an
MySQL daemon running on the local machine on the default port
for the INET socket.

=item port

Port where MySQL daemon listens to. default is 3306.

=back

=back

=head2 MetaData Method

=over 4

=item B<tables>

    @names = $dbh->tables;

Returns a list of table and view names, possibly including a schema prefix. This list should include all tables that can be used in a "SELECT" statement without further qualification.

=back

=head2 Private MetaData Methods

=over 4

=item ListDBs

    @dbs = $dbh->func('_ListDBs');

Returns a list of all databases managed by the MySQL daemon.

=item ListTables

B<WARNING>: This method is obsolete due to DBI's $dbh->tables().

    @tables = $dbh->func('_ListTables');

Once connected to the desired database on the desired mysql daemon with the "DBI-"connect()> method, we may extract a list of the tables that have been created within that database.

"ListTables" returns an array containing the names of all the tables present within the selected database. If no tables have been created, an empty list is returned.

    @tables = $dbh->func('_ListTables');
    foreach $table (@tables) {
        print "Table: $table\n";
    }

=back


=head1 DATABASE HANDLES

The DBD::mysqlPP driver supports the following attributes of database
handles (read only):

  $insertid = $dbh->{'mysqlpp_insertid'};
  $insertid = $dbh->{'mysql_insertid'};

=head1 STATEMENT HANDLES

The statement handles of DBD::mysqlPP support a number
of attributes. You access these by using, for example,

  my $numFields = $sth->{'NUM_OF_FIELDS'};

=over

=item mysqlpp_insertid/mysql_insertid

MySQL has the ability to choose unique key values automatically. If this
happened, the new ID will be stored in this attribute. An alternative
way for accessing this attribute is via $dbh->{'mysqlpp_insertid'}.
(Note we are using the $dbh in this case!)

=item NUM_OF_FIELDS

Number of fields returned by a I<SELECT> statement. You may use this for checking whether a statement returned a result.
A zero value indicates a non-SELECT statement like I<INSERT>, I<DELETE> or I<UPDATE>.

=back

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires these other modules and libraries:

  DBI
  Net::MySQL

B<Net::MySQL> is a Pure Perl client interface for the MySQL database.

B<Net::MySQL> implements network protool between server and client of
MySQL, thus you don't need external MySQL client library like
libmysqlclient for this module to work. It means this module enables
you to connect to MySQL server from some operation systems which MySQL
is not ported. How nifty!

=head1 DIFFERENCE FROM "DBD::mysql"

The function of B<DBD::mysql> which cannot be used by B<DBD::mysqlPP> is described.

=head2 Parameter of Cnstructor

Cannot be used.

=over 4

=item * msql_configfile

=item * mysql_compression

=item * mysql_read_default_file/mysql_read_default_group

=item * mysql_socket

=back

=head2 Private MetaData Methods

These methods cannot be used for $drh.

=over 4

=item * ListDBs

=item * ListTables


=back

=head2 Server Administration

All func() method cannot be used.

=over 4

=item * func('createdb')

=item * func('dropdb')
 
=item * func('shutdown')

=item * func('reload')

=back

=head2 Database Handles

Cannot be used

=over 4

=item * $dbh->{info}

=back

=head2 Statement Handles

A different part.

=over 4

=item * The return value of I<execute('SELECT * from table')>

Although B<DBD::mysql> makes a return value the number of searched records SQL of I<SELECT> is performed, B<DBD::mysqlPP> surely returns I<0E0>.

=back

Cannot be used.

=over 4

=item * 'mysql_use_result' attribute

=item * 'ChopBlanks' attribute

=item * 'is_blob' attribute

=item * 'is_key' attribute

=item * 'is_num' attribute

=item * 'is_pri_key' attribute

=item * 'is_not_null' attribute

=item * 'length'/'max_length' attribute

=item * 'NUUABLE' attribute

=item * 'table' attribute

=item * 'TYPE' attribute

=item * 'mysql_type' attribute

=item * 'mysql_type_name' attributei

=back

=head2 SQL Extensions

Cannot be used.

=over 4

=item * LISTFIELDS

=item * LISTINDEX

=back

=head1 TODO

Encryption of the password independent of I<Math::BigInt>.

Enables access to much metadata.

=head1 SEE ALSO

L<Net::MySQL>, L<DBD::mysql>

=head1 AUTHORS

Hiroyuki OYAMA E<lt>oyama@module.jpE<gt>

=head1 MAINTAINER

Takuya Tsuchida E<lt>tsucchi at cpan.orgE<gt>

=head1 REPOSITORY

http://github.com/tsucchi/p5-Net-MySQL

=head1 COPYRIGHT AND LICENCE

Copyright (C) 2002-2011 Hiroyuki OYAMA. Japan. All rights reserved.

Copyright (C) 2011 Takuya Tsuchida

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
