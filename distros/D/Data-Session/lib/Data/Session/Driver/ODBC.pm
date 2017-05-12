package Data::Session::Driver::ODBC;

use parent 'Data::Session::Driver';
no autovivification;
use strict;
use warnings;

use Hash::FieldHash ':all';

use Try::Tiny;

our $VERSION = '1.17';

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
	my($sql)                = "insert into $table_name ($data_col_name, $id_col_name) select ?, ? " .
								"on duplicate key update $data_col_name = ?";

	$dbh -> do($sql, {}, $data, $id, $data) || die __PACKAGE__ . ". $DBI::errstr";

	return 1;

} # End of store.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Driver::ODBC> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::Driver::ODBC> allows L<Data::Session> to store sessions via L<DBD::ODBC>.

To use this module do both of these:

=over 4

=item o Specify a driver of type ODBC, as Data::Session -> new(type => 'driver:ODBC ...')

=item o Specify a database handle as Data::Session -> new(dbh => $dbh), or a data source as
Data::Session -> new(data_source => $string)

=back

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::Driver::ODBC>.

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

=item o data_source_attr => $string

Specifies the attributes (as used by
DBI -> connect($data_source, $username, $password, $data_source_attr) ) to obtain a database handle.

This key is normally passed in as Data::Session -> new(data_source_attr => $string).

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

Typical values are 0, 1 and 2.

This key is normally passed in as Data::Session -> new(verbose => $integer).

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

Returns 1.

=head1 Method: traverse()

Retrieves all ids from the sessions table, and for each id calls the supplied subroutine with the
id as the only parameter.

$dbh -> selectall_arrayref is used, and the table is not locked.

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
