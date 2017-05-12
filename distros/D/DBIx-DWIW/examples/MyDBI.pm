package MyDBI;
use DBIx::DWIW 'safe';
@ISA = 'DBIx::DWIW';
use strict;

=head1 NAME

C<MyDBI> -- example sub-class of C<DBIx::DWIW>

=head1 SYNOPSIS

  use MyDBI;

  my $db = MyDBI->Connect();

  ## do stuff

See C<DBIx::DWIW> for the functions available to the C<$db> object.

This is the sample C<MyDBI.pm> distributed with C<DBIx::DWIW>.

=head1 DESCRIPTION

This package knows many named database configurations (they're like
ODBC DSNs in the Windows world, if that helps you at all). They have
names like C<Finance>, C<Games>, C<Homer>, etc., with C<Homer> being
the default. To access another, use something like:

  my $db = MyDBI->Connect('Games');

Note that if you use the single argument form of C<Connect()>, which
we highly recommend, you are specifying a B<configuration name>, not
necessarily a database name.  That is, configuration names and
database names may not necessarily be related.  You might have a
database called C<Homer> on two servers, test and production.  You
might defined a configuration named C<Homer-test> and one called
C<Homer-prod> to make things clear.  The two may only differ in the
host they connect to.

The configuration name internally supplies a host, user, password, and
database name. Using these gives us the flexability to move/rename
databases, servers, and make other changes without having to update
lots of code.

=cut

my $default_user = 'db_user';
my $default_pass = 'db_pass';
my $default_host = 'db.foobar.org';
my $default_db   = 'Homer';
my $slave_user   = 'readonly';
my $slave_pass   = 'ImAslave';

my @defaults = ( Host   => $default_host,
		 User   => $default_user,
		 Pass   => $default_pass );


my %Config =
(
 Finance =>
  {
  @defaults,
  DB => 'Finance'
  },

 'Games' =>
 {
  @defaults,
  DB   => 'test',
  User => 'gamer',
  Pass => 'IlikeDOOM',
 },

'Homer' =>
 {
  @defaults,
  DB   => 'Homer',
  Host => 'homer-db.foobar.org',
 },

);

##
## Given a DB name, return the configuration for it.
##
sub LocalConfig($$)
{
    my ($class, $name) = @_;

    if ($name)
    {
	return $Config{$name};
    }
    else
    {
	return $Config{$default_db};
    }
}

##
## Default Host, User, and Password for users of this package
##
sub DefaultDB      { return $default_db   }
sub RawDefaultUser { return $default_user }
sub RawDefaultPass { return $default_pass }
sub RawDefaultHost { return $default_host }

##
## How long to sleep between checks of a down database.
## Elements are either a number in seconds, or a control item.
## Control items are references to hashes, with the following elements:
##     Mail -- address to send a "database is down" message.
##
## Once all elements have been cycled through, the original function
## (connect, database access, etc.) will return failed.
##
my @RetryCycleSleep =
  ( 0, 5, 10,                                                    # back-off
    { Mail => 'db-admin@foobar.org' },                           # mail
    30,30,30,30,30,30,30,30,30,30,                               # 5 minutes
    { Mail => 'page-db-admin@foobar.org' },                      # page
    30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30,30, # 10 minutes
  );

##
## Returns true if the action should be retried, false if the it
## should bail.
##
sub RetryWait($$)
{
    my $db   = shift;
    my $error = shift;

    if (not $db->{RetryStart})
    {
	$db->{RetryStart} = time;
	$db->{RetryCommand} = $0;
	$0 = "(waiting on db) $0";
    }

    ## If we "know" the dbi is down, then just retry.  Will enhance
    ## this logic later to bitch if things have been down too long.

    if (-e '/tmp/.dbi_down')
    {
        sleep 30;
        return 1;
    }

    my $item = $RetryCycleSleep[ $db->{RetryCount}++ ];

    if (not defined $item)
    {
	## Ran off the end of the list -- bail
	warn scalar(localtime). ": giving up\n";
	return 0;
    }

    if (not ref $item)
    {
	## Just a number of seconds to sleep
	if ($item)
	{
	    my $now = localtime;
	    warn "$now: sleeping for $item [$error]\n";
	    sleep $item;
	}
	return 1;
    }
    else
    {
	if ($item->{Mail} and open MAIL, "|/usr/sbin/sendmail $item->{Mail}")
	{
	    warn "sending mail to $item->{Mail}\n";
	    print MAIL "$db->{DESC} is down\nError: $error\nProgram: $0\n";
	    close MAIL;

            $db->{RetryMailed}->{$item->{Mail}} = 1;
	}
	return $db->RetryWait($error);
    }
}

1;


__END__
