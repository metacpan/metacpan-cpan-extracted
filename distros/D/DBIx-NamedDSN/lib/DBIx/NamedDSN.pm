package DBIx::NamedDSN;

use 5.005;
use strict;
use vars qw($VERSION $DBI_KEY_NAME %CACHED_DSNS $NAMED_DSN_CONFIG $CONNECT_INFO_KEY);

use Carp;
use DBI;

$VERSION='0.11';
$DBI_KEY_NAME='ndsn_name';
$NAMED_DSN_CONFIG='@NAMED_DSN_CONFIG@';
$CONNECT_INFO_KEY='ndsn_connection_info';

sub connect {
    my $self=shift;
    my ($name,$user,$pass,@rest)=@_;
    my ($dsn,$st_user,$st_passwd)=$self->get_cached_dsn($name);
    my $dbh;

    # here we pass it through if it looks like a dbi connect string,
    # so people can take advantage of the connect_string method with
    # normal boring handles.

    $dsn=$name if (!$dsn && $name=~/^dbi:/);
    croak "Unrecognized named DSN: '$name'.  (Do you need to add it in '".$NAMED_DSN_CONFIG."'?)" unless $dsn;
    
    $user||=$st_user;
    $pass||=$st_passwd;

    $dbh=DBI->connect($dsn,$user,$pass,@rest);

    if ($dbh) {
	my $hash=tied %$dbh;
	$hash->{$DBI_KEY_NAME}=$name;
	$hash->{$CONNECT_INFO_KEY}={connect_string=>$dsn,user=>$user,pass=>$pass,everything_else=>[@rest]};
    }
    return $dbh;
}

sub get_cached_dsn {
    my $self=shift;
    my $name=shift;
    
    unless (%CACHED_DSNS) {
	open FH, $NAMED_DSN_CONFIG or croak "Could not open config file: ".$NAMED_DSN_CONFIG;
	%CACHED_DSNS=map {split /\t/,$_,2} grep {/\w+\tdbi:\w+/} map {chomp; s/^\s+//; s/\#.*//;$_} <FH>;
	close FH;
    }

    return unless defined $CACHED_DSNS{$name};

    return split(/\t/,$CACHED_DSNS{$name});
}

sub DBI::db::connection_string {
    my $self=shift;
    
    my $hash=tied %$self;
    return $hash->{$DBIx::NamedDSN::CONNECT_INFO_KEY}->{connect_string};
}

sub DBI::db::ndsn_identifier {
    my $self=shift;
    
    my $hash=tied %$self;
    return $hash->{$DBIx::NamedDSN::DBI_KEY_NAME};
}
1;

__END__
=head1 NAME

DBIx::NamedDSN - Store all of your DSNs in the same location.

=head1 SYNOPSIS

  use DBIx::NamedDSN;
  
  $dsn_name="testdb1";
  $dbh=DBIx::NamedDSN->connect($dsn_name);

  # ...everything DBI with $dbh.

  $ident=$dbh->ndsn_identifier;
  $cs=$dbh->connection_string;

=head1 DESCRIPTION

DBIx::NamedDSN simplifies the method of connecting to a DBI data
source, particularly across a diverse and changing data set.  This
also aids in minimizing the changes to existing tools when data
sources are changed.  Rather than having to update a whole set of data
source names across a suite of tools, you can simply change the named
dsn in one place and the tools will automagically work.

Data source strings and (optionally) authentication information are
stored in a central configuration file.  The format of the file is
described later.  (See NAMED_DSN CONFIG FILE.)  Each entry has a
unique name (or token).  This token is what is used to connect to the
database.  If you are changing your database environment over from one
database system to another, if you move a local database over to a
full-fledged database server, or if you just want to be
forward-thinking about your growth potential, this module may be for
you.

In addition to the above, DBIx::NamedDSN adds a method to the DBI
which lets you query any database handle opened with DBIx::NamedDSN
for its connect string.

=head1 DBIx::NamedDSN METHODS AND VARIABLES

This section describes in detail the individual methods provided by
the NamedDSN object.

=over 4

=item C<connect>

  $dbh=DBIx::NamedDSN->connect($dsn_name);
  $dbh=DBIx::NamedDSN->connect($dsn_name,$user,$passwd);

The connect method is the core feature of the module; it is what does
the transform between the nameddsn token and the actual connect
string, as well as connecting you to the actual DBI.  The database
handle that is returned is a normal DBI::db object, with two
additional methods: $dbh->ndsn_identifier() which returns the ndsn
token used to connect, and $dbh->connect_string(), which returns the
connection parameters used to connect to the database.

=item C<$NAMED_DSN_CONFIG>

  $DBIx::NamedDSN::NAMED_DSN_CONFIG="/path/to/config/";

You can set this variable to explictly set where DBIx::NamedDSN looks
for its lookup table.  On build-time, this was set to L<@NAMED_DSN_CONFIG@>.

=back

=head1 NAMED_DSN CONFIG FILE

This section describes the format of the NamedDSN configuration file.
The location of this file is set at build time, and defaults to
"@NAMED_DSN_CONFIG@".  You can explicitly set the path of
the file by setting the variable $DBIx::NamedDSN::NAMED_DSN_CONFIG to
the location you desire.

nameddsn.conf has a simple format, consisting of up to four
tab-delimited columns per record.  Any lines with only whitespace or
comments are ignored.  While currently any lines without tabs are
ignored, this behavior should be considered undefined---its meaning
may change.  DO NOT DEPEND ON THIS CAPABILITY FOR YOUR COMMENTS.

The first two columns in each record are required.  The first column
is the NamedDSN name.  This is a unique token which identifies the
actual dsn used to connect to the DBI.  The second column is the
actual dsn string, as passed to connect.  The optional third column is
the default username to use for this connection.  The optional fourth
column is the default password to use for this connection.

=head1 TODO

=over 4

=item

Option to automagically override DBI's connect by request; ie,

  use DBI;
  use DBIx::NamedDSN qw/magic/;

  $dbh=DBI->connect($shortname,...); # will work automatically!

=item

User configurable resource files (~/.ndsnrc or the like).

=back

=head1 HISTORY

=over 4

=item 0.10

Original release.

=back

=head1 SEE ALSO

L<DBI>

=head1 AUTHOR

David Christensen, E<lt>dwc@dwci.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by David Christensen

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
