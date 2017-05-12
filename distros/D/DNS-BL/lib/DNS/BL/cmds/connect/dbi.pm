package DNS::BL::cmds::connect::dbi;

use DNS::BL;

use 5.006001;
use strict;
use warnings;
use Fcntl qw(:DEFAULT);

use DBI;

use vars qw/@ISA/;

@ISA = qw/DNS::BL::cmds/;

use Carp;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Preloaded methods go here.

=pod

=head1 NAME

DNS::BL::cmds::connect::dbi - Implement the DB connect command with DBI for DNS::BL

=head1 SYNOPSIS

  use DNS::BL::cmds::connect::dbi;

=head1 DESCRIPTION

This module implements the connection to a DB backend where C<DNS::BL>
data will be stored. This backend is implemented through L<DBI>.

The following methods are implemented by this module:

=over

=item C<-E<gt>execute()>

See L<DNS::BL::cmds> for information on this method's purpose.

The connect command follows a syntax such as

  connect dbi <args> ...

Note that the 'connect' token must be removed by the calling class,
usually C<DNS::BL::cmds::connect>. B<args> are key - value pairs
specifying different parameters as described below. Unknown parameters
are reported as errors. The complete calling sequence is as

  connect dbi [user username] [password pwd] dsn dsn-string bl list

Where each of the arguments mean the following:

=over

=item B<dsn dsn-string>

The string that should be passed to DBI as the backend identifier.

=item B<user username>

The username for connecting to the server. If left unspecified,
defaults to "dnsbl-ro".

=item B<password pwd>

The password for connecting as the given user. Defaults to a blank
password.

=item B<bl list>

The name of the list on which you want to operate. This is a local
convention and every site has its own set of lists.

=back

This class will be C<use>d and then, its C<execute()> method invoked
following the same protocol outlined in L<DNS::BL>. Prior C<connect()>
information is to be removed by the calling class.

=cut

