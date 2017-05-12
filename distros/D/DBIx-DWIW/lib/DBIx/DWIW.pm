package DBIx::DWIW;

use 5.005;
use strict;
use DBI;
use Carp;
use Sys::Hostname;  ## for reporting errors
use Time::HiRes;    ## for fast timeouts

our $VERSION = '0.50';
our $SAFE    = 1;

=head1 NAME

DBIx::DWIW - Robust and simple DBI wrapper to Do What I Want (DWIW)

=head1 SYNOPSIS

When used directly:

  use DBIx::DWIW;

  my $db = DBIx::DWIW->Connect(DB   => $database,
                               User => $user,
                               Pass => $password,
                               Host => $host);

  my @records = $db->Array("select * from foo");

When sub-classed for full functionality:

  use MyDBI;  # class inherits from DBIx::DWIW

  my $db = MyDBI->Connect('somedb') or die;

  my @records = $db->Hashes("SELECT * FROM foo ORDER BY bar");

=head1 DESCRIPTION

NOTE: This module is currently specific to MySQL, but needn't be. We just
haven't had a need to talk to any other database server.

DBIx::DWIW was developed (over the course of roughly 1.5 years) in Yahoo!
Finance (http://finance.yahoo.com/) to suit our needs. Parts of the API may
not make sense and the documentation may be lacking in some areas. We've
been using it for so long (in one form or another) that these may not be
readily obvious to us, so feel free to point that out. There's a reason the
version number is currently < 1.0.

This module was B<recently> extracted from Yahoo-specific code, so things
may be a little strange yet while we smooth out any bumps and blemishes
left over form that.

DBIx::DWIW is B<intended to be sub-classed>. Doing so gives you all the
benefits it can provide and the ability to easily customize some of its
features. You can, of course, use it directly if it meets your needs as-is.
But you'll be accepting its default behavior in some cases where it may not
be wise to do so.

The DBIx::DWIW distribution comes with a sample sub-class in the file
C<examples/MyDBI.pm> which illustrates some of what you might want to do in
your own class(es).

This module provides three main benefits:

=head2 Centralized Configuration

Rather than store the various connection parameters (username, password,
hostname, port number, database name) in each and every script or
application which needs them, you can easily put them in once place--or
even generate them on the fly by writing a bit of custom code.

If this is all you need, consider looking at Brian Aker's fine
C<DBIx::Password> module on the CPAN. It may be sufficient.

=head2 API Simplicity

Taking a lesson from Python (gasp!), this module promotes one obvious way
to do most things. If you want to run a query and get the results back as a
list of hashrefs, there's one way to do that. The API may sacrifice speed
in some cases, but new users can easily learn the simple and descriptive
method calls. (Nobody is forcing you to use it.)

=head2 Fault Tolerance

Databases sometimes go down. Networks flake out. Bad stuff happens. Rather
than have your application die, DBIx::DWIW provides a way to handle
outages. You can build custom wait/retry/fail logic which does anything you
might want (such as ringing your pager or sending e-mail).

=head2 Transaction Handling

As of version 0.25, three transaction related methods were added to DWIW.
These methods were designed to make transaction programming easier in a
couple of ways.

Consider a code snippet like this:

  sub do_stuff_with_thing
  {
      $db->Begin();
      $db->Execute("some sql here");
      $db->Execute("another query here");
      $db->Commit();
  }

That's all well an good. You have a function that you can call and it will
perform 2 discrete actions as part of a transaction. However, what if you
need to call that in the context of a larger transaction from time to time?
What you'd like to do is this:

  $db->Begin();
  for my $thing (@thing_list)
  {
      do_stuff_with_thing($thing);
  }
  $db->Commit();

and have it all wrapped up in once nice juicy transaction.

With DBIx::DWIW, you can. That is, in fact, the default behavior. You can
call C<Begin()> as many times as you want, but it'll only ever let you
start a single transaction until you call the corresponding commit. It does
this by tracking the number of times you call C<Begin()> and C<Commit()>. A
counter is incremented each time you call C<Begin()> and decremented each
time you call C<Commit()>. When the count reaches zero, the original
transaction is actually committed.

Of course, there are problems with that method, so DBIx::DWIW provides an
alternative. You can use I<named transactions>. Using named transactions
instead, the code above would look like this:

  sub do_stuff_with_thing
  {
      $db->Begin('do_stuff transaction');
      $db->Execute("some sql here");
      $db->Execute("another query here");
      $db->Commit('do_stuff transaction');
  }

and:

  $db->Begin('Big Transaction');
  for my $thing (@thing_list)
  {
      do_stuff_with_thing($thing);
  }
  $db->Commit('Big Transaction');

In that way, you can avoid problems that might be caused by not calling
C<Begin()> and C<Commit()> the same number of times. Once a named
transaction is begun, the module simply ignores any C<Begin()> or
C<Commit()> calls that don't have a name or whose name doesn't match that
assigned to the currently open transaction.

The only exception to this rule is C<Rollback()>. Because a transaction
rollback usually signifies a big problem, calling C<Rollback()> B<always>
ends the currently running transaction.

Return values for these functions are a bit different, too. C<Begin()> and
C<Commit()> can return undef, 0, or 1. undef means there was an error. 0
means that nothing was done (but there was no error either), and 1 means
that work was done.

The methods are:

=over

=item Begin

Start a new transaction if one is not already running.

=item Commit

Commit the current transaction, if one is running.

=item Rollback

Rollback the current transaction, if one is running.

=back

See the detailed method descriptions below for all the gory details.

Note that C<Begin()>, C<Commit()>, and C<Rollback()> are not protected by
DBIx::DWIW's normal wait/retry logic if a network connection fails. This
because I'm not sure that it it makes sense. If your connection drops and
the other end notices, it'll probably rollback for you anyway.

=head1 DBIx::DWIW CLASS METHODS

The following methods are available from DBIx::DWIW objects. Any function
or method not documented should be considered private. If you call it, your
code may break someday and it will be B<your> fault.

The methods follow the Perl tradition of returning false values when an
error occurs (and usually setting $@ with a descriptive error message).

Any method which takes an SQL query string can also be passed bind values
for any placeholders in the query string:

  $db->Hashes("SELECT * FROM foo WHERE id = ?", $id);

Any method which takes an SQL query string can also be passed a prepared
DWIW statement handle:

  $db->Hashes($sth, $id);

=over

=cut

##
## This is the cache of currently-open connections, filled with
##       $CurrentConnections{host,user,password,db . class} = $db
##
my %CurrentConnections;

##
## Autoload to trap method calls that we haven't defined. The default (when
## running in unsafe mode) behavior is to check $dbh to see if it can()
## field the call. If it can, we call it. Otherwise, we die.
##

use vars '$AUTOLOAD';

sub AUTOLOAD
{
    my $method = $AUTOLOAD;
    my $self   = shift;

    $method =~ s/.*:://;  ## strip the package name

    my $orig_method = $method;

    if ($self->{SAFE})
    {
        if (not $method =~ s/^dbi_//)
        {
            $@ = "undefined or unsafe method ($orig_method) called";
            Carp::croak("$@");
        }
    }

    if ($self->{DBH} and $self->{DBH}->can($method))
    {
        $self->{DBH}->$method(@_);
    }
    else
    {
        Carp::croak("undefined method ($orig_method) called");
    }
}

##
## Allow the user to explicitly tell us if they want SAFE on or off.
##

sub import
{
    my $class = shift;

    while (my $arg = shift @_)
    {
        if ($arg eq 'unsafe')
        {
            $SAFE = 0;
        }
        elsif ($arg eq 'safe')
        {
            $SAFE = 1;
        }
        else
        {
            warn "unknown use argument: $arg";
        }
    }
}

##
## This is an 'our' variable so that it can be easily overridden with
## 'local', e.g.
##
##   {
##      local($DBIx::DWIW::ConnectTimeoutOverride) = $DBIx::DWIW::ShorterTimeout($ConnectTimeoutOverride, 1.5)
##      Some::Routine::That::Connects();
##   }
##
## It has the following semantics:
##    undef   -- unset; no impact
##      0     -- infinite timeout (no timeout)
##     > 0    -- timeout, in seconds
##
our $ConnectTimeoutOverride;
our %ConnectTimeoutOverrideByHost; ## on a per-host basis

our $QueryTimeoutOverride;
our %QueryTimeoutOverrideByHost; ## on a per-host basis

##
## Given two timeouts, return the one that's shorter. Note that a false
## value is the same as an infinite timeout, so 1 is shorter than 0.
##
sub ShorterTimeout($$)
{
    my $a = shift;
    my $b = shift;

    if (not defined $a) {
        return $b;
    } elsif (not defined $b) {
        return $a;
    } elsif (not $a) {
        return $b;
    } elsif (not $b) {
        return $a;
    } elsif ($a < $b) {
        return $a;
    } else {
        return $b;
    }
}


=item Connect()

The C<Connect()> constructor creates and returns a database connection
object through which all database actions are conducted. On error, it
calls C<die()>, so you may want to C<eval {...}> the call.  The
C<NoAbort> option (described below) controls that behavior.

C<Connect()> accepts ``hash-style'' key/value pairs as arguments.  The
arguments which it recognizes are:

=over

=item Host

The name of the host to connect to. Use C<undef> to force a socket
connection on the local machine.

=item User

The database user to authenticate as.

=item Pass

The password to authenticate with.

=item DB

The name of the database to use.

=item Socket

NOT IMPLEMENTED.

The path to the Unix socket to use.

=item Port

The port number to connect to.

=item Proxy

Set to true to connect to a DBI::ProxyServer proxy.  You'll also need
to set ProxyHost, ProxyKey, and ProxyPort.  You may also want to set
ProxyKey and ProxyCipher.

=item ProxyHost

The hostname of the proxy server.

=item ProxyPort

The port number on which the proxy is listening.  This is probably
different than the port number on which the database server is
listening.

=item ProxyKey

If the proxy server you're using requires encryption, supply the
encryption key (as a hex string).

=item ProxyCipher

If the proxy server requires encryption, supply the name of the
package which provides encryption.  Typically this is something
like C<Crypt::DES> or C<Crypt::Blowfish>.

=item Unique

A boolean which controls connection reuse.

If false (the default), multiple C<Connect>s with the same connection
parameters (User, Pass, DB, Host) return the same open
connection. If C<Unique> is true, it returns a connection distinct
from all other connections.

If you have a process with an active connection that fork()s, be aware
that you CANNOT share the connection between the parent and child.
Well, you can if you're REALLY CAREFUL and know what you're doing.
But don't do it.

Instead, acquire a new connection in the child. Be sure to set this
flag when you do, or you'll end up with the same connection and spend
a lot of time pulling your hair out over why the code does mysterious
things.

As of version 0.27, DWIW also checks the class name of the caller and
guarantees unique connections across different classes.  So if you
call Connect() from SubClass1 and SubClass2, each class gets its own
connection.

=item Verbose

Turns verbose reporting on.  See C<Verbose()>.

=item Quiet

Turns off warning messages.  See C<Quiet()>.

=item NoRetry

If true, the C<Connect()> fails immediately if it can't connect to
the database. Normally, it retries based on calls to
C<RetryWait()>.  C<NoRetry> affects only C<Connect>, and has no effect
on the fault-tolerance of the package once connected.

=item NoAbort

If there is an error in the arguments, or in the end the database
can't be connected to, C<Connect()> normally prints an error message
and dies. If C<NoAbort> is true, it puts the error string into
C<$@> and return false.

=item Timeout

The amount of time (in seconds) after which C<Connect()> should give up and
return. You may use fractional seconds. A Timeout of zero is the same as
not having one at all.

If you set the timeout, you probably also want to set C<NoRetry> to a
true value.  Otherwise you'll be surprised when a server is down and
your retry logic is running.

=item QueryTimeout

The amount of time (in seconds) after which query operations should give up
and return. You may use fractional seconds. A Timeout of zero is the same
as not having one at all.

=back

There are a minimum of four components to any database connection: DB,
User, Pass, and Host. If any are not provided, there may be defaults
that kick in. A local configuration package, such as the C<MyDBI>
example class that comes with DBIx::DWIW, may provide appropriate
default connection values for several database. In such a case, a
client may be able to simply use:

    my $db = MyDBI->Connect(DB => 'Finances');

to connect to the C<Finances> database.

As a convenience, you can just give the database name:

    my $db = MyDBI->Connect('Finances');

See the local configuration package appropriate to your installation
for more information about what is and isn't preconfigured.

=cut

sub Connect($@)
{
    my $class = shift;
    my $use_slave_hack = 0;
    my $config_name;

    ##
    ## If the user asks for a slave connection like this:
    ##
    ##   Connect('Slave', 'ConfigName')
    ##
    ## We'll try calling FindSlave() to find a slave server.
    ##
    if (@_ == 2 and ($_[0] eq 'Slave' or $_[0] eq 'ReadOnly'))
    {
        $use_slave_hack = 1;
        shift;
    }

    my %Options;

    ##
    ## Handle $self->Connect('SomeConfig')
    ##
    if (@_ % 2 != 0)
    {
        $config_name = shift;
        if (my $config = $class->LocalConfig($config_name))
        {
            %Options = (%{$config}, @_);
        }
        else
        {
            die "unknown local config \"$config_name\", or bad number of arguments to Connect: " . join(", ", $config_name, @_);
        }
    }
    else
    {
        %Options = @_;
    }

    my $UseSlave = delete($Options{UseSlave});

    if ($use_slave_hack)
    {
        $UseSlave = 1;
    }

    ## Find a slave to use, if we can.

    if ($UseSlave)
    {
        if ($class->can('FindSlave'))
        {
            %Options = $class->FindSlave(%Options);
        }
        else
        {
            warn "$class doesn't know how to find slaves";
        }
    }

    ##
    ## Fetch the arguments.
    ##
    my $DB       =  delete($Options{DB})   || $class->DefaultDB();
    my $User     =  delete($Options{User}) || $class->DefaultUser($DB);
    my $Password =  delete($Options{Pass});
    my $Port     =  delete($Options{Port}) || $class->DefaultPort($DB);
    my $Unique   =  delete($Options{Unique});
    my $Retry    = !delete($Options{NoRetry});
    my $Quiet    =  delete($Options{Quiet});
    my $NoAbort  =  delete($Options{NoAbort});
    my $ConnectTimeout =  delete($Options{Timeout});
    my $QueryTimeout   =  delete($Options{QueryTimeout});
    my $Verbose  =  delete($Options{Verbose}); # undef = no change
                                               # true  = on
                                               # false = off
    ## allow empty passwords
    $Password = $class->DefaultPass($DB) if not defined $Password;

    $config_name = $DB unless defined $config_name;

    ## respect the DB_DOWN hack
    $Quiet = 1 if $ENV{DB_DOWN};

    ##
    ## Host parameter is special -- we want to recognize
    ##    Host => undef
    ## as being "no host", so we have to check for its existence in the hash,
    ## and default to nothing ("") if it exists but is empty.
    ##
    my $Host;
    if (exists $Options{Host})
    {
        $Host =  delete($Options{Host}) || "";
    }
    else
    {
        $Host = $class->DefaultHost($DB) || "";
    }

    if (not $DB)
    {
        $@ = "missing DB parameter to Connect";
        die $@ unless $NoAbort;
        return ();
    }

    if (not $User)
    {
        $@ = "missing User parameter to Connect";
        die $@ unless $NoAbort;
        return ();
    }

    if (not defined $Password)
    {
        $@ = "missing Pass parameter to Connect";
        die $@ unless $NoAbort;
        return ();
    }

#      if (%Options)
#      {
#          my $keys = join(', ', keys %Options);
#          $@ = "bad parameters [$keys] to Connect()";
#          die $@ unless $NoAbort;
#          return ();
#      }

    my $myhost = hostname();
    my $desc;

    if (defined $Host)
    {
        $desc = "connection to $Host\'s MySQL server from $myhost";
    }
    else
    {
        $desc = "local connection to MySQL server on $myhost";
    }

    ## we're going to build the dsn up incrementally...
    my $dsn;

    ## proxy details
    ##
    ## This can be factored together once I'm sure it is working.

    # DBI:Proxy:cipher=Crypt::DES;key=$key;hostname=$proxy_host;port=8192;dsn=DBI:mysql:$db:$host

    if ($Options{Proxy})
    {
        if (not ($Options{ProxyHost} and $Options{ProxyPort}))
        {
            $@ = "ProxyHost and ProxyPort are required when Proxy is set";
            die $@ unless $NoAbort;
            return ();
        }

        $dsn = "DBI:Proxy";

        my $proxy_port = $Options{ProxyPort};
        my $proxy_host = $Options{ProxyHost};

        if ($Options{ProxyCipher} and $Options{ProxyKey})
        {
            my $proxy_cipher = $Options{ProxyCipher};
            my $proxy_key    = $Options{ProxyKey};

            $dsn .= ":cipher=$proxy_cipher;key=$proxy_key";
        }

        $dsn .= ";hostname=$proxy_host;port=$proxy_port";
        $dsn .= ";dsn=DBI:mysql:$DB:$Host;mysql_client_found_rows=1";
    }
    else
    {
        if ($Port)
        {
            $dsn .= "DBI:mysql:$DB:$Host;port=$Port;mysql_client_found_rows=1";
        }
        else
        {
            $dsn .= "DBI:mysql:$DB:$Host;mysql_client_found_rows=1";
        }
    }

    warn "DSN: $dsn\n" if $ENV{DEBUG};

    ##
    ## If we're not looking for a unique connection, and we already have
    ## one with the same options, use it.
    ##
    if (not $Unique)
    {
        if (my $db = $CurrentConnections{$dsn . $class})
        {
            if (defined $Verbose)
            {
                $db->{VERBOSE} = $Verbose;
            }

            return $db;
        }
    }


    if ($Host and my $Override = $ConnectTimeoutOverrideByHost{$Host})
    {
        $ConnectTimeout = ShorterTimeout($ConnectTimeout, $Override);
    }
    elsif ($ConnectTimeoutOverride)
    {
        $ConnectTimeout = ShorterTimeout($ConnectTimeout, $ConnectTimeoutOverride);
    }

    if ($Host and my $Override = $QueryTimeoutOverrideByHost{$Host})
    {
        $QueryTimeout = ShorterTimeout($QueryTimeout, $Override);
    }
    elsif ($QueryTimeoutOverride)
    {
        $QueryTimeout = ShorterTimeout($QueryTimeout, $QueryTimeoutOverride);
    }

    my $self = {
                ## Connection info
                DB          => $DB,
                DBH         => undef,
                DESC        => $desc,
                HOST        => $Host,
                PASS        => $Password,
                QUIET       => $Quiet,
                RETRY       => 1,
                UNIQUE      => $Unique,
                USER        => $User,
                PORT        => $Port,
                VERBOSE     => $Verbose,
                SAFE        => $SAFE,
                DSN         => $dsn,
                UNIQUE_KEY  => $dsn . $class,
                CONNECT_TIMEOUT => $ConnectTimeout,
                QUERY_TIMEOUT   => $QueryTimeout,
                RetryCount  => 0,

                ## Transaction info
                BeginCount  => 0,  ## ++ on Begin, -- on Commit, reset Rollback
                TrxRunning  => 0,  ## true after a Begin
                TrxName     => undef,
               };

    $self = bless $self, $class;

    if ($ENV{DBIxDWIW_VERBOSE}) {
        $self->{VERBOSE} = 1;
    }

    if (my $routine = $self->can("PreConnectHook")) {
        $routine->($self);
    }

    if ($ENV{DBIxDWIW_CONNECTION_DEBUG}) {
        require Data::Dumper;

        local($Data::Dumper::Indent) = 2;
        local($Data::Dumper::Purity) = 0;
        local($Data::Dumper::Terse)  = 1;

        Carp::cluck("DBIx::DWIW Connecting:\n" . Data::Dumper::Dumper($self) . "\n\t");
    }

    my $dbh;
    my $done = 0;

    while (not $done)
    {
        local($SIG{PIPE}) = 'IGNORE';

        ## If the user wants a timeout, we need to set that up and do
        ## it here.  This looks complex, but it's really a no-op
        ## unless the user wants it.
        ##
        ## Notice that if a timeout is hit, then the RetryWait() stuff
        ## will never have a chance to run.  That's good, but we need
        ## to make sure that users expect that.

        if ($self->{CONNECT_TIMEOUT})
        {
            eval
            {
                local $SIG{ALRM} = sub { die "alarm\n" };

                Time::HiRes::alarm($self->{CONNECT_TIMEOUT});
                $dbh = DBI->connect($dsn, $User, $Password, { PrintError => 0 });
                Time::HiRes::alarm(0);
            };
            if ($@ eq "alarm\n")
            {
                if (my $routine = $self->can("ConnectTimeoutHook")) {
                    $routine->($self);
                }

                my $timeout = $self->{CONNECT_TIMEOUT};
                undef $self; # this fires the DESTROY, which sets $@, so must
                             # do before setting $@ below.

                $@ = "connection timeout ($timeout sec passed)";
                return ();
            }
        }
        else
        {
            $dbh = DBI->connect($dsn, $User, $Password, { PrintError => 0 });
        }

        if (not ref $dbh)
        {
            if (not $DBI::errstr and $@)
            {
                ##
                ## Must be a problem with loading DBD or something --
                ## a *perl* problem as opposed to a network/credential
                ## problem. If we clear $Retry now, we'll ensure to drop
                ## into the die 'else' clause below.
                ##
                $Retry = 0;
            }

            if ($Retry
                and
                ($DBI::errstr =~ m/can\'t connect/i
                 or
                 $DBI::errstr =~ m/Too many connections/i
                 or
                 $DBI::errstr =~ m/Lost connection to MySQL server/i)
                and
                $self->RetryWait($DBI::errstr))
            {
                $done = 0; ## Heh.
            }
            else
            {
                my $ERROR = ($DBI::errstr || $@ || "internal error");

                ##
                ## If DBI::ProxyServer is being used and the target mmysql
                ## server refuses the connection (wrong password, trying to
                ## access a db that they've not been given permission for,
                ## etc.) DBI::ProxyServer just reports "Unexpected EOF from
                ## server". Let's give the user a hint as to what that
                ## might mean.
                ##
                if ($ERROR =~ m/^Cannot log in to DBI::ProxyServer: Unexpected EOF from server/) {
                    $ERROR =    "Cannot log in via DBI::ProxyServer: Unexpected EOF from server (check user's MySQL credentials and privileges)";
                }
                if (not $NoAbort) {
                    die $ERROR;
                }
                elsif (not $Quiet) {
                    warn $ERROR;
                }

                $@ = $ERROR;
                $self->_OperationFailed();

                undef $self; # This fires the DESTROY, which sets $@.
                $@ = $ERROR; # Just in case the DESTROY did set $@.
                return ();
            }
        }
        else
        {
            eval { $dbh->{AutoCommit} = 1};
            $dbh->{mysql_auto_reconnect} = 1;
            $done = 1;  ## it worked!
        }
    } ## end while not done

    ##
    ## We got through....
    ##
    $self->_OperationSuccessful();
    $self->{DBH} = $dbh;

    ##
    ## Save this one if it's not to be unique.
    ##
    if (not $Unique)
    {
        $CurrentConnections{$self->{UNIQUE_KEY}} = $self;
    }

    return $self;
}

*new = \&Connect;

=item Dump()

Dump the internal configuration to stdout.  This is mainly useful for
debugging DBIx::DWIW.  You probably don't need to call it unless you
know what you're doing. :-)

=cut

sub Dump
{
    my $self = shift;

    ## Trivial dumping of key/value pairs.
    for my $key (sort keys %$self)
    {
        print "$key: $self->{$key}\n" unless not defined $self->{$key};
    }
}

=item Timeout()

Like the QueryTimeout argument to Connect(), sets (or resets) the amount of
time (in seconds) after which queries should give up and return. You may
use fractional seconds. A timeout of zero is the same as not having one at
all.

C<Timeout()> called with any (or no) arguments returns the current
query timeout value.

=cut

sub Timeout(;$)
{
    my $self = shift;
    my $time = shift;

    if (defined $time)
    {
        $self->{QUERY_TIMEOUT} = $time;
    }

    print "QUERY_TIMEOUT SET TO: $self->{QUERY_TIMEOUT}\n" if $self->{VERBOSE};

    return $self->{QUERY_TIMEOUT};
}

=item Disconnect()

Closes the connection. Upon program exit, this is called automatically
on all open connections. Returns true if the open connection was
closed, false if there was no connection or there was some other
error (with the error being returned in C<$@>).

=cut

sub Disconnect($)
{
    my $self = shift;
    my $class = ref $self;

    if (not $self->{UNIQUE})
    {
        delete $CurrentConnections{$self->{UNIQUE_KEY}};
    }

    if (not $self->{DBH})
    {
        # Not an error, since this gets called as part of the destructor --
        # might not be connected even though the object exists.
        return ();
    }

    ## clean up a lingering sth if there is one...

    if (defined $self->{RecentExecutedSth})
    {
        $self->{RecentExecutedSth}->finish();
    }

    if (not $self->{DBH}->disconnect())
    {
        $@ = "couldn't disconnect (or wasn't disconnected)";
        $self->{DBH} = undef;
        return ();
    }
    else
    {
        $@ = "";
        $self->{DBH} = undef;
        return 1;
    }
}

sub DESTROY($)
{
    my $self = shift;
    $self->Disconnect();
}

=item Quote(@values)


Calls the DBI C<quote()> function on each value, returning a list of
properly quoted values. As per quote(), NULL is returned for
items that are not defined.

=cut

sub Quote($@)
{
    my $self  = shift;
    my $dbh   = $self->dbh();
    my @ret;

    for my $item (@_)
    {
        push @ret, $dbh->quote($item);
    }

    if (wantarray)
    {
        return @ret;
    }

    if (@ret > 1)
    {
        return join ', ', @ret;
    }

    return $ret[0];
}

=item InList($field => @values)

Given a field and a value or values, returns SQL appropriate for a
WHERE clause in the form

    field = 'value'

or

    field IN ('value1', 'value2', ...)

depending on the number of values. Each value is passed through
C<Quote> while building the SQL.

If no values are provided, nothing is returned.

This function is useful because MySQL apparently does not optimize

    field IN ('val')

as well as it optimizes

    field = 'val'

=item InListUnquoted($field => @values)

Just like C<InList>, but the values are not passed through C<Quote>.

=cut

sub InListUnquoted
{
    my $self   = shift;
    my $field  = shift;
    my @values = @_;

    if (@values == 1) {
        return "$field = $values[0]";
    } elsif (@values > 1) {
        return "$field IN (" . join(', ', @values) . ')';
    } else {
        return ();
    }
}

sub InList
{
    my $self   = shift;
    my $field  = shift;
    my @values = $self->Quote(@_);

    return $self->InListUnquoted($field => @values);
}


=pod

=item ExecuteReturnCode()

Returns the return code from the most recently Execute()d query.  This
is what Execute() returns, so there's little reason to call it
directly.  But it didn't use to be that way, so old code may be
relying on this.

=cut

sub ExecuteReturnCode($)
{
    my $self = shift;
    return $self->{ExecuteReturnCode};
}

## Private version of Execute() that deals with statement handles
## ONLY.  Given a statement handle, call execute and insulate it from
## common problems.

sub _Execute()
{
    my $self      = shift;
    my $statement = shift;
    my @bind_vals = @_;

    if (not ref $statement)
    {
        $@ = "non-reference passed to _Execute()";
        warn "$@" unless $self->{QUIET};
        return ();
    }

    my $sth = $statement->{DBI_STH};

    print "_EXECUTE: $statement->{SQL}: ", join(" | ", @bind_vals), "\n" if $self->{VERBOSE};

    ##
    ## Execute the statement. Retry if requested.
    ##
    my $done = 0;

    ## mysql_auto_reconnect (DBD::mysql >= 2.9) should always be in
    ## lockstep with AutoCommit.
    $self->{DBH}->{mysql_auto_reconnect} = $self->{DBH}->{AutoCommit};

    while (not $done)
    {
        local($SIG{PIPE}) = 'IGNORE';

        ## If the user wants a timeout, we need to set that up and do
        ## it here.  This looks complex, but it's really a no-op
        ## unless the user wants it.
        ##
        ## Notice that if a timeout is hit, the RetryWait() stuff
        ## will never have a chance to run.  That's good, but we need
        ## to make sure that users expect that.

        if ($self->{QUERY_TIMEOUT})
        {
            eval
            {
                local $SIG{ALRM} = sub { die "alarm\n" };

                Time::HiRes::alarm($self->{QUERY_TIMEOUT});
                $self->{ExecuteReturnCode} = $sth->execute(@bind_vals);
                Time::HiRes::alarm(0);
            };
            if ($@ eq "alarm\n")
            {
                if (my $routine = $self->can("ExecuteTimeoutHook")) {
                    $routine->($self, $statement);
                }

                $@ = "query timeout ($self->{QUERY_TIMEOUT} sec passed)";
                return ();
            }
        }
        else
        {
            $self->{ExecuteReturnCode} = $sth->execute(@bind_vals);
        }

        ##
        ## Otherwise, if it's an error that we know is "retryable" and
        ## the user wants to retry (based on the RetryWait() call),
        ## we'll try again.  But we will not retry if in the midst of a
        ## transaction.
        ##
        if (not defined $self->{ExecuteReturnCode})
        {
            my $err = $self->{DBH}->errstr;

            if (not $self->{TrxRunning}
                and
                $self->{RETRY}
                and (
                     $err =~ m/Lost connection/
                     or
                     $err =~ m/server has gone away/
                     or
                     $err =~ m/Server shutdown in progress/
                    ))
            {
                if ($self->RetryWait($err))
                {
                    next;
                }
            }

            ##
            ## It is really an error that we cannot (or should not)
            ## retry, so spit it out if needed.
            ##
            $@ = "$err [in prepared statement]";
            Carp::cluck "execute of prepared statement returned undef [$err]" if $self->{VERBOSE};
            $self->_OperationFailed();
            return ();
        }
        else
        {
            $done = 1;
        }
    }

    ##
    ## Got through.
    ##
    $self->_OperationSuccessful();

    print "EXECUTE successful\n" if $self->{VERBOSE};

    ##
    ## Save this as the most-recent successful statement handle.
    ##
    $self->{RecentExecutedSth} = $sth;

    ##
    ## Execute worked -- return the statement handle.
    ##
    return $self->{ExecuteReturnCode}
}

## Public version of Execute that deals with SQL only and calls
## _Execute() to do the real work.

=item Execute($sql)

Executes the given SQL, returning true if successful, false if not
(with the error in C<$@>).

C<Do()> is a synonym for C<Execute()>

=cut

sub Execute($$@)
{
    my $self      = shift;
    my $sql       = shift;
    my @bind_vals = @_;

    if (not $self->{DBH})
    {
        $@ = "not connected in Execute()";
        Carp::croak "not connected to the database" unless $self->{QUIET};
    }

    my $sth;

    if (ref $sql)
    {
        $sth = $sql;
    }
    else
    {
        print "EXECUTE> $sql\n" if $self->{VERBOSE};
        $sth = $self->Prepare($sql, 0+@bind_vals);
    }

    return $sth->Execute(@bind_vals);
}

##
## Do is a synonym for Execute.
##
*Do = \&Execute;

=item Prepare($sql)

Prepares the given sql statement, but does not execute it (just like
DBI). Instead, it returns a statement handle C<$sth> that you can
later execute by calling its Execute() method:

  my $sth = $db->Prepare("INSERT INTO foo VALUES (?, ?)");

  $sth->Execute($a, $b);

The statement handle returned is not a native DBI statement
handle. It's a DBIx::DWIW::Statement handle.

When called from Execute(), Scalar(), Hashes(), etc. AND there
are values to substitute, the statement handle is cached.
This benefits a typical case where ?-substitutions being done
lazily in an Execute call inside a loop.
Meanwhile, interpolated sql queries, non-? queries, and
manually Prepare'd statements are unaffected.  These typically
do not benefit from moving caching the prepare.

Note: prepare-caching is of no benefit until Mysql 4.1.

=cut

sub Prepare($$;$)
{
    my $self = shift;
    my $sql  = shift;
    my $has_bind = shift;

    if (not $self->{DBH})
    {
        $@ = "not connected in Prepare()";

        if (not $self->{QUIET})
        {
            carp scalar(localtime) . ": not connected to the database";
        }
        return ();
    }

    $@ = "";  ## ensure $@ is clear if not error.

    if ($self->{VERBOSE})
    {
        print "PREPARE> $sql\n";
    }

    ## Automatically cache the prepare if there are bind args.

    my $dbi_sth = $has_bind ?
          $self->{DBH}->prepare_cached($sql) :
          $self->{DBH}->prepare($sql);

    ## Build the new statement handle object and bless it into
    ## DBIx::DWIW::Statement.  Then return that object.

    $self->{RecentPreparedSth} = $dbi_sth;

    my $sth = {
                SQL     => $sql,      ## save the sql
                DBI_STH => $dbi_sth,  ## the real statement handle
                PARENT  => $self,     ## remember who created us
              };

    return bless $sth, 'DBIx::DWIW::Statement';
}

=item RecentSth()

Returns the DBI statement handle (C<$sth>) of the most-recently
I<successfully executed> statement.

=cut

sub RecentSth($)
{
    my $self = shift;
    return $self->{RecentExecutedSth};
}

=item RecentPreparedSth()

Returns the DBI statement handle (C<$sth>) of the most-recently
prepared DBI statement handle (which may or may not have already been
executed).

=cut

sub RecentPreparedSth($)
{
    my $self = shift;
    return $self->{RecentPreparedSth};
}

=item InsertedId()

Returns the C<mysql_insertid> associated with the most recently
executed statement. Returns nothing if there is none.

Synonyms: C<InsertID()>, C<LastInsertID()>, and C<LastInsertId()>

=cut

sub InsertedId($)
{
    my $self = shift;
    if ($self->{RecentExecutedSth}
        and
        defined($self->{RecentExecutedSth}->{mysql_insertid}))
    {
        return $self->{RecentExecutedSth}->{mysql_insertid};
    }
    else
    {
        return ();
    }
}

## Aliases for people who like Id or ID and Last or not Last. :-)

*InsertID     = \&InsertedId;
*LastInsertID = \&InsertedId;
*LastInsertId = \&InsertedId;

=item RowsAffected()

Returns the number of rows affected for the most recently executed
statement.  This is valid only if it was for a non-SELECT. (For
SELECTs, count the return values). As per the DBI, -1 is returned
if there was an error.

=cut

sub RowsAffected($)
{
    my $self = shift;
    if ($self->{RecentExecutedSth})
    {
        return $self->{RecentExecutedSth}->rows();
    }
    else
    {
        return ();
    }
}

=item RecentSql()

Returns the SQL of the most recently executed statement.

=cut

sub RecentSql($)
{
    my $self = shift;
    if ($self->{RecentExecutedSth})
    {
        return $self->{RecentExecutedSth}->{Statement};
    }
    else
    {
        return ();
    }
}

=item PreparedSql()

Returns the SQL of the most recently prepared statement.
(Useful for showing SQL that doesn't parse.)

=cut

sub PreparedSql($)
{
    my $self = shift;
    if ($self->{RecentpreparedSth})
    {
        return $self->{RecentPreparedSth}->{SQL};
    }
    else
    {
        return ();
    }
}

=item Hash($sql)

A generic query routine. Pass an SQL statement that returns a single
record, and it returns a hashref with all the key/value pairs of
the record.

The example at the bottom of page 50 of DuBois's I<MySQL> book would
return a value similar to:

  my $hashref = {
     last_name  => 'McKinley',
     first_name => 'William',
  };

On error, C<$@> has the error text, and false is returned. If the
query doesn't return a record, false is returned, but C<$@> is also
false.

Use this routine only if the query will return a single record.  Use
C<Hashes()> for queries that might return multiple records.

Because calling C<Hashes()> on a larger recordset can use a lot of
memory, you may wish to call C<Hash()> once with a valid query and
call it repeatedly with no SQL to retrieve records one at a time.
It'll take more CPU to do this, but it is more memory efficient:

  my $record = $db->Hash("SELECT * FROM big_table");
  do {
      # ... do something with $record
  }  while (defined($record = $db->Hash()));

Note that a call to any other DWIW query resets the iterator, so only
do so when you are finished with the current query.

This seems like it breaks the principle of having only one obvious way
to do things with this package.  But it's really not all that obvious,
now is it? :-)

=cut

sub Hash($$@)
{
    my $self      = shift;
    my $sql       = shift || "";
    my @bind_vals = @_;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected in Hash()";
        return ();
    }

    print "HASH: $sql\n" if ($self->{VERBOSE});

    my $result = undef;

    if ($sql eq "" or $self->Execute($sql, @bind_vals))
    {
        my $sth = $self->{RecentExecutedSth};
        $result = $sth->fetchrow_hashref;

        if (not $result)
        {
            if ($sth->err)
            {
                $@ = $sth->errstr . " [$sql] ($sth)";
            }
            else
            {
                $@ = "";
            }
            $sth->finish;   ## (else get error about statement handle still active)
        }
    }
    return $result ? $result : ();
}

=item Hashes($sql)

A generic query routine. Given an SQL statement, returns a list of
hashrefs, one per returned record, containing the key/value pairs of
each record.

The example in the middle of page 50 of DuBois's I<MySQL> would return
a value similar to:

 my @hashrefs = (
  { last_name => 'Tyler',    first_name => 'John',    birth => '1790-03-29' },
  { last_name => 'Buchanan', first_name => 'James',   birth => '1791-04-23' },
  { last_name => 'Polk',     first_name => 'James K', birth => '1795-11-02' },
  { last_name => 'Fillmore', first_name => 'Millard', birth => '1800-01-07' },
  { last_name => 'Pierce',   first_name => 'Franklin',birth => '1804-11-23' },
 );

On error, C<$@> has the error text, and false is returned. If the
query doesn't return a record, false is returned, but C<$@> is also
false.

=cut

sub Hashes($$@)
{
    my $self      = shift;
    my $sql       = shift;
    my @bind_vals = @_;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected in Hashes()";
        return ();
    }

    print "HASHES: $sql\n" if $self->{VERBOSE};

    my @records;

    if ($self->Execute($sql, @bind_vals))
    {
        my $sth = $self->{RecentExecutedSth};

        while (my $ref = $sth->fetchrow_hashref)
        {
            push @records, $ref;
        }
    }
    $self->{RecentExecutedSth}->finish;
    return @records;
}

