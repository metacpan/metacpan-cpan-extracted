package Data::Session::Driver;

use parent 'Data::Session::Base';
no autovivification;
use strict;
use warnings;

use DBI;

use Hash::FieldHash ':all';

fieldhash my %created_dbh => 'created_dbh';

our $errstr  = '';
our $VERSION = '1.17';

# -----------------------------------------------

sub DESTROY
{
	my($self) = @_;

	(! $self -> dbh) && return;

	(! $self -> dbh -> ping) && die __PACKAGE__ . '. Database handle fails to ping';

	(! ${$self -> dbh}{AutoCommit}) && $self -> dbh -> commit;

	if ($self -> created_dbh)
	{
		$self -> dbh -> disconnect;
		$self -> created_dbh(0);
	}

	$self -> dbh('');

} # End of DESTROY.

# -----------------------------------------------

sub get_dbh
{
	my($self, $arg) = @_;

	if ($self -> dbh)
	{
		(ref $self -> dbh eq 'CODE') && $self -> dbh($self -> dbh -> () );
	}
	else
	{
		$self -> dbh
		(
			DBI -> connect
			(
				$self -> data_source,
				$self -> username,
				$self -> password,
				$self -> data_source_attr,
			) || die __PACKAGE__ . ". Can't connect to database with dsn '" . $self -> data_source . "'"
		);
		$self -> created_dbh(1);
	}

} # End of get_dbh.

# -----------------------------------------------

sub init
{
	my($class, $arg)        = @_;
	$$arg{created_dbh}      = 0;
	$$arg{data_col_name}    ||= 'a_session';
	$$arg{data_source}      ||= '';
	$$arg{data_source_attr} ||= {AutoCommit => 1, PrintError => 0, RaiseError => 1};
	$$arg{dbh}              ||= '';
	$$arg{host}             ||= '';
	$$arg{id}               ||= 0;
	$$arg{id_col_name}      ||= 'id';
	$$arg{password}         ||= '';
	$$arg{port}             ||= '';
	$$arg{socket}           ||= '';
	$$arg{table_name}       ||= 'sessions';
	$$arg{username}         ||= '';
	$$arg{verbose}          ||= 0;

} # End of init.

# -----------------------------------------------

sub remove
{
	my($self, $id)          = @_;
	my($dbh)                = $self -> dbh;
	local $$dbh{RaiseError} = 1;
	my($id_col_name)        = $self -> id_col_name;
	my($table_name)         = $self -> table_name;
	my($sql)                = "delete from $table_name where $id_col_name = ?";

	$dbh -> do($sql, {}, $id) || die __PACKAGE__ . ". Can't delete $id_col_name '$id' from table '$table_name'";

	return 1;

} # End of remove.

# -----------------------------------------------

sub retrieve
{
	my($self, $id)          = @_;
	my($data_col_name)      = $self -> data_col_name;
	my($dbh)                = $self -> dbh;
	local $$dbh{RaiseError} = 1;
	my($id_col_name)        = $self -> id_col_name;
	my($table_name)         = $self -> table_name;
	my($sql)                = "select $data_col_name from $table_name where $id_col_name = ?";
	my($message)            = __PACKAGE__ . "Can't %s in retrieve(). SQL: $sql";
	my($sth)                = $dbh -> prepare_cached($sql, {}, 3) || die sprintf($message, 'prepare_cached');

	$sth -> execute($id) || die sprintf($message, 'execute');

	my($row) = $sth -> fetch;

	$sth -> finish;

	# Return '' for failure.

	return $row ? $$row[0] : '';

} # End of retrieve.

# -----------------------------------------------

sub traverse
{
	my($self, $sub) = @_;

	if (! $sub || ref($sub) ne 'CODE')
	{
		die __PACKAGE__ . '. traverse() called without subref';
	}

	my($dbh)                = $self -> dbh;
	local $$dbh{RaiseError} = 1;
	my($id_col_name)        = $self -> id_col_name;
	my($table_name)         = $self -> table_name;
	my($sql)                = "select $id_col_name from $table_name";
	my($message)            = __PACKAGE__ . "Can't %s in traverse(). SQL: $sql";
	my($id)                 = $dbh -> selectall_arrayref($sql, {}) || die sprintf($message, 'selectall_arrayref');

	for my $i (0 .. $#$id)
	{
		$sub -> ($$id[$i][0]);
	}

	return 1;

} # End of traverse.

# -----------------------------------------------

1;

=pod

=head1 NAME

L<Data::Session::Driver> - A persistent session manager

=head1 Synopsis

See L<Data::Session> for details.

=head1 Description

L<Data::Session::Driver> is the parent of all L<Data::Session::Driver::*> modules.

=head1 Case-sensitive Options

See L<Data::Session/Case-sensitive Options> for important information.

=head1 Method: new()

Creates a new object of type L<Data::Session::Driver>.

C<new()> takes a hash of key/value pairs, some of which might mandatory. Further, some combinations
might be mandatory.

=head1 Method: remove($id)

Deletes from storage the session identified by $id, or dies if it can't.

Returns 1.

=head1 Method: retrieve($id)

Retrieve from storage the session identified by $id, or dies if it can't.

Returns the session.

This is a frozen session. This value must be thawed by calling the appropriate serialization
driver's thaw() method.

L<Data::Session> calls the right thaw() automatically.

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
