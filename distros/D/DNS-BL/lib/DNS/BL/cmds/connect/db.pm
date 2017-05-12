package DNS::BL::cmds::connect::db;

use DNS::BL;

use 5.006001;
use strict;
use warnings;
use Fcntl qw(:DEFAULT);

use MLDBM qw(DB_File Storable);

use vars qw/@ISA/;

@ISA = qw/DNS::BL::cmds/;

use Carp;

our $VERSION = '0.00_01';
$VERSION = eval $VERSION;  # see L<perlmodstyle>

# Preloaded methods go here.

=pod

=head1 NAME

DNS::BL::cmds::connect::db - Implement the DB connect command for DNS::BL

=head1 SYNOPSIS

  use DNS::BL::cmds::connect::db;

=head1 DESCRIPTION

This module implements the connection to a DB backend where C<DNS::BL>
data will be stored. On each call to this class' methods, a hash will
be C<tie()>d and then C<untie()>d. This guarantees that the underlying
DB structure will be unlocked and available for other commands that
may, for instance, replace or manipulate the hash "from under us".

The following methods are implemented by this module:

=over

=item C<-E<gt>execute()>

See L<DNS::BL::cmds> for information on this method's purpose.

The connect command follows a syntax such as

  connect db <args> ...

Note that the 'connect' token must be removed by the calling class,
usually C<DNS::BL::cmds::connect>. B<args> are key - value pairs
specifying different parameters as described below. Unknown parameters
are reported as errors. The complete calling sequence is as

  connect db file "filename" [mode bulk]

Where "filename" refers to the DB file where data is to be found. If
the file does not exist, it will be created (provided that permissions
allow).

If "mode bulk" is indicated, arrangements are made to tie() to the
database once. This makes the operation slightly faster, but increases
the chance of collision when concurrent access to the backing store is
performed.

This class will be C<use>d and then, its C<execute()> method invoked
following the same protocol outlined in L<DNS::BL>. Prior C<connect()>
information is to be removed by the calling class.

=cut

sub execute 
{ 
    my $bl	= shift;
    my $command	= shift;	# Expect "db"
    my %args	= @_;

    my @known 	= qw/file mode/;

    unless ($command eq 'db')
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'" . __PACKAGE__ . "' invoked by connect type '$command'")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    for my $k (keys %args)
    {
	unless (grep { $k eq $_ } @known)
	{
	    return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
				"Unknown argument '$k' to 'connect db'")
		: &DNS::BL::DNSBL_ESYNTAX();
	}
    }

    unless (exists $args{file} and length($args{file}))
    {
	return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
			    "Missing file name for 'connect db'")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    # Store the passed data
    $args{_class} = __PACKAGE__;

    if (exists $args{mode})
    {
	if ($args{mode} eq 'bulk')
	{
	    my %db = ();
	    unless (tie %db, 'MLDBM', $args{file}, O_CREAT|O_RDWR, 0640)
	    {
		return wantarray ? 
		    (&DNS::BL::DNSBL_ECONNECT(), 
		     "Cannot tie to file '$args{file}'")
		    : &DNS::BL::DNSBL_ECONNECT();
	    }
	    $args{_db} = \%db;
	}
	else
	{
	    return wantarray ? (&DNS::BL::DNSBL_ESYNTAX(), 
				"Missing or wrong name for 'connect db mode'")
		: &DNS::BL::DNSBL_ESYNTAX();
	}
    }

    $bl->set("_connect", \%args);

    # Add I/O methods to the $bl object so that further calls can be
    # processed

    $bl->set("_read",	\&_read);
    $bl->set("_match",	\&_match);
    $bl->set("_write",	\&_write);
    $bl->set("_erase",	\&_delete);
    $bl->set("_commit",	\&_commit);
    
    return wantarray ? (&DNS::BL::DNSBL_OK, "Connected to DB") : 
	&DNS::BL::DNSBL_OK;
};

sub _portal
{
    my $bl	= shift;	# Calling BL object
    my $data	= $bl->get('_connect');

    my %r	= ();		# Placeholder for the DB

    unless ($data or $data->{_class} eq __PACKAGE__)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "->write can only be called while 'connect db' is in effect")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    if (exists $data->{_db})
    {
	return wantarray ? (&DNS::BL::DNSBL_OK, "DB tied", $data->{_db}) : 
	    &DNS::BL::DNSBL_OK;
    }
    else
    {
	unless (tie %r, 'MLDBM', $data->{file}, O_CREAT|O_RDWR, 0640)
	{
	    return wantarray ? 
		(&DNS::BL::DNSBL_ECONNECT(), 
		 "Cannot tie to file '" . $data->{file} . "'")
		: &DNS::BL::DNSBL_ECONNECT();
	}
	return wantarray ? (&DNS::BL::DNSBL_OK, "DB tied", \%r) : 
	    &DNS::BL::DNSBL_OK;
    }
}

