package CAM::Session;

=head1 NAME

CAM::Session - DBI and cookie CGI session state maintenance

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 COMPARISON

CGI::Session is a better module than this one, but this one is a
little easier to use.  If you are starting from scratch, use
CGI::Session.  If you are using CAM::App, then we recommend this
module for session management since CAM::App takes care of all of the
details for you.

See README for more detail.

=head1 SYNOPSIS

  use CAM::Session;
  use DBI;
  my $dbh = DBI->connect(...);
  CAM::Session->setDBH($dbh);
  
  my $session = new CAM::Session();
  $session->printCookie();
  
  $session->set("username", $username);
  ...
  $session->get("username", $username);
  $session->delete("username");

To periodically clean up the session table, run a script like the
following as a daily scheduled task:

  use CAM::Session;
  use DBI;
  my $dbh = DBI->connect(...) || die "no dbh";
  CAM::Session->setDBH($dbh);
  CAM::Session->setExpiration(24*60*60); # older than one day
  CAM::Session->clean();

=head1 DESCRIPTION

CAM::Session interacts with the CGI program, the database and the
visitor's cookie to create a storage space for persistent data.

=cut

#----------------

require 5.005_62;
use strict;
use warnings;
use Carp;
use CGI::Cookie;
use CGI;
use DBI;

our @ISA = qw();
our $VERSION = '1.03';

# global settings, can be overridden for the whole class or for
# individual instances.
our $global_expiration = 24*60*60;  # one day, in seconds
our $global_dbh = undef;
our $global_dbTablename = "session";
our $global_cookieName = "session";
our $global_keylength = 16;

our $colname_key  = "session_key";
our $colname_time = "session_time";
our $colname_data = "session_data";

#----------------

=head1 FUNCTIONS

=over 4

=cut

#----------------

=item new

=item new DBIHANDLE

Create a new session object, retrieving the session ID from the
cookie, if any.  If the database handle is not set here, it must have
been set previously via the setDBH() class method.

=cut

sub new
{
   my $pkg = shift;
   my $dbh = shift; # optional

   my $self = bless({
      data => {},
      expiration => $global_expiration,
      dbTablename => $global_dbTablename,
      cookieName => $global_cookieName,
      dbh => $dbh || $global_dbh,
      needsSave => 0,
   }, $pkg);

   if (!$self->{dbh})
   {
      &carp("No database connection has been specified.  Please use ".$pkg."::setDBH()");
      return undef;
   }
   if (!ref($self->{dbh}) || ref($self->{dbh}) !~ /^(DBI|DBD)\b/)
   {
      my $type = ref($self->{dbh}) ? ref($self->{dbh}) : "scalar";
      &carp("The DBH object is not a valid DBI/DBD connection: $type");
      return undef;
   }

   my %cookies = CGI::Cookie->fetch();
   if (exists $cookies{$self->{cookieName}})
   {
      # existing session
      $self->{id} = $cookies{$self->{cookieName}}->value;
      if (!$self->loadSessionData())
      {
         $self->_newSession();
      }
   }
   else
   {
      $self->_newSession();
   }

   return $self;
}
#----------------

=item DESTROY

Saves the session data on object destruction, if needed.

=cut

sub DESTROY
{
   my $self = shift;
   if ($self->{needsSave})
   {
      $self->saveSessionData();
   }
   return $self;
}
#----------------

=item getID

=cut

sub getID
{
   my $self = shift;
   return $self->{id};
}
#----------------

=item getCookie

Return a cookie that indicates this session.  Any arguments are passed
to CGI::Cookie::new().  Use this, for example, with

    print CGI->header(-cookie => $session->getCookie);

=cut

sub getCookie
{
   my $self = shift;

   my $id = $self->getID();
   my $cookie = CGI::Cookie->new(-name => $self->{cookieName},
                                 -value => $id,
                                 -path => "/",
                                 @_);
   return $cookie;
}
#----------------

=item printCookie

Outputs a cookie that indicates this session.  Use this just before
"print CGI->header()", for example.

=cut

sub printCookie
{
   my $self = shift;

   my $cookie = $self->getCookie(@_);
   print "Set-Cookie: $cookie\n";
}
#----------------