=item Array($sql)

Similar to C<Hash()>, but returns a list of values from the matched
record. On error, the empty list is returned and the error can be
found in C<$@>. If the query matches no records, an empty list is
returned but C<$@> is false.

The example at the bottom of page 50 of DuBois's I<MySQL> would return
a value similar to:

  my @array = ( 'McKinley', 'William' );

Use this routine only if the query will return a single record.  Use
C<Arrays()> or C<FlatArray()> for queries that might return multiple
records.

=cut

sub Array($$@)
{
    my $self      = shift;
    my $sql       = shift;
    my @bind_vals = @_;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected Array()";
        return ();
    }

    print "ARRAY: $sql\n" if $self->{VERBOSE};

    my @result;

    if ($self->Execute($sql, @bind_vals))
    {
        my $sth = $self->{RecentExecutedSth};
        @result = $sth->fetchrow_array;

        if (not @result)
        {
            if ($sth->err)
            {
                $@ = $sth->errstr . " [$sql]";
            }
            else
            {
                $@ = "";
            }
        }
        $sth->finish;   ## (else get error about statement handle still active)
    }
    return @result;
}

=pod

=item Arrays($sql)

A generic query routine. Given an SQL statement, returns a list of
array refs, one per returned record, containing the values of each
record.

The example in the middle of page 50 of DuBois's I<MySQL> would return
a value similar to:

 my @arrayrefs = (
  [ 'Tyler',     'John',     '1790-03-29' ],
  [ 'Buchanan',  'James',    '1791-04-23' ],
  [ 'Polk',      'James K',  '1795-11-02' ],
  [ 'Fillmore',  'Millard',  '1800-01-07' ],
  [ 'Pierce',    'Franklin', '1804-11-23' ],
 );