sub _write
{
    my $bl	= shift;
    my $e	= shift;

    my @r = _portal($bl);
    return wantarray ? @r : $r[0] if $r[0] != &DNS::BL::DNSBL_OK;

    my $db = $r[2];

    # The index update is only needed if no prior entry exists.
    unless (exists $db->{$e->addr->network->cidr})
    {
	# Build the index until level - 1
	if ($e->addr->masklen > 0)
	{
	    for my $m (0 .. $e->addr->masklen - 1)
	    {
		my $f = NetAddr::IP->new($e->addr->addr . "/$m")->network;
		my @c = grep { $_->contains($e->addr) } $f->split($m + 1);
		my $i = $db->{'index:' . $f} || [];
		unless (grep { 'index:' . $c[0]->cidr eq $_ } @$i)
		{
		    push @$i, 'index:' . $c[0]->cidr;
		    $db->{'index:' . $f} = $i;
		}
	    }
	}

	# Build the last index level
	my $i = $db->{'index:' . $e->addr->network->cidr} || [];
	unless (grep { 'index:' . $e->addr->network->cidr eq $_ } @$i)
	{
	    push @$i, 'node:' . $e->addr->network->cidr;
	    $db->{'index:' . $e->addr->network->cidr} = $i;
	}
    }

    # Store the actual entry in the hash
    $db->{$e->addr->network->cidr} = $e;

    return wantarray ? (&DNS::BL::DNSBL_OK, "OK - Done") : 
	&DNS::BL::DNSBL_OK;
}

sub _read
{
    my $bl	= shift;
    my $e	= shift;

    my @r = _portal($bl);
    return wantarray ? @r : $r[0] if $r[0] != &DNS::BL::DNSBL_OK;

    my $db = $r[2];

    my @ret = ();
    my $index = $db->{'index:' . $e->addr->network->cidr} || [];

    # Use the index to find the entries that must be attached
    while (@$index)
    {
	my $l = shift @$index;
#	print "_read: Index checking $l out of ", 0 + @$index, "\n";
	if (substr($l, 0, 5) eq 'node:')
	{
	    my $ip = new NetAddr::IP substr($l, 5);
#	    print "_read: Consider $ip\n";
	    push @ret, $ip if $e->addr->contains($ip);
	}
	elsif (substr($l, 0, 6) eq 'index:')
	{
	    my $ip = new NetAddr::IP substr($l, 6);
	    if ($e->addr->contains($ip))
	    {
		my $i = $db->{$l};
		push @$index, @$i if $i;
#		print "_read: Add $l to queue\n";
	    }
	}
    }
    
    @ret = grep { defined $_ } map { $db->{$_->network->cidr} } @ret;

    return (&DNS::BL::DNSBL_OK, scalar @ret . " entries found",
	    @ret) if @ret;
    return (&DNS::BL::DNSBL_ENOTFOUND, "No entries matched");
}

sub _match
{
    my $bl	= shift;
    my $e	= shift;

    my @r = _portal($bl);
    return wantarray ? @r : $r[0] if $r[0] != &DNS::BL::DNSBL_OK;

    my $db = $r[2];

    my @ret = ();
    my $index = $db->{'index:' . NetAddr::IP->new('any')->network->cidr} || [];

    # Use the index to find the entries that must be attached
    while (@$index)
    {
	my $l = shift @$index;
#	print "_match: Index checking $l out of ", 0 + @$index, "\n";
	if (substr($l, 0, 5) eq 'node:')
	{
	    my $ip = new NetAddr::IP substr($l, 5);
#	    print "_match: Consider $ip\n";
	    push @ret, $ip if $e->addr->within($ip);
	}
	elsif (substr($l, 0, 6) eq 'index:')
	{
	    my $ip = new NetAddr::IP substr($l, 6);
	    if ($e->addr->within($ip))
	    {
		my $i = $db->{$l};
		push @$index, @$i if $i;
#		print "_match: Add $l to queue\n";
	    }
	}
    }
    
    @ret = grep { defined $_ } map { $db->{$_->network->cidr} } @ret;

    return (&DNS::BL::DNSBL_OK, scalar @ret . " entries found",
	    @ret) if @ret;
    return (&DNS::BL::DNSBL_ENOTFOUND, "No entries matched");
}

sub _commit
{
    return wantarray ? (&DNS::BL::DNSBL_OK, "commit is not required with DB") 
	: &DNS::BL::DNSBL_OK;
}

