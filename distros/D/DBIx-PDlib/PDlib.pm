package DBIx::PDlib;

use 5.00503;
use strict;
use DBI;
use Carp;

require Exporter;
use vars qw($VERSION);

$VERSION = sprintf "%d.%03d", q$Revision: 1.9 $ =~ /(\d+)/g;
# $Date: 2004/03/15 13:46:14 $
# $Author: sjackson $

#############################################
# perl module to make sql operations easier #
#############################################

sub connect
{
	# options are exactly the same as DBI's
	my ($this) = shift;
	my $class = ref($this) || $this;

	# the connect code was borrowed heavily from DBIx::Abstract
	my($dbh,$data_source,$user,$pass);
	my $self = {};
	my ($config,$options) = @_;

	if (!defined($config))
	{
		croak "DBIx::PDlib->connect A connection configuration must be provided.";
	} elsif (ref($config) eq 'HASH') {
		if ($$config{'dbh'})
		{	# they provided the dbh connect string
			$dbh = $$config{'dbh'};
		} else {
			$user = $$config{'user'} || $$config{'username'};
			$pass = $$config{'password'} || $$config{'pass'};
			if (!defined($$config{'user'}) && $$config{'password'}) {
				$$config{'password'} = undef;
			}
			if (exists($$config{'dsn'})) {
				$data_source = $$config{'dsn'};
			} else {
				$$config{'driver'} ||= 'mysql'; # cause it's what I use
				$$config{'dbname'} ||= $$config{'db'} || '';
				$$config{'host'} ||= '';
				$$config{'port'} ||= '';
				$data_source = ___drivers($$config{'driver'},$config);
			}
		}
	} elsif (UNIVERSAL::isa($config,'DBI::db')) {
		$dbh = $config;
	} elsif (ref($config)) {
		croak "DBIx::PDlib->connect Config must be a hashref or a DBI object, not ".ref($config)."ref\n";
	} else {
		croak "DBIx::PDlib->connect Config must be a hashref or a DBI object, not a scalar.\n";
	}

	if ($data_source)
	{
		$dbh = DBI->connect($data_source,$user,$pass);
	} elsif (! $dbh) {
		croak "Could not understand data source.\n";
	}

	if (! $dbh) { return 0; }

	bless( $self, $class );

	if (ref($config) eq 'HASH' and !$$config{'dbh'})
	{
		$self->{'_dbh_args'} = {
			driver              => $$config{'driver'},
			dbname              => $$config{'dbname'},
			host                => $$config{'host'},
			port                => $$config{'port'},
			user                => $user,
			password            => $pass,
			data_source         => $data_source,
			};
	} else {
		$self->{'_dbh_args'} = { dbh => 1 };
	}
	$self->{'_dbh'} = $dbh;

	return $self;
}

sub ___drivers
{
	my ($driver,$config) = @_;
	my %drivers = (
		# Feel free to add new drivers... note that some DBD data_sources
		# do not translate well (eg Oracle).
		mysql       => "dbi:mysql:$$config{dbname}:$$config{host}:$$config{port}",
		msql        => "dbi:msql:$$config{dbname}:$$config{host}:$$config{port}",
		Pg          => "dbi:Pg:$$config{dbname}:$$config{host}:$$config{port}",
		# According to DBI, drivers should use the below if they have no
		# other preference.  It is ODBC style.
		DEFAULT     => "dbi:$driver:"
		);

	# Make Oracle look a little bit like other DBs.
	# Right now we only have one hack, but I can imagine there being
	# more...
	if ($driver eq 'Oracle') {
		$$config{'sid'} ||= delete($$config{'dbname'});
		$ENV{ORACLE_HOME} = $$config{'home'} unless (-d $ENV{ORACLE_HOME});
	}

	my @keys;
	foreach (keys(%$config)) {
		next if /^user$/;
		next if /^password$/;
		next if /^driver$/;
		push(@keys,"$_=$$config{$_}");
	}
	$drivers{'DEFAULT'} .= join(';',@keys);
	if ($drivers{$driver}) {
		return $drivers{$driver};
	} else {
		return $drivers{'DEFAULT'};
	}
}