On error, C<$@> has the error text, and false is returned. If the
query doesn't return a record, false is returned, but C<$@> is also
false.

=cut

sub Arrays($$@)
{
    my $self      = shift;
    my $sql       = shift;
    my @bind_vals = @_;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected Arrays()";
        return ();
    }

    print "ARRAYS: $sql\n" if $self->{VERBOSE};

    my @records;

    if ($self->Execute($sql, @bind_vals))
    {
        my $sth = $self->{RecentExecutedSth};

        while (my $ref = $sth->fetchrow_arrayref)
        {
            push @records, [@{$ref}]; ## perldoc DBI to see why!
        }
    }
    return @records;
}

=pod

=item FlatArray($sql)

A generic query routine. Pass an SQL string, and all matching fields
of all matching records are returned in one big list.

If the query matches a single records, C<FlatArray()> ends up being
the same as C<Array()>. But if there are multiple records matched, the
return list will contain a set of fields from each record.

The example in the middle of page 50 of DuBois's I<MySQL> would return
a value similar to:

     my @items = (
         'Tyler', 'John', '1790-03-29', 'Buchanan', 'James', '1791-04-23',
         'Polk', 'James K', '1795-11-02', 'Fillmore', 'Millard',
         '1800-01-07', 'Pierce', 'Franklin', '1804-11-23'
     );