sub execute 
{ 
    my $bl	= shift;
    my $command	= shift;	# Expect "dbi"
    my %args	= @_;

    my @known 	= qw/dsn user password bl/;

    unless ($command eq 'dbi')
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'" . __PACKAGE__ . "' invoked by connect type '$command'")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    unless (exists $args{dsn} and length($args{dsn}))
    {
	return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
			    "Missing argument 'dsn' for 'connect dbi'")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    unless (exists $args{bl} and length($args{bl}))
    {
	return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
			    "Missing argument 'bl' for 'connect dbi'")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    for my $k (keys %args)
    {
	unless (grep { $k eq $_ } @known)
	{
	    return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
				"Unknown argument '$k' to 'connect dbi'")
		: &DNS::BL::DNSBL_ESYNTAX();
	}
    }

    my $dbh = DBI->connect($args{dsn},
			   (exists $args{user} ? $args{user} : ''),
			   (exists $args{password} ? $args{password} : ''),
			   { RaiseError => 0,
			     PrintWarn => 0,
			     Warn => 0,
			     PrintError => 0,
			     AutoCommit => 0 });

    unless ($dbh)
    {
	return wantarray ? (&DNS::BL::DNSBL_ECONNECT,
			    "Connect failed: DBI Error: $DBI::errstr") 
	    : &DNS::BL::DNSBL_ECONNECT;
    }

    # $sth is a hashref where all the prepared queries will be
    # stored.
    my $sth = {};

    # Prepare the query for inserting an entry into a given dnsbl. This
    # is used by write. Must be called with the following positional
    # arguments:
    #
    # Start_CIDR, End_CIDR, Created, Text, Return, dnsbl_name

    $sth->{add} = $dbh->prepare(<<END_OF_SQL

INSERT INTO entries (Bls_Id, Start_CIDR, End_CIDR, Created, Text, Return)
SELECT bls.Id, ?, ?, ?, ?, ?
FROM bls WHERE bls.Name = ?
				;
END_OF_SQL
				);

    unless ($sth->{add})
    {
	return wantarray ? (&DNS::BL::DNSBL_ECONNECT,
			    "Connect failed: Error preparing 'add' " .
			    "SQL statement: "
			    . ($DBI::errstr || "No DBI error")) 
	    : &DNS::BL::DNSBL_ECONNECT;
    }

    # Prepare the query implementing the ->read() semantics. Must be
    # called with the following arguments
    #
    # Start_CIDR, End_CIDR, dnsbl_name

    $sth->{read} = $dbh->prepare(<<END_OF_SQL

SELECT e.Start_CIDR, e.End_CIDR, e.Text, e.Return, e.Created
FROM entries e, bls b
WHERE
  e.Start_CIDR >= ?
  and e.End_CIDR <= ?
  and b.Name = ?
  and b.Id = e.Bls_Id
				;
END_OF_SQL
				);
    unless ($sth->{read})
    {
	return wantarray ? (&DNS::BL::DNSBL_ECONNECT,
			    "Connect failed: Error preparing 'read' " .
			    "SQL statement: "
			    . ($DBI::errstr || "No DBI error")) 
	    : &DNS::BL::DNSBL_ECONNECT;
    }

    # Prepare the query implementing the ->match() semantics. Must be
    # called with the following arguments
    #
    # Start_CIDR, End_CIDR, dnsbl_name

    $sth->{match} = $dbh->prepare(<<END_OF_SQL

SELECT e.Start_CIDR, e.End_CIDR, e.Text, e.Return, e.Created
FROM entries e, bls b
WHERE
  e.Start_CIDR <= ?
  and e.End_CIDR >= ?
  and b.Name = ?
  and b.Id = e.Bls_Id
				;
END_OF_SQL
				);
    unless ($sth->{match})
    {
	return wantarray ? (&DNS::BL::DNSBL_ECONNECT,
			    "Connect failed: Error preparing 'match' " .
			    "SQL statement: "
			    . ($DBI::errstr || "No DBI error")) 
	    : &DNS::BL::DNSBL_ECONNECT;
    }

    # Prepare the query implementing the ->erase() semantics. Must be
    # called with the following arguments
    #
    # Start_CIDR, End_CIDR, dnsbl_name

    $sth->{erase} = $dbh->prepare(<<END_OF_SQL

DELETE entries FROM entries, bls WHERE
  entries.Start_CIDR >= ?
  and entries.End_CIDR <= ?
  and bls.Name = ?
  and bls.Id = entries.Bls_Id
				;
END_OF_SQL
				);
    unless ($sth->{erase})
    {
	return wantarray ? (&DNS::BL::DNSBL_ECONNECT,
			    "Connect failed: Error preparing 'erase' " .
			    "SQL statement: "
			    . ($DBI::errstr || "No DBI error")) 
	    : &DNS::BL::DNSBL_ECONNECT;
    }

    # Store the private data
    $args{_class} = __PACKAGE__;
    $args{_sth} = $sth;
    $args{_dbh} = $dbh;

    $bl->set("_connect", \%args);

    # Add I/O methods to the $bl object so that further calls can be
    # processed

    $bl->set("_read",	\&_read);
    $bl->set("_match",	\&_match);
    $bl->set("_write",	\&_write);
    $bl->set("_erase",	\&_delete);
    $bl->set("_commit",	\&_commit);
    
    return wantarray ? (&DNS::BL::DNSBL_OK, "Connected to DBI") : 
	&DNS::BL::DNSBL_OK;
};

sub _write
{
    my $bl	= shift;
    my $e	= shift;

    my $data	= $bl->get('_connect');
    unless ($data or $data->{_class} eq __PACKAGE__)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "->write can only be called while 'connect dbi' is in effect")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    if ($data->{_sth}->{add}->execute(scalar $e->addr->network->numeric,
				      scalar $e->addr->broadcast->numeric,
				      $e->time, $e->desc, $e->value,
				      $data->{bl})
	and (my $rows = $data->{_sth}->{add}->rows) != 0)
    {
	return wantarray ? (&DNS::BL::DNSBL_OK, "OK - $rows inserted") : 
	    &DNS::BL::DNSBL_OK;
    }
    else
    {
	return wantarray ? (&DNS::BL::DNSBL_EOTHER, 
			    "Failed: (" . ($rows || '0') . 
			    " rows inserted) "
			    . ($DBI::errstr || "No DBI error")) : 
	    &DNS::BL::DNSBL_EOTHER;
    }
}