=item getAll

Retrieve a hash of all of the session data.

=cut

sub getAll
{
   my $self = shift;

   if (wantarray)
   {
      return (%{$self->{data}});
   }
   else
   {
      return (scalar keys %{$self->{data}});
   }
}
#----------------

=item get FIELDNAME

Retrieve a field from the session storage.

=cut

sub get
{
   my $self = shift;
   my $fieldName = shift;

   return undef if (!defined $fieldName);
   return $self->{data}->{$fieldName};
}
#----------------

=item set FIELDNAME, VALUE, FIELDNAME, VALUE, ...

Record a field in the session storage.  If autoSave is on (it is
by default) this value is immediately recorded in the database.

=cut

sub set
{
   my $self = shift;

   while (@_ > 0)
   {
      my $fieldName = shift;
      my $value = shift;

      return undef if (!defined $fieldName);

      $self->{data}->{$fieldName} = $value;
   }
   $self->{needsSave} = 1;
   return $self;
}
#----------------

=item delete FIELDNAME, FIELDNAME, ...

Remove one or more fields from the session storage.  If autoSave is on
(it is by default) this change is immediately recorded in the
database.

=cut

sub delete
{
   my $self = shift;

   foreach my $fieldName (@_)
   {
      delete $self->{data}->{$fieldName};
   }
   $self->{needsSave} = 1;
   return $self;
}
#----------------

=item clear

Calls delete() on every field in the session storage.

=cut

sub clear
{
   my $self = shift;
   return $self->delete(keys %{$self->{data}});
}
#----------------

=item loadSessionData

Retrieve the session data from storage.  This function is called by
new() so it is only needed if you need to reload the data for some
reason.

Returns a boolean indicating the success or failure of the load
operation.

=cut

sub loadSessionData
{
   my $self = shift;

   my $id = $self->getID();
   return undef if (!$id);
   my $dbrow = $self->_getSession($id);
   return undef if (!$dbrow);
      
   $self->{data} = $self->_explode($dbrow->{$colname_data});
   if (!$self->{data})
   {
      $self->{data} = {};
      return undef;
   }
   $self->{needsSave} = 0;
   return $self;
}
#----------------

=item saveSessionData

Write the session data to permanent storage.  This function is called
by the set() method. so it is only needed if you have turned off the
autoSave feature.

Returns a boolean indicating the success or failure of the save
operation.

=cut

sub saveSessionData
{
   my $self = shift;

   my $id = $self->getID();
   return undef if (!$id);
   my $data = $self->_implode($self->{data});
   $data = "" if (!defined $data);
   my $dbh = $self->{dbh};
   my $result = $dbh->do("update $$self{dbTablename} set " .
                         "$colname_data=" . $dbh->quote($data) . "," .
                         "$colname_time=now() " .
                         "where $colname_key='$id'");

   return undef if ((!$result) || $result == 0);
   return $self;
}
#----------------

=item isNewSession

Returns true if this session was newly created (as opposed to a repeat
visitor)

=cut

sub isNewSession
{
   my $self = shift;
   return $self->{newsession};
}
#----------------

# PRIVATE FUNCTION
sub _newSession
{
   my $self = shift;

   $self->{id} = undef;

   my $dbh = $self->{dbh};
   my $tries = 0;
   # Loop until we get an unused ID, but give up if it takes too long
   while ($tries++ < 20)
   {
      my $id = $self->_newID();
      my $sth = $dbh->prepare("select count(*) from $$self{dbTablename} " .
                              "where $colname_key=?");
      $sth->execute($id);
      my ($matches) = $sth->fetchrow_array();
      $sth->finish();

      if ($matches == 0)
      {
         $dbh->do("insert into $$self{dbTablename} set " .
                  "$colname_key='$id',$colname_time=now()");
         $self->{id} = $id;
         $self->{newsession} = 1;
         last;
      }
   }
   return $self;
}

