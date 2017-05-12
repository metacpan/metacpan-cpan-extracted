package CGI::Session::Driver::odbc;

use strict;
use Carp;
use CGI::Session::Driver::DBI;

@CGI::Session::Driver::odbc::ISA       = qw( CGI::Session::Driver::DBI );
$CGI::Session::Driver::odbc::VERSION   = '1.05';

# -----------------------------------------------

sub init
{
	my($self) = @_;

	if ($$self{'DataSource'} && ($$self{'DataSource'} !~ /^dbi:ODBC/) )
	{
		$$self{'DataSource'} = "dbi:ODBC:$$self{'DataSource'}";
	}

	return $self -> SUPER::init();

}	# End of init.

# -----------------------------------------------

sub store
{
	my($self, $sid, $datastr) = @_;

	Carp::croak "store(): usage error" if (! ($sid && $datastr) );

	my($dbh) = $$self{'Handle'};
	my($sth) = $dbh -> prepare("select $self->{IdColName} from " . $self -> table_name() . ' where id=?');

	if (! defined $sth)
	{
		return $self -> set_error("store(): \$sth->prepare failed with message " . $dbh -> errstr() );
    }

	$sth -> execute($sid) or return $self -> set_error("store(): \$sth->execute failed with message " . $dbh->errstr() );

	if ($sth->fetchrow_array() )
	{
		_run_sql($dbh, 'update ' . $self -> table_name() . " set $self->{DataColName}=? where $self->{IdColName}=?", $datastr, $sid)
			or return $self -> set_error("store(): serialize to db failed " . $dbh->errstr() );
	}
	else
	{
		_run_sql($dbh, 'insert into ' . $self -> table_name() . " ($self->{DataColName}, $self->{IdColName}) values(?, ?)", $datastr, $sid)
			or return $self -> set_error("store(): serialize to db failed " . $dbh->errstr() );
	}

	return 1;

}	# End of store.

# -----------------------------------------------

sub _run_sql
{
	my($dbh, $sql, $datastr, $sid) = @_;

	eval
	{
		my($sth) = $dbh -> prepare($sql) or return 0;

		$sth -> bind_param(1, $datastr) or return 0;
		$sth -> bind_param(2, $sid) or return 0;
		$sth -> execute() or return 0;
	};

	return 0 if $@;
	return 1;

}	# End of _run_sql.

# -----------------------------------------------
# If the table name hasn't been defined yet, check this location for 3.x compatibility.

sub table_name
{
	my($self) = shift;

	if (! defined $$self{'TableName'})
	{
		$$self{'TableName'} = $CGI::Session::ODBC::TABLE_NAME;
	}

	return  $self -> SUPER::table_name(@_);

}	# End of table_name.

# -----------------------------------------------

1;

__END__

=pod

=head1 NAME

C<CGI::Session::Driver::odbc> - A CGI::Session driver for ODBC

=head1 Synopsis

	$s = CGI::Session -> new('driver:ODBC', $sid);
	$s = CGI::Session -> new('driver:ODBC', $sid,
	{
		DataSource => 'dbi:ODBC:test',
		User       => 'sherzodr',
		Password   => 'hello',
	});
	$s = CGI::Session -> new('driver:ODBC', $sid, {Handle => $dbh});

or

    $s = new CGI::Session('driver:ODBC', undef,
    {
        TableName=>'session',
        IdColName=>'my_id',
        DataColName=>'my_data',
        Handle=>$dbh,
    });

=head1 Description

C<CGI::Session::Driver::odbc> stores session records in an ODBC-compatile table.
For details see L<CGI::Session::Driver::DBI|CGI::Session::Driver::DBI>, its parent class.

=head2 Driver Arguments

The C<CGI::Session::Driver::odbc> driver supports all the arguments documented in L<CGI::Session::Driver::DBI|CGI::Session::Driver::DBI>.
In addition, the I<DataSource> argument can optionally leave the leading "dbi:ODBC:" string out:

	$s = CGI::Session -> new('driver:ODBC', $sid, {DataSource => 'shopping_cart'});
	# is the same as:
	$s = CGI::Session -> new('driver:ODBC', $sid, {DataSource => 'dbi:ODBC:shopping_cart'});

=head2 Backwards Compatibility

For backwards compatibility, you can also set the table like this before calling C<new()>.
However, it is not recommended because it can cause conflicts in a persistent environment.

    $CGI::Session::ODBC::TABLE_NAME = 'my_sessions';

=head2 The C<sessions> table

The C<CGI::Session::DBI> docs recommend using this SQL create statement:

	create table sessions
	(
		id char(32) not null unique,
		a_session text not null
	);

Under Oracle, change the column type of the C<a_session> column from C<text> to C<long>,
and if you use C<Class::DBI::Loader>, which wants a primary key in every table,
change the definition of your C<id> column too. Thus you want:

	create table sessions
	(
		id char(32) not null primary key, # I.e.: 'unique' => 'primary key'.
		a_session long not null           # I.e.: 'text' => 'long'.
	);

=head1 Distributions

This module is available both as a Unix-style distro (*.tgz) and an
ActiveState-style distro (*.ppd). The latter is shipped in a *.zip file.

See http://savage.net.au/Perl-modules/html/installing-a-module.html for
help on unpacking and installing each type of distro.

=head1 Credits

This code is partially copied from the corresponding MySql driver by Sherzod Ruzmetov and the Postgres driver by Cosimo Streppone.

=head1 Author

C<CGI::Session::Driver::odbc> was written by Ron Savage I<E<lt>ron@savage.net.auE<gt>> in 2006.

Home page: http://savage.net.au/index.html

=head1 Copyright

Australian copyright (c) 2005, Ron Savage.
	All Programs of mine are 'OSI Certified Open Source Software';
	you can redistribute them and/or modify them under the terms of
	The Artistic License, a copy of which is available at:
	http://www.opensource.org/licenses/index.html

=cut