C<FlatArray()> tends to be most useful when the query returns one
column per record, as with

    my @names = $db->FlatArray('select distinct name from mydb');

or two records with a key/value relationship:

    my %IdToName = $db->FlatArray('select id, name from mydb');

But you never know.

=cut

sub FlatArray($$@)
{
    my $self      = shift;
    my $sql       = shift;
    my @bind_vals = @_;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected in FlatArray()";
        return ();
    }

    print "FLATARRAY: $sql\n" if $self->{VERBOSE};

    my @records;

    if ($self->Execute($sql, @bind_vals))
    {
        my $sth = $self->{RecentExecutedSth};

        while (my $ref = $sth->fetchrow_arrayref)
        {
            push @records, @{$ref};
        }
    }
    return @records;
}

=pod

=item FlatArrayRef($sql)

Works just like C<FlatArray()> but returns a ref to the array instead
of copying it.  This is a big win if you have very large arrays.

=cut

sub FlatArrayRef($$@)
{
    my $self      = shift;
    my $sql       = shift;
    my @bind_vals = @_;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected in FlatArray()";
        return ();
    }

    print "FLATARRAY: $sql\n" if $self->{VERBOSE};

    my @records;

    if ($self->Execute($sql, @bind_vals))
    {
        my $sth = $self->{RecentExecutedSth};

        while (my $ref = $sth->fetchrow_arrayref)
        {
            push @records, @{$ref};
        }
    }
    return \@records;
}

