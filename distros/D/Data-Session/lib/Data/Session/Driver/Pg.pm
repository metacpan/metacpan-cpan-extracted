package Data::Session::Driver::Pg;

use parent 'Data::Session::Driver';
no autovivification;
use strict;
use warnings;

use DBD::Pg qw(PG_BYTEA PG_TEXT);

use Hash::FieldHash ':all';

use Try::Tiny;

our $VERSION = '1.17';

# -----------------------------------------------

sub init
{
	my($self, $arg) = @_;

	$self -> SUPER::init($arg);

	$$arg{pg_bytea} ||= 0;
	$$arg{pg_text}  ||= 0;

	if ($$arg{pg_bytea} == 0 && $$arg{pg_text} == 0)
	{
		$$arg{pg_bytea} = 1;
	}
	elsif ($$arg{pg_bytea} == 1 && $$arg{pg_text} == 1)
	{
		$$arg{pg_text} = 0;
	}

} # End of init.

# -----------------------------------------------

sub new
{
	my($class, %arg) = @_;

	$class -> init(\%arg);

	my($self) = from_hash(bless({}, $class), \%arg);

	$self -> get_dbh(\%arg);

	return $self;

} # End of new.

# -----------------------------------------------

sub store
{
	my($self, $id, $data)   = @_;
	my($data_col_name)      = $self -> data_col_name;
	my($dbh)                = $self -> dbh;
	local $$dbh{RaiseError} = 1;
	my($id_col_name)        = $self -> id_col_name;
	my($table_name)         = $self -> table_name;

	# There is a race condition were two clients could run this code concurrently,
	# and both end up trying to insert. That's why we check for "duplicate" below

	try
	{
		my($sql) = "insert into $table_name ($data_col_name, $id_col_name) select ?, ? " .
						"where not exists (select 1 from $table_name where $id_col_name = ? limit 1)";
		my($sth) = $dbh -> prepare($sql);

		$sth -> bind_param(1, $data, {pg_type => $self -> pg_bytea ? PG_BYTEA : PG_TEXT});
		$sth -> bind_param(2, $id);
		$sth -> bind_param(3, $id);

		my($rv);

		try
		{
			$rv = $sth -> execute;

			($rv eq '0E0') && $self -> update($dbh, $table_name, $id_col_name, $data_col_name, $id, $data);
		}
		catch
		{
			if ($_ =~ /duplicate/)
			{
				$self -> update($dbh, $table_name, $id_col_name, $data_col_name, $id, $data);
			}
			else
			{
				die __PACKAGE__ . ". $_";
			}
		};

		$sth -> finish;
	}
	catch
	{
		die __PACKAGE__ . ". $_";
	};

	return 1;

} # End of store.

# -----------------------------------------------

sub update
{
	my($self, $dbh, $table_name, $id_col_name, $data_col_name, $id, $data) = @_;
	my($sql) = "update $table_name set $data_col_name = ? where $id_col_name = ?";
	my($sth) = $dbh -> prepare($sql);

	$sth -> bind_param(1, $data, {pg_type => $self -> pg_bytea ? PG_BYTEA : PG_TEXT});
	$sth -> bind_param(2, $id);

	$sth -> execute;
	$sth -> finish;

	return 1;

} # End of update.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Driver::Pg> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::Driver::Pg> allows L<Data::Session> to manipulate sessions via L<DBD::Pg>.

To use this module do both of these:

=over 4

=item o Specify a driver of type Pg, as Data::Session -> new(type => 'driver:Pg ...')

=item o Specify a database handle as Data::Session -> new(dbh => $dbh) or a data source as
Data::Session -> new(data_source => $string)

=back

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::Driver::Pg>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

The keys are listed here in alphabetical order.

They are lower-case because they are (also) method names, meaning they can be called to set or get
the value at any time.

=over 4

=item o data_col_name => $string

Specifes the name of the column in the sessions table which holds the session data.

This key is normally passed in as Data::Session -> new(data_col_name => $string).

Default: 'a_session'.

This key is optional.

=item o data_source => $string

Specifies the data source (as used by
DBI -> connect($data_source, $username, $password, $data_source_attr) ) to obtain a database handle.

This key is normally passed in as Data::Session -> new(data_source => $string).

Default: ''.

This key is optional, as long as a value is supplied for 'dbh'.

=item o data_source_attr => $hashref

Specifies the attributes (as used by
DBI -> connect($data_source, $username, $password, $data_source_attr) ) to obtain a database handle.

This key is normally passed in as Data::Session -> new(data_source_attr => $hashref).

Default: {AutoCommit => 1, PrintError => 0, RaiseError => 1}.

This key is optional.

=item o dbh => $dbh

Specifies the database handle to use to access the sessions table.

This key is normally passed in as Data::Session -> new(dbh => $dbh).

If not specified, this module will use the values of these keys to obtain a database handle:

=over 4

=item o data_source

=item o data_source_attr

=item o username

=item o password

=back

Default: ''.

This key is optional.

=item o host => $string

Not used.

=item o id_col_name => $string

Specifes the name of the column in the sessions table which holds the session id.

This key is normally passed in as Data::Session -> new(id_col_name => $string).

Default: 'id'.

This key is optional.

=item o password => $string

Specifies the password (as used by
DBI -> connect($data_source, $username, $password, $data_source_attr) ) to obtain a database handle.

This key is normally passed in as Data::Session -> new(password => $string).

Default: ''.

This key is optional.

=item o pg_bytea => $boolean

Specifies (if pg_bytea => 1) that the a_session column in the sessions table is of type bytea.

This key is normally passed in as Data::Session -> new(pg_bytea => $boolean).

If both 'pg_bytea' and 'pg_text' are set to 1, 'pg_text' is forced to be 0.

If both 'pg_bytea' and 'pg_text' are set to 0, 'pg_bytea' is forced to be 1.

=item o pg_text => $boolean

Specifies (if pg_text => 1) that the a_session column in the sessions table is of type text.

This key is normally passed in as Data::Session -> new(pg_text => $boolean).

=item o port => $string

Not used.

=item o socket => $string

Not used.

=item o table_name => $string

Specifes the name of the sessions table.

This key is normally passed in as Data::Session -> new(table_name => $string).

Default: 'sessions'.

This key is optional.

=item o username => $string

Specifies the username (as used by
DBI -> connect($data_source, $username, $password, $data_source_attr) ) to obtain a database handle.

This key is normally passed in as Data::Session -> new(username => $string).

Default: ''.

This key is optional.

=item o verbose => $integer

Print to STDERR more or less information.

This key is normally passed in as Data::Session -> new(verbose => $integer).

Typical values are 0, 1 and 2.

This key is optional.

=back

=head1 Method: remove($id)

Deletes from storage the session identified by $id, or dies if it can't.

Returns 1.

=head1 Method: retrieve($id)

Retrieve from storage the session identified by $id, or dies if it can't.

Returns the session.

This is a frozen session. This value must be thawed by calling the appropriate serialization
driver's thaw() method.

L<Data::Session> calls the right thaw() automatically.

=head1 Method: store($id => $data)

Writes to storage the session identified by $id, together with its data $data, or dies if it can't.

$dbh -> selectall_arrayref is used, and the table is not locked.

Returns 1.

=head1 Method: traverse()

Retrieves all ids from the sessions table, and for each id calls the supplied subroutine with the id
as the only parameter.

Returns 1.

=head1 Support

Log a bug on RT: L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Session>.

=head1 Author

L<Data::Session> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2010.

Home page: L<http://savage.net.au/index.html>.

=head1 Copyright

Australian copyright (c) 2010, Ron Savage.

	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