sub _read
{
    my $bl	= shift;
    my $e	= shift;

    my $data	= $bl->get('_connect');
    unless ($data or $data->{_class} eq __PACKAGE__)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "->read can only be called while 'connect dbi' is in effect")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    my @ret = ();
    if ($data->{_sth}->{read}->execute(scalar $e->addr->network->numeric,
				       scalar $e->addr->broadcast->numeric,
				       $data->{bl}))
    {
	while (my $r_ref = $data->{_sth}->{read}->fetchrow_arrayref)
	{
	    my $ip = new NetAddr::IP (NetAddr::IP->new($r_ref->[0])->addr 
				      . '-' . 
				      NetAddr::IP->new($r_ref->[1])->addr);
#	    warn "** Read fetched IP: $ip\n";
	    my $ne = new DNS::BL::Entry;
	    $ne->addr($ip);
	    $ne->desc($r_ref->[2]);
	    $ne->value($r_ref->[3]);
	    $ne->time($r_ref->[4]);
	    push @ret, $ne;
	}
    }
    else
    {
	return wantarray ? (&DNS::BL::DNSBL_EOTHER, 
			    "Failed: to ->read: "
			    . ($DBI::errstr || "No DBI error")) : 
				&DNS::BL::DNSBL_EOTHER;
    }

    return (&DNS::BL::DNSBL_OK, scalar @ret . " entries found",
	    @ret) if @ret;
    return wantarray ? (&DNS::BL::DNSBL_ENOTFOUND, "No entries matched") : 
	&DNS::BL::DNSBL_ENOTFOUND;
}

sub _match
{
    my $bl	= shift;
    my $e	= shift;

    my $data	= $bl->get('_connect');
    unless ($data or $data->{_class} eq __PACKAGE__)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "->match can only be called while 'connect dbi' is in effect")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    my @ret = ();
    if ($data->{_sth}->{match}->execute(scalar $e->addr->network->numeric,
					scalar $e->addr->broadcast->numeric,
					$data->{bl}))
    {
	while (my $r_ref = $data->{_sth}->{match}->fetchrow_arrayref)
	{
	    my $ip = new NetAddr::IP (NetAddr::IP->new($r_ref->[0])->addr 
				      . '-' . 
				      NetAddr::IP->new($r_ref->[1])->addr);
#	    warn "** Match fetched IP: $ip\n";
	    my $ne = new DNS::BL::Entry;
	    $ne->addr($ip);
	    $ne->desc($r_ref->[2]);
	    $ne->value($r_ref->[3]);
	    $ne->time($r_ref->[4]);
	    push @ret, $ne;
	}
    }
    else
    {
	return wantarray ? (&DNS::BL::DNSBL_EOTHER, 
			    "Failed: to ->read: "
			    . ($DBI::errstr || "No DBI error")) : 
				&DNS::BL::DNSBL_EOTHER;
    }

    return (&DNS::BL::DNSBL_OK, scalar @ret . " entries found",
	    @ret) if @ret;
    return wantarray ? (&DNS::BL::DNSBL_ENOTFOUND, "No entries matched") : 
	&DNS::BL::DNSBL_ENOTFOUND;
}

sub _commit
{
    my $bl	= shift;
    my $e	= shift;

    my $data	= $bl->get('_connect');
    unless ($data or $data->{_class} eq __PACKAGE__)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "->commit can only be called while 'connect dbi' is in effect")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    if ($data->{_dbh}->commit)
    {
	return wantarray ? (&DNS::BL::DNSBL_OK, "OK - Committed") : 
	    &DNS::BL::DNSBL_OK;
    }
    else
    {
	return wantarray ? (&DNS::BL::DNSBL_EOTHER, 
			    "Failed: "
			    . ($DBI::errstr || "No DBI error")) : 
				&DNS::BL::DNSBL_EOTHER;
    }
}

sub _delete
{
    my $bl	= shift;
    my $e	= shift;

    my $data	= $bl->get('_connect');
    unless ($data or $data->{_class} eq __PACKAGE__)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "->delete can only be called while 'connect dbi' is in effect")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    if ($data->{_sth}->{erase}->execute(scalar $e->addr->network->numeric,
					scalar $e->addr->broadcast->numeric,
					$data->{bl})
	and (my $rows = $data->{_sth}->{erase}->rows) != 0)
    {
	return wantarray ? (&DNS::BL::DNSBL_OK, 
			    "OK - $rows entries deleted") : 
				&DNS::BL::DNSBL_OK;
    }
    else
    {
	return wantarray ? (&DNS::BL::DNSBL_EOTHER, 
			    "Failed: (" . ($rows || '0') . 
			    " rows deleted) " . 
			    ($DBI::errstr || "No DBI error")) : 
			    &DNS::BL::DNSBL_EOTHER;
    }
}

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: dbi.pm,v $
Revision 1.4  2004/12/24 19:19:11  lem
Passes all tests. Ready for real-world...

Revision 1.3  2004/12/24 12:59:25  lem
Full functionality with some casual testing. Seems ready to be a RC.

Revision 1.2  2004/12/21 21:19:29  lem
dsn is a mandatory argument

Revision 1.1  2004/12/21 21:17:38  lem
Added boilerplate DBI connector.


=head1 SEE ALSO

Perl(1), L<DNS::BL>, L<DBI>.

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