=pod

=item Scalar($sql)

A generic query routine. Pass an SQL string, and a scalar is
returned.

If the query matches a single row column pair this is what you want.
C<Scalar()> is useful for computational queries, count(*), max(xxx),
etc.

my $max = $dbh->Scalar('select max(id) from personnel');

If the result set contains more than one value, the first value is returned
and a warning is issued.

=cut

sub Scalar()
{
    my $self = shift;
    my $sql  = shift;
    my @bind_vals = @_;
    my $ret;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected in Scalar()";
        return ();
    }

    print STDERR "SCALAR: $sql\n" if $self->{VERBOSE};

    if ($self->Execute($sql, @bind_vals))
    {
        my $sth = $self->{RecentExecutedSth};

        if ($sth->rows() > 1 or $sth->{NUM_OF_FIELDS} > 1)
        {
          warn "$sql in DWIW::Scalar returned more than 1 row and/or column";
        }
        my $ref = $sth->fetchrow_arrayref;
        $ret = ${$ref}[0];
        $sth->finish;   ## (else get error about statement handle still active)
    }
    return $ret;
}

=pod

=item CSV($sql)

A generic query routine. Pass an SQL string, and a CSV scalar is
returned.

my $max = $dbh->CSV('select * from personnel');

The example in the middle of page 50 of DuBois\'s I<MySQL> would
return a value similar to:

     my $item = <<END_OF_CSV;
     "Tyler","John","1790-03-29"
     "Buchanan","James","1791-04-23"
     "Polk","James K","1795-11-02"
     "Fillmore","Millard","1800-01-07",
     "Pierce","Franklin","1804-11-23"
     END_OF_CSV