sub _delete
{
    my $bl	= shift;
    my $e	= shift;

    my @r = _portal($bl);
    return wantarray ? @r : $r[0] if $r[0] != &DNS::BL::DNSBL_OK;

    my $db = $r[2];
    my $num = 0;
    my @ret = ();
    my $index = $db->{'index:' . $e->addr->network->cidr} || [];

    # Use the index to find which entries must be deleted
    while (@$index)
    {
	my $l = shift @$index;
#	print "_delete: Index checking $l out of ", 0 + @$index, "\n";
	if (substr($l, 0, 5) eq 'node:')
	{
	    my $ip = new NetAddr::IP substr($l, 5);
#	    print "_delete: Consider $ip\n";
	    push @ret, $ip if $e->addr->contains($ip);
	}
	elsif (substr($l, 0, 6) eq 'index:')
	{
	    my $ip = new NetAddr::IP substr($l, 6);
	    if ($e->addr->contains($ip))
	    {
		my $i = $db->{$l};
		push @$index, @$i if $i;
#		print "_delete: Add $l to queue\n";
	    }
	}
    }

    # Based on the hits, delete entries from the hash and from
    # the cache
    for my $n (@ret)
    {
#	print "_delete: deleting 'node:" . $n->network->cidr . "'\n";
	delete $db->{$n->network->cidr};
	++ $num;

	for my $m (reverse 0 .. $n->masklen)
	{
	    my $k = 'index:' 
		. NetAddr::IP->new($n->addr . "/$m")->network->cidr;
#	    print "_delete: Check cache for $k\n";
	    my $i = $db->{$k} || [];
	    my @rem = ();

	    push @rem, grep { substr($_, 0, 6) eq 'index:' 
				  and exists $db->{$_} } @$i;

	    push @rem,
	    grep { $_ }
	    map { $_->[1] if exists $db->{$_->[0]} }
	    map { [ substr($_, 5), $_ ] }
	    grep { substr($_, 0, 5) eq 'node:' } 
	    @$i;

#	    print "_delete: db $k -> [", join(',', @$i) || 'empty', "]\n";
#	    print "_delete: rem $k -> [", join(',', @rem) || 'empty', "]\n";
#	    print "_delete: comp=", ($#rem == $#$i), ", rem=", 
#	    scalar @rem, ", i=", scalar @$i, "\n";
#	    print "_delete: rem=", 
#	    map { defined $_ ? $_ ? $_ : 'false' : 'undef' } @rem, "\n";
#	    print "_delete: i=",
#	    map { defined $_ ? $_ ? $_ : 'false' : 'undef' } @$i, "\n";

	    if (@rem == @$i)
	    {
#		print "_delete: This node was unchanged - Skip the rest\n";
		last;
	    }
	    elsif (@rem)
	    {
		$db->{$k} = \@rem;
#		print "_delete: rebuild index node '$k'\n";
	    }
	    else
	    {
#		print "_delete: delete index node '$k'\n";
		delete $db->{$k};
	    }
	}
    }

    if ($num)
    {
	return (&DNS::BL::DNSBL_OK, "$num entries deleted");
    }
    else
    {
	return (&DNS::BL::DNSBL_ENOTFOUND, "No entries deleted");
    }
}

sub DNS::BL::cmds::_db_dump::execute
{
    my $bl	= shift;
    my %db	= ();

    my $data	= $bl->get('_connect');

    unless ($data or $data->{_class} eq __PACKAGE__)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ESYNTAX(), 
	     "'db_dump' can only be called while 'connect db' is in effect")
	    : &DNS::BL::DNSBL_ESYNTAX();
    }

    unless (tie %db, 'MLDBM', $data->{file}, O_RDONLY, 0640)
    {
	return wantarray ? 
	    (&DNS::BL::DNSBL_ECONNECT(), 
	     "Cannot tie to file '" . $data->{file} . "'")
	    : &DNS::BL::DNSBL_ECONNECT();
    }

    print Data::Dumper->Dump([ \%db ]);

    untie %db;

    return wantarray ? (&DNS::BL::DNSBL_OK, "OK - Done") : 
	&DNS::BL::DNSBL_OK;
}

1;
__END__

=pod

=back

=head2 EXPORT

None by default.


=head1 HISTORY

$Log: db.pm,v $
Revision 1.5  2004/11/09 22:49:20  lem
Return valid results even with slightly corrupt indexes

Revision 1.4  2004/10/24 20:29:51  lem
Added an index to speed up _read and _match

Revision 1.3  2004/10/21 18:33:08  lem
Added rudimentary import support + bulk mode

Revision 1.2  2004/10/12 17:44:46  lem
Updated docs. Added print with format

Revision 1.1  2004/10/11 21:16:34  lem
Basic db and commands added


=head1 SEE ALSO

Perl(1), L<DNS::BL>.

=head1 AUTHOR

Luis Muñoz, E<lt>luismunoz@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004 by Luis Muñoz

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