# PRIVATE FUNCTION
sub _getSession
{
   my $self = shift;
   my $id = shift;

   return undef if (!$id);

   my $dbh = $self->{dbh};
   my $sth = $dbh->prepare("select *" .
                           (defined $self->{expiration} ?
                            ",date_add(now(), interval -$$self{expiration} second) as expires "
                            : "") .
                           "from $$self{dbTablename} " .
                           "where $colname_key=?");
   $sth->execute($id);
   my $row = $sth->fetchrow_hashref();
   $sth->finish();

   return undef if (!$row);

   if (defined $self->{expiration})
   {
      $row->{$colname_time} =~ s/\D//g;
      $row->{expires} =~ s/\D//g;
      
      if ($row->{$colname_time} lt $row->{expires})
      {
         $dbh->do("delete from $$self{dbTablename} " .
                  "where $colname_key=" . $dbh->quote($self->{cachekey}));
         return undef;
      }
   }

   return $row;
}
#----------------

=item setDBH DBI_HANDLE

Set the global database handle for this package.  Use like this:

  CAM::Session->setDBH($dbh);

=cut

sub setDBH
{
   my $pkg = shift; # unused
   my $val = shift;
   $global_dbh = $val;
}
#----------------

=item setExpiration SECONDS

Set the duration for the session content.  If the session is older
than the specified time, a new session will be created.  The default
expiration is unlimited (set solely by the visitor's cookie
expiration).  This is a class method

Use like this:

  CAM::Session->setExpiration($seconds);

=cut

sub setExpiration
{
   my $pkg = shift; # unused
   my $val = shift;
   $global_expiration = $val;
}
#----------------

=item setTableName NAME

Set the name of the database table that is used for the session
storage.  This is a class method.

Use like this:

  CAM::Session->setTableName($name);

=cut

sub setTableName
{
   my $pkg = shift; # unused
   my $val = shift;
   $global_dbTablename = $val;
}
#----------------

=item setCookieName NAME

Set the name of the cookie that is used for the recording the session.
This is a class method.

Use like this:

  CAM::Session->setCookieName($name);

=cut

sub setCookieName
{
   my $pkg = shift; # unused
   my $val = shift;
   $global_cookieName = $val;
}
#----------------


# PRIVATE FUNCTION
sub _implode
{
   my $self = shift;
   my $H_data = shift;

   # Treat the hash like an array.  The keys and values are treated
   # identically.
   my @escaped = (%$H_data);
   foreach (@escaped)
   {
      $_ = "" if (!defined $_);
      $_ = CGI::escape($_);
   }
   return join(",", @escaped);
}

# PRIVATE FUNCTION
sub _explode
{
   my $self = shift;
   my $implosion = shift;

   $implosion = "" if (!defined $implosion);

   # The split limit of -1 prevents trailing blank fields from being omitted
   my @fields = split /,/, $implosion, -1;
   if (@fields %2 != 0)
   {
      &carp("not an even number of fields in imploded data");
      return undef;
   }
   foreach (@fields)
   {
    $_ = CGI::unescape($_);
   }
   return {@fields};
}

# PRIVATE FUNCTION
sub _newID
{
   my $self = shift;

   require Digest::MD5;
   # Copied from CGI::Session::ID::MD5
   my $md5 = Digest::MD5->new();
   $md5->add($$ , time() , rand(9999) );
   return substr($md5->hexdigest(), 0, $global_keylength);
}
#----------------

=item setup

=item setup DBIHANDLE, TABLENAME

Create a database table for storing sessions.  This is not
intended to be called often, if ever.  This is a class method.

=cut

sub setup
{
   my $pkg = shift; # unused
   my $dbh = shift || $global_dbh;
   my $tablename = shift || $global_dbTablename;

   $dbh->do("create table if not exists $tablename (" .
            "$colname_key char($global_keylength) primary key not null," .
            "$colname_time timestamp," .
            "$colname_data mediumtext)");
}
#----------------

=item clean

=item clean DBIHANDLE, TABLENAME, SECONDS

Cleans out all records older than the specified number of seconds.
This is a class method.

=cut

sub clean
{
   my $pkg = shift; # unused
   my $dbh = shift || $global_dbh;
   my $tablename = shift || $global_dbTablename;
   my $seconds = shift || $global_expiration;

   return $dbh->do("delete from $tablename " .
                   "where $colname_time < " .
                   "date_add(now(),interval -$seconds second)");
}


1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan

=head1 SEE ALSO

CGI::Session, CAM::App