=cut

sub CSV()
{
    my $self = shift;
    my $sql  = shift;
    my $ret;

    $@ = "";

    if (not $self->{DBH})
    {
        $@ = "not connected in Scalar()";
        return ();
    }

    print STDERR "SCALAR: $sql\n" if $self->{VERBOSE};

    if ($self->Execute($sql))
    {
        my $sth = $self->{RecentExecutedSth};

        while (my $ref = $sth->fetchrow_arrayref)
        {
            my $col = 0;
            foreach (@{$ref})
            {
                if (defined($_))
                {
                  $ret .= ($sth->{mysql_type_name}[$col++] =~
                           /(char|text|binary|blob)/) ?
                             "\"$_\"," : "$_,";
                }
                else
                {
                  $ret .= "NULL,";
                }
            }

            $ret =~ s/,$/\n/;
        }
    }

    return $ret;
}

=pod

=item Verbose([boolean])

Returns the value of the verbose flag associated with the connection.
If a value is provided, it is taken as the new value to install.
Verbose is OFF by default.  If you pass a true value, you'll get some
verbose output each time a query executes.

Returns the current value.

=cut

sub Verbose()
{
    my $self = shift;
    my $val = $self->{VERBOSE};

    if (@_)
    {
        $self->{VERBOSE} = shift;
    }

    return $val;
}