sub raw_query
{
	#######################################################
	#######################################################
	## 
	## This will allow you to send any raw SQL to the $dbh
	## handle. Mainly useful for CREATE and DROP type statements
	##

	ref(my $self = shift) or croak "instance variable needed";

	my $query = shift;

	# make sure connection is still up
	$self->_check_active_connection();

	my $return_value = $self->{_dbh}->do($query);
	return defined(wantarray()) ? ($return_value) : "";
}

sub iterated_select
{
	#######################################################
	#######################################################
	## 
	## This will allow you to select a lot of stuff at once 
	## usage should be self explanitory i hope =]
	##

	ref(my $self = shift) or croak "instance variable needed";

	my($select, $from, $where, $other) = @_;

	# make sure connection is still up
	$self->_check_active_connection();

	my $query = "SELECT $select ";
	$query .= "   FROM $from " if $from;
	$query .= "  WHERE $where " if $where;
	$query .= "        $other" if $other;

	my $handle = $self->{_dbh}->prepare($query);

	# If we can execute a statement then do it and send back the handle

	return $handle if ($handle->execute);
	
	# else we can finish things up and close the dbh
	my ($pkg,$file,$line) = caller;
	carp "Unable to execute handle at line $line in file $file package $pkg\n";
	$handle->finish;
	return;
}


sub select_hashref
{
	####################################################
	####################################################
	## 
	## Useful SQL Select wrapper to cut down on code
	## in our friendly main scripts

	ref(my $self = shift) or croak "instance variable needed";

	my($select, $from, $where, $other) = @_;

	# make sure connection is still up
	$self->_check_active_connection();

	my $query = "SELECT $select ";
	$query .= "FROM $from " if $from;
	$query .= "WHERE $where " if $where;
	$query .= "$other" if $other;
	
	my $handle = $self->{_dbh}->prepare($query);

	unless ($handle->execute)
	{
		my ($pkg,$file,$line) = caller;
		carp "Unable to execute handle at line $line in file $file package $pkg\n";
		return;
	}
	my $hashref = $handle->fetchrow_hashref;
	$handle->finish;

	return $hashref;
}

sub select
{
	
	####################################################
	####################################################
	## 
	## Useful SQL Select wrapper to cut down on code
	## in our friendly main scripts

	ref(my $self = shift) or croak "instance variable needed";

	my($select, $from, $where, $other) = @_;

	# make sure connection is still up
	$self->_check_active_connection();

	my $query = "SELECT $select ";
	$query .= "FROM $from " if $from;
	$query .= "WHERE $where " if $where;
	$query .= "$other" if $other;
	
	my $handle = $self->{_dbh}->prepare($query);

	unless ($handle->execute)
	{
		my ($pkg,$file,$line) = caller;
		carp "Unable to execute handle at line $line in file $file package $pkg\n";
		return;
	}
	my @array = $handle->fetchrow_array;
	$handle->finish;

	# return entire array if they're asking for an array,
	# otherwise return the first element
	return wantarray ? @array : $array[0];
}

sub select_all
{
	
	####################################################
	####################################################
	## 
	## Useful SQL Select wrapper to cut down on code
	## in our friendly main scripts
	##
	## returns an array referance of all rows returns, containing
	## an array referance of columns returned for each row
 
	ref(my $self = shift) or croak "instance variable needed";

	my($select, $from, $where, $other) = @_;

	# make sure connection is still up
	$self->_check_active_connection();

	my $query = "SELECT $select ";
	$query .= "FROM $from " if $from;
	$query .= "WHERE $where " if $where;
	$query .= "$other" if $other;
	
	my $alldata = $self->{_dbh}->selectall_arrayref($query);
	if ($alldata)
	{
		return $alldata
	} else {
		my ($pkg,$file,$line) = caller;
		carp "Unable to execute handle at line $line in file $file package $pkg\n";
		return; # if there was an error, return nothing
	}
}