=pod

=item Quiet()

When errors occur, a message will be sent to STDOUT if Quiet is true
(it is by default).  Pass a false value to disable it.

Returns the current value.

=cut

sub Quiet()
{
    my $self = shift;

    if (@_)
    {
        $self->{QUIET} = shift;
    }

    return $self->{QUIET};
}

=pod

=item Safe()

Enable or disable "safe" mode (on by default).  In "safe" mode, you
must prefix a native DBI method call with "dbi_" in order to call it.
If safe mode is off, you can call native DBI methods using their real
names.

For example, in safe mode, you'd write something like this:

  $db->dbi_commit;

but in unsafe mode you could use:

  $db->commit;

The rationale behind having a safe mode is that you probably don't
want to mix DBIx::DWIW and DBI method calls on an object unless you
know what you're doing.  You need to opt in.

C<Safe()> returns the current value.

=cut

sub Safe($;$)
{
    my $self = shift;

    if (@_)
    {
        $self->{SAFE} = shift;
    }

    return $self->{SAFE};
}

=pod

=item dbh()

Returns the real DBI database handle for the connection.

=cut

sub dbh($)
{
    my $self = shift;
    return $self->{DBH};
}

=pod

=item RetryWait($error)

This method is called each time there is a error (usually caused by a
network outage or a server going down) which a sub-class may want to
examine and decide how to continue.

If C<RetryWait()> returns 1, the operation which was being attempted when
the failure occurred is retried. If C<RetryWait()> returns 0, the action
fails.

The default implementation causes your application to make up to three
immediate reconnect attempts, and if all fail, emit a message to STDERR
(via a C<warn()> call) and then sleep for 30 seconds. After 30 seconds, the
warning and sleep repeat until successful.

You probably want to override this so method that it will eventually give
up. Otherwise your application may hang forever. The default method does
maintain a count of how many times the retry has been attempted in
C<$self->{RetryCount}>.

Note that RetryWait() is not be called in the middle of transaction.
In that case, we assume that the transaction will have been rolled
back by the server and you'll get an error.

=cut

sub RetryWait($$)
{
    my $self  = shift;
    my $error = shift;

    if ($self->{RetryCount} > 9) # we failed too many times, die already. 
    {
        return 0;
    }

    ##
    ## Immediately retry a few times, to pick up timed-out connections
    ##
    if ($self->{RetryCount}++ <= 2)
    {
        return 1;
    }
    elsif (not $self->{RetryStart})
    {
        $self->{RetryStart} = time;
        $self->{RetryCommand} = $0;
        $0 = "(waiting on db) $0";
    }

    if (not $self->{QUIET}) {
        my $now = localtime;
        warn "$now: db connection down ($error), retry in 30 seconds";
    }
    sleep 30;

    return 1;
}

##
## [non-public member function]
##
## Called whenever a database operation has been successful, to reset the
## internal counters, and to send a "back up" message, if appropriate.
##
sub _OperationSuccessful($)
{
    my $self = shift;

    if (not $self->{QUIET} and $self->{RetryCount} > 1)
    {
        my $now   = localtime;
        my $since = localtime($self->{RetryStart});
        warn "$now: $self->{DESC} is back up (down since $since)\n";
    }

    if ($self->{RetryCommand}) {
        $0 = $self->{RetryCommand};
        undef $self->{RetryCommand};
    }
    $self->{RetryCount}  = 0;
    undef $self->{RetryStart};
}

##
## [non-public member function]
##
## Called whenever a database operation has finally failed after all the
## retries that will be done for it.
##
sub _OperationFailed($)
{
    my $self = shift;
    $0 = $self->{RetryCommand} if $self->{RetryCommand};

    $self->{RetryCount}  = 0;
    $self->{RetryStart}  = undef;
    $self->{RetryCommand}= undef;
}

=pod

=back

=head1 Local Configuration

There are two ways to to configure C<DBIx::DWIW> for your local
databases.  The simplest (but least flexible) way is to create a
package like:

    package MyDBI;
    @ISA = 'DBIx::DWIW';
    use strict;

    sub DefaultDB   { "MyDatabase"         }
    sub DefaultUser { "defaultuser"        }
    sub DefaultPass { "paSSw0rd"           }
    sub DefaultHost { "mysql.somehost.com" }
    sub DefaultPort { 3306                 }

The four routines override those in C<DBIx::DWIW>, and explicitly
provide exactly what's needed to contact the given database.

The user can then use

    use MyDBI
    my $db = MyDBI->Connect();

and not have to worry about the details.

A more flexible approach appropriate for multiple-database or
multiple-user installations is to create a more complex package, such
as the C<MyDBI.pm> which was included in the C<examples> sub-directory
of the DBIx::DWIW distribution.

In that setup, you have quit a bit of control over what connection
parameters are used.  And, since it's Just Perl Code, you can do
anything you need in there.

=head2 Methods Related to Connection Defaults

The following methods are provided to support this in sub-classes:

=over

=item LocalConfig($name)

Passed a configuration name, C<LocalConfig()> should return a list of
connection parameters suitable for passing to C<Connect()>.

By default, C<LocalConfig()> simply returns an empty list.

=cut

sub LocalConfig($$)
{
    return ();
}

=pod

=item DefaultDB($config_name)

Returns the default database name for the given configuration.  Calls
C<LocalConfig()> to get it.

=cut

sub DefaultDB($)
{
    my ($class, $DB) = @_;

    if (my $DbConfig = $class->LocalConfig($DB))
    {
        return $DbConfig->{DB};
    }

    return ();
}

=pod

=item DefaultUser($config_name)

Returns the default username for the given configuration. Calls
C<LocalConfig()> to get it.

=cut

sub DefaultUser($$)
{
    my ($class, $DB) = @_;

    if (my $DbConfig = $class->LocalConfig($DB))
    {
        return $DbConfig->{User};
    }
    return ();
}

=pod

=item DefaultPass($config_name)

Returns the default password for the given configuration.
Calls C<LocalConfig()> to get it.

=cut

sub DefaultPass($$)
{
    my ($class, $DB, $User) = @_;
    if (my $DbConfig = $class->LocalConfig($DB))
    {
        if (defined $DbConfig->{Pass})
        {
            return $DbConfig->{Pass};
        }
    }
    return ();
}

=pod

=item DefaultHost($config_name)

Returns the default hostname for the given configuration.  Calls
C<LocalConfig()> to get it.

=cut

sub DefaultHost($$)
{
    my ($class, $DB) = @_;
    if (my $DbConfig = $class->LocalConfig($DB))
    {
        if ($DbConfig->{Host})
        {
                return $DbConfig->{Host};
        }
    }
    return ();
}

=pod

=item DefaultPort($config_name)

Returns the default port number for the given configuration.  Calls
C<LocalConfig()> to get it.

=cut

sub DefaultPort($$)
{
    my ($class, $DB) = @_;
    if (my $DbConfig = $class->LocalConfig($DB))
    {
        if ($DbConfig->{Port})
        {
            if ($DbConfig->{Host} eq hostname)
            {
                return (); #use local connection
            }
            else
            {
                return $DbConfig->{Host};
            }
        }
    }
    return ();
}

=pod

=head2 Transaction Methods

=over