sub insert 
{
	my ($pkg,$file,$line) = caller;
	####################################################
	####################################################
	##
	## Useful SQL Insert wrapper to cut down on code
	## in our friendly main scripts
	##
	## Usage: insert($tablename,$fields_array_ref,$values_array_ref);

	ref(my $self = shift) or croak "instance variable needed";

	my($table, $fields, $values) = @_;

	# make sure connection is still up
	$self->_check_active_connection();

	return unless ($table &&
	               (ref $fields eq "ARRAY") &&
	               (ref $values eq "ARRAY") &&
	               (@$fields == @$values)
	              );

	my $f_list = join(', ',@$fields);
	my $v_list = join(',', map { "?" } @$values );
	my $handle = $self->{_dbh}->prepare("INSERT INTO $table ($f_list) VALUES ($v_list)");
	if ($handle->execute(@$values))
	{	# will auto-quote stuff this way. pass 'undef' for NULL values
		$handle->finish;
		# return 1 (success) if they want a return value, or just return.
		return defined(wantarray()) ? (1) : "";
	} else {
		# couldn't execute it.
		carp "Unable to execute insert handle at line $line in file $file package $pkg\n";
		return;
	}
}

sub update
{
	my ($pkg,$file,$line) = caller;

	####################################################
	####################################################
	##
	## Useful SQL Update wrapper to cut down on code
	## in our friendly main scripts
	##
	## Usage: update($tablename,$fields_array_ref,$values_array_ref,$where_statement);

	ref(my $self = shift) or croak "instance variable needed";

	my($table, $fields, $values, $where) = @_;

	# make sure connection is still up
	$self->_check_active_connection();

	# they must give us everything. UPDATE's without $where are valid SQL, but
	# I see no reason we should have them called from any script using this
	# sql wrapper. So we make sure they give us some where statement,
	# and they can pass "$where=1" if they really know what they're doing.
	return unless ($table &&
	               (ref($fields) eq "ARRAY") &&
	               (ref($values) eq "ARRAY") &&
	               (@$fields == @$values) &&
	               $where
	              );
	my $query = "UPDATE $table SET " . 
	            join(',', map { " $_ = ?" } @$fields ) .
	            " WHERE $where";

	my $handle = $self->{_dbh}->prepare($query);
	if ($handle->execute(@$values))
	{	# will auto-quote stuff this way.
		$handle->finish;
		# return 1 (success) if they want a return value, or just return.
		return defined(wantarray()) ? (1) : "";
	} else {
		# couldn't execute it.
		carp "Unable to execute update handle at line $line in file $file package $pkg\n";
		return;
	}
}

sub delete
{
	####################################################
	####################################################
	##
	## Useful delete wrapper to cut down on code
	## in our friendly main scripts

	ref(my $self = shift) or croak "instance variable needed";

	my($table,$where) = @_;

	# make sure connection is still up
	$self->_check_active_connection();

	if ($table && $where)
	{
		my $return_value = $self->{_dbh}->do("DELETE FROM $table WHERE $where");
		# return $return_value if they want a return value, or just return.
		return defined(wantarray()) ? ($return_value) : "";
	} else {
		return;
	}
}

sub quote
{
	## THIS SHOULDN'T BE NEEDED EXCEPT A FEW CASES (where statements)
	## MOST FUNCTIONS NEEDING QUOTING (inserts, updates)
	## WILL DO QUOTING THEMSELVES

	####################################################
	####################################################
	##
	## Useful for quoting text fields, since we don't 
	## actually connect to DBI in the main scripts anymore
	## it's needed
	## 
	## Usage:
	##	my @newvalues = quote(@values);
	##	my $firstquotedvalue = $newvalues[0];
	##	foreach (@newvalues) {
	##		# do something
	##	}

	ref(my $self = shift) or croak "instance variable needed";

	# make sure connection is still up
	$self->_check_active_connection();

	my(@toreturn);
	foreach my $toquote (@_)
	{
		my $temp = $self->{_dbh}->quote($toquote);
		push(@toreturn,$temp);
	}
	# return entire array if they're asking for an array,
	# otherwise return the first element
	return wantarray ? @toreturn : $toreturn[0];
}

sub disconnect
{
	ref(my $self = shift) or croak "instance variable needed";
	$self->{_dbh}->disconnect();
}

sub connected
{
	ref(my $self = shift) or croak "instance variable needed";
	my $rc = $self->{_dbh}->ping;
	return 1 if $rc;
}

sub _check_active_connection
{
	ref(my $self = shift) or croak "instance variable needed";

	unless ($self->connected())
	{	# we're not connected anymore, something died.
		if ($self->{_dbh_args}{data_source})
		{	# we can't do a reconnect if they passed in an active handle
			my $dbh = DBI->connect(
				$self->{_dbh_args}{datasource},
				$self->{_dbh_args}{user},
				$self->{_dbh_args}{password} );
			$self->{_dbh} = $dbh;
		}
	}
	# we could loop until ok, or return some error code if we're still
	# not connected, but I'm just hoping this fixes things. We've been getting:
#DBD::mysql::st execute failed: MySQL server has gone away at /usr/local/apache/public-dns.purifieddata.net/lib/PDlib_dns.pm line 64.
#Unable to execute handle at line 87 in file /usr/local/apache/public-dns.purifieddata.net/lib/utils_dns.pm package utils_dns
#[Tue Aug 19 22:20:07 2003] [error] Can't call method "fetchrow_array" on an undefined value at /usr/local/apache/public-dns.purifieddata.net/lib/utils_dns.pm line 88.
}


1;

__END__

=head1 NAME

DBIx::PDlib - DBI SQL abstraction and convenience methods

=head1 SYNOPSIS

  use DBIx::PDlib;
  my $db = DBIx::PDlib->connect({
    driver   => 'mydriver',
    host     => 'myhost.com',
    dbname   => 'mydb',
    user     => 'myuser',
    password => 'mypassword',
    });

  my ($name) = $db->select('name','table1',"id = '10'");

  my $dbi_sth = $db->iterated_select('name','table1',
                                       "id > 2",'ORDER BY name');
  while (my ($name) = $dbi_sth->fetchrow_array) { ...do stuff... }

  my $rv = $db->insert('table1',['id','name'],['11','Bob']);

  my $rv = $db->update('table1',['name'],['Bob Jr.'],"id = '11'");

  my $rv = $db->delete('table1',"id = '11'");

  my @quoted = $db->quote( "something", $foo, $bar, @moredata );

  my $rv = $db->raw_query("CREATE TABLE table1 (id int, name char)");

  if ($db->connected) { ...we're connected... }

  $db->disconnect;

=head1 ABSTRACT

DBIx::PDlib provides a simplified way to interact with DBI. It provides methods for SELECT, INSERT, UPDATE, and DELETE which result in having to type less code to do the DBI queries. It does as little as possible to make things easier.

What it doesn't do... It isn't trying to replace DBI. It's not trying to completely abstract SQL statement building into some 100% perllike syntax (though that is REALLY cool, and what I liked about DBIx::Abstract), but it does abstract it some.

=head1 REQUIRES

    DBI

=head1 INSTALLATION

Download the gzipped tar file from:

    http://search.cpan.org/search?dist=DBIx-PDlib

Unzip the module as follows or use winzip:

    tar -zxvf DBIx-PDlib-1.xxx.tar.gz

For "make test" to work, you need to setup some parameters for the build.

    perl Makefile.PL --help

The rest is done the standard Perl way:

    make
    make test
    make install    # you need to be root

Windows users without a working "make" can get nmake from:

    ftp://ftp.microsoft.com/Softlib/MSLFILES/nmake15.exe

=head1 METHODS

=head2 MAIN METHODS

=over

=item C<$db = DBIx::PDlib-E<gt>connect( $connect_config | $dbihandle )> I<CONSTRUCTOR>

Open a connection to a database as configured by $connect_config.
$connect_config can either be a scalar, in which case it is a DBI data source, or a referance to a hash with the following keys:

 dsn      -- The data source to connect to your database
 
 OR, DBIx::PDlib will try to generate it if you give these instead:

 driver   -- DBD driver to use (defaults to mysql)
 host     -- Host of database server
 port     -- Port of database server
 dbname   -- Name of database

 Username and password are always valid.

 user     -- Username to connect as
 password -- Password for user

Alternatively you can pass in a DBI handle directly.  This will disable
the methods "reconnect" and "ensure_connection" as they rely on connection
info not available on a DBI handle.

=item C<$sth = $db-E<gt>iterated_select( 't.field1,t2.field2','table t, table2 t2','t.id = t2.id','ORDER BY t.field1')>

This builds an SQL query, executes it, and returns the DBI statement handle if execute succeeds. It will return undef if execute fails.

The above query would build the following SQL statement:
    SELECT t.field1, t2.field2 FROM table t, table2 t2
    WHERE t.id = t2.id ORDER BY t.field1

The first two options (fields and table) are required. The third option is the WHERE statement, which you can leave blank or undef to exclude using a where statement. The fourth option is any additional raw SQL to append to the query (ORDER BY, GROUP BY, etc type stuff can be put here).

=item C<$field = $db-E<gt>select( 'field1','table','id E<gt> 10','ORDER BY field1')>

This will return the first row of data, and call DBI's finish() on the handle. If called in array context, an array of the fields will be returned. If called in scalar context, the first field in the first row returned will be returned. 'undef' will be returned if the call fails.

This is very useful if you just need to grab one row of data. The statement fields have the same requirements as iterated_select.

=item C<$arrayref = $db-E<gt>select_all( 'field1','table','id E<gt> 10','ORDER BY field1')>

This will execute the statement (same requirements as iterated_select), and call DBI's fetchall_arrayref on the handle, finish() the handle, and return the resulting arrayref. The $arrayref will contain an array representing all rows returned, of arrayrefs containing the columns for each row (an array of arrays).

=item C<$rv = $db-E<gt>insert('table1',['id','name'],['11','Bob']);>

Inserts a row into the database.

The first option is the table to insert into. The second option is the list of field names. The third option is a list of values.

Use the perl 'undef' value to insert a NULL.

This format was chosen to allow Insert's and Update's to use the same calling semantics.

=item C<$rv = $db-E<gt>update('table1',['name'],['Bob Jr.'],'id = 11');>

Updates a row in the database.

The first three options have the same requirements as insert(). The last option  is the WHERE statement, and is optional (though recommended).

Use the perl 'undef' value to update a field to NULL.

=item C<$rv = $db-E<gt>delete('table1','id = 11');>

Deletes rows matching the where statement in the second option from the database table 'table1'.

The where statement is required as a safety precaution. If you really want to delete everything in the table, pass in a "1" as the where statement.

=item C<@quoted = $db-E<gt>quote('something', $foo, $bar, @moredata );>

Takes in an array of values, and returns an array of those same values quoted using DIB's quote(). If called in scalar context, it will return the first item in the list.

=back

=head2 ACCESSOR METHODS

=over

=item C<$db-E<gt>raw_query($sql)>

This executes a DBI do() on whatever you pass to it. This is useful for CREATE, DROP, ALTER, etc type SQL commands.

=item C<$db-E<gt>connected>

Check to see if this object is connected to a database. It will do a DBI ping on the current DBI database handle that is inside the DBIx::PDlib object, returning 1 if it is successful.

=item C<$db-E<gt>disconnect>

You don't need to call this, but if you really want to disconnect from the database for some reason, this will do the job. It just calls DBI's disconnect() on the current DBI handle in the object.

=back

=head1 QUOTING

An attempt has been made to provide automatic quoting where appropriate, but there are some areas normally used that you will need to do your own value quoting.

In areas where you will need to do your own quoting, the quote() method is the recommended way to do it.

insert() - The values passed to insert will automatically be quoted by use of DBI's placeholders (B<?>). To pass a B<NULL>, simply pass an B<undef> value. You should NOT manually quote values passed to insert(), as DBI's quote will be called on those values, resulting in the actual quotes being entered into the database.

update() - The values portion will be automatically quoted, the same way as insert(). However, the B<WHERE> statement will simply be appended to the query string that is built, so you MUST quote your own values.

select(), iterated_select(), select_all(), delete() - No quoting is done by these methods. Any fields that need quoted will need to be handled by your program.


=head1 TODO

not sure yet.

=head1 SEE ALSO

DBI

DBIx::Abstract (From which connect(), Makefile.PL, and t/1.pl borrow heavily)

=head1 AUTHOR

Josh I. Miller, E<lt>jmiller@purifieddata.netE<gt>

=head1 COPYRIGHT AND LICENSE

Portions copyright 2003 by Josh I. Miller

Portions copyright 2001-2002 by Andrew Turner

Portions copyright 2000-2001 by Adelphia Business Solutions

Portions copyright 1998-2000 by the Maine Internetworks (MINT)

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