=item Begin([name)

Begin a new transaction, optionally naming it.

=cut

sub Begin
{
    my $self = shift;
    my $name = shift;

    ## if one is already running, just increment count if we need to
    if ($self->{TrxRunning})
    {
        print "Begin() called with running transaction - " if $self->{VERBOSE};
        if ($self->{BeginCount} and not defined $name)
        {
            print "$self->{BeginCount}\n" if $self->{VERBOSE};
            $self->{BeginCount}++;
        }
        else
        {
            print "$self->{TrxName}\n" if $self->{VERBOSE};
        }

        return 1;
    }

    print "Begin() starting new transaction - " if $self->{VERBOSE};

    ## it is either named or not.
    if (defined $name)
    {
        $self->{TrxName} = $name;
        print "$name\n" if $self->{VERBOSE};
    }
    else
    {
        $self->{BeginCount} = 1;
        print "(auto-count)\n" if $self->{VERBOSE};
    }

    $self->{TrxRunning} = 1;
    eval { $self->{DBH}->{AutoCommit} = 0 };
    $self->{DBH}->{mysql_auto_reconnect} = 0;
    return $self->{DBH}->begin_work;
}

=pod

=item Commit([name)

Commit the current transaction (or named transaction).

=cut

sub Commit
{
    my $self = shift;
    my $name = shift;

    ## if there is no transaction running now
    if (not $self->{TrxRunning})
    {
        print "Commit() called without a transaction\n" if $self->{VERBOSE};
        return 0;
    }

    ## if the controlling transaction was auto-counting
    if ($self->{BeginCount})
    {
        ## if this commit was named, skip it.
        if (defined $name)
        {
            print "Commit() skipping named commit on auto-counting transaction"
                if $self->{VERBOSE};
            return 0;
        }

        ## decrement
        $self->{BeginCount}--;

        ## need to commit
        if ($self->{BeginCount} == 0)
        {
            print "Commit()ing auto-counting transaction\n" if $self->{VERBOSE};
            my $rc = $self->{DBH}->commit;
            $self->{TrxRunning} = 0;
            eval { $self->{DBH}->{AutoCommit} = 1; };
            $self->{DBH}->{mysql_auto_reconnect} = 1;
            $self->{BeginCount} = 0;
            $self->{TrxName}    = undef;   ## just in case
            return $rc;
        }
        elsif ($self->{BeginCount} > 0)
        {
            print "Commit() decremented BeginCount\n" if $self->{VERBOSE};
            return 0;
        }
        else
        {
            print "Commit() is confused -- BeginCount went negative!\n"
                if $self->{VERBOSE};
            $@ = "Commit() is confused.  BeginCount went negative!";
            return ();
        }

    }

    ## if the controlling transaction was named, deal with it.

    if (defined $self->{TrxName})
    {
        ## if the commit was not named, do nothing.
        if (not defined $name)
        {
            print "Commit() skipping unnamed commit on named begin\n"
                if $self->{VERBOSE};
            return 0;
        }

        ## if the commit was named, the names need to match.
        if ($name ne $self->{TrxName})
        {
            print "Commit() skipping named commit due to name mismatch\n"
                if $self->{VERBOSE};
            return 0;
        }

        my $rc;

        ## if they match, commit.
        if ($name eq $self->{TrxName})
        {
            print "Commit()ing transaction - $self->{TrxName}\n"
                if $self->{VERBOSE};
            $rc = $self->{DBH}->commit;
            $self->{TrxRunning} = 0;
            eval { $self->{DBH}->{AutoCommit} = 1 };
            $self->{DBH}->{mysql_auto_reconnect} = 1;
            $self->{BeginCount} = 0;      ## just in case
            $self->{TrxName}    = undef;
            return $rc;
        }
    }

    ## otherwise, we're confused.  we should never end up here.
    else
    {
        print "Commit() is confused -- something is wonky\n" if $self->{VERBOSE};
        $@ = "Commit() is confused.  Internal state problem.";
        return ();
    }

}

=pod

=item Rollback()

Rollback the current transaction.

=cut

sub Rollback
{
    my $self = shift;

    if (not $self->{TrxRunning})
    {
        print "Rollback() called without a transaction\n" if $self->{VERBOSE};
        return;
    }

    ## rollback via DBI and reset things
    my $rc = $self->{DBH}->rollback;
    $self->{TrxRunning} = 0;
    eval { $self->{DBH}->{AutoCommit} = 1 };
    $self->{DBH}->{mysql_auto_reconnect} = 1;
    $self->{BeginCount} = 0;
    $self->{TrxName}    = undef;
    print "Rollback() transaction\n" if $self->{VERBOSE};
    return $rc;
}

=pod

=back

=cut

######################################################################

=pod

=back

=head1 The DBIx::DWIW::Statement CLASS

Calling C<Prepare()> on a database handle returns a
DBIx::DWIW::Statement object which acts like a limited DBI statement
handle.

=head2 Methods

The following methods can be called on a statement object.

=over

=cut

package DBIx::DWIW::Statement;

use vars '$AUTOLOAD';

sub AUTOLOAD
{
    my $self   = shift;
    my $method = $AUTOLOAD;

    $method =~ s/.*:://;  ## strip the package name

    my $orig_method = $method;

    if ($self->{SAFE})
    {
        if (not $method =~ s/^dbi_//)
        {
            Carp::cluck("undefined or unsafe method ($orig_method) called in");
        }
    }

    if ($self->{DBI_STH} and $self->{DBI_STH}->can($method))
    {
        $self->{DBI_STH}->$method(@_);
    }
    else
    {
        Carp::cluck("undefined method ($orig_method) called");
    }
}

## This looks funny, so I should probably explain what is going on.
## When Execute() is called on a statement handle, we need to know
## which $db object to use for execution.  Luckily that was stashed
## away in $self->{PARENT} when the statement was created.  So we call
## the _Execute method on our parent $db object and pass ourselves.
## Since $db->_Execute() only accepts Statement objects, this is just
## as it should be.

=pod

=item Execute([@values])

Executes the statement.  If values are provided, they'll be substituted
for the appropriate placeholders in the SQL.

=cut

sub Execute(@)
{
    my $self      = shift;
    my @bind_vals = @_;
    my $db        = $self->{PARENT};

    return $db->_Execute($self, @bind_vals);
}

sub DESTROY
{
#      my $self = shift;

#      return unless defined $self;
#      return unless ref($self);

#      if ($self->{DBI_STH})
#      {
#          $self->{DBI_STH}->finish();
#      }
}

1;

=pod

=back

=head1 AUTHORS

DBIx::DWIW evolved out of some Perl modules that we developed and used
in Yahoo! Finance (http://finance.yahoo.com).  The following people
contributed to its development:

  Jeffrey Friedl (jfriedl@yahoo.com)
  rayg (rayg@bitbaron.com)
  John Hagelgans
  Jeremy Zawodny (Jeremy@Zawodny.com)

=head1 CREDITS

The following folks have provided feedback, patches, and other help
along the way:

  Eric E. Bowles (bowles@ambisys.com)
  David Yan (davidyan@yahoo-inc.com)
  DH <crazyinsomniac@yahoo.com>
  Toby Elliott (telliott@yahoo-inc.com)
  Keith C. Ivey (keith@smokefreedc.org)
  Brian Webb (brianw@yahoo-inc.com)
  Steve Friedl (steve@unixwiz.net)

Please direct comments, questions, etc to Jeremy for the time being.
Thanks.

=head1 COPYRIGHT

DBIx::DWIW is Copyright (c) 2001, Yahoo! Inc.  All rights reserved.

You may distribute under the same terms of the Artistic License, as
specified in the Perl README file.

=head1 SEE ALSO

L<DBI>, L<perl>

Jeremy's presentation at the 2001 Open Source Database Summit, which
introduced DBIx::DWIW is available from:

  http://jeremy.zawodny.com/mysql/

=cut
