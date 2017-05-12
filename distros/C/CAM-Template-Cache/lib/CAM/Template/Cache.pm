package CAM::Template::Cache;

=head1 NAME

CAM::Template::Cache - Template files with database storage

=head1 LICENSE

Copyright 2005 Clotho Advanced Media, Inc., <cpan@clotho.com>

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 SYNOPSIS

  use CAM::Template::Cache;
  CAM::Template::Cache->setDBH($dbh);
  CAM::Template::Cache->setExpiration(60*60); # seconds ago
  
  my $key = $username.":".$pagetype;  # whatever you like
  my $template = new CAM::Template::Cache($key);
  $template->setExpiration(24*60*60); # seconds ago
  if ($template->isFresh()) {
     $template->printCache();
  } else {
     $template->setFilename($templateFilename);
     $template->addParams(blah blah);
     $template->print();
  }

=head1 DESCRIPTION

CAM::Template provides an interface for parameter replacement in a
template file.  This package provides the additional functionality of
storing the completed template in a MySQL database for later quick
retrieval.

Use of the cached version of the template requires a unique key that
will allow retrieval of the completed file, if present.  The cache
uses a time stamp and an expiration interval (default: 1 day) to
decide if the cached copy is recent enough.

This module also includes the class methods setup() and clean() as
convenience functions for initialization and maintenance of the cache
database.

=cut

require 5.005_62;
use strict;
use warnings;
use Carp;
use CAM::Template;

our @ISA = qw(CAM::Template);
our $VERSION = '0.91';

# global settings, can be overridden for the whole class or for
# individual instances.
our $global_expiration = 24*60*60;  # one day, in seconds
our $global_dbh = undef;
our $global_dbTablename = "TemplateCache";
our $global_uselock = 0;

our $colname_key  = "TemplateCache_key";
our $colname_time = "TemplateCache_time";
our $colname_data = "TemplateCache_content";

#--------------------------

=head1 FUNCTIONS

=over 4

=cut

#--------------------------

=item new

=item new CACHEKEY

=item new CACHEKEY, DBIHANDLE

Create a new template object.  To get the caching functionality, the
cachekey is required, and must uniquely identify the content of
interest.  If the cachekey is not specified, then this template
behaves without any of the caching infrastructure.

If the database handle is not set here, it must have been
set previously via the class method setDBH().

Any additional function arguments (namely, a filename or replacement
parameters) are passed on to the CAM::Template constructor.

=cut

sub new
{
   my $pkg = shift;
   my $cachekey = shift;
   my $dbh;
   $dbh = shift if (ref $_[0]);

   my $self = $pkg->SUPER::new(@_);
   $self->{cachekey} = $cachekey;
   $self->{expiration} = $global_expiration;
   $self->{dbTablename} = $global_dbTablename;
   $self->{dbh} = $dbh || $global_dbh;

   if (defined $self->{cachekey})
   {
      if (!$self->{dbh})
      {
         &carp("No database connection has been specified.  Please use ".$pkg."::setDBH()");
         return undef;
      }
      if (ref($self->{dbh}) !~ /^(DBI|DBD)\b/)
      {
         &carp("The DBH object is not a valid DBI/DBD connection: " . ref($self->{dbh}));
         return undef;
      }
   }

   return $self;
}
#--------------------------

=item setDBH DBI_HANDLE

Set the global database handle for this package.  Use like this:

  CAM::Template::Cache->setDBH($dbh);

=cut

sub setDBH
{
   my $pkg = shift; # unused
   my $val = shift;
   $global_dbh = $val;
}
#--------------------------

=item setExpiration SECONDS

Set the duration for the cached content.  If the cache is older than
the specified time, the isFresh() method will return false.

Use like this:

  CAM::Template::Cache->setExpiration($seconds);

or like this:

  $template->setExpiration($seconds);

=cut

sub setExpiration
{
   my $self = shift;
   my $val = shift;

   if (ref $self)
   {
      $self->{expiration} = $val;
   }
   else
   {
      $global_expiration = $val;
   }
}
#--------------------------

=item setTableName NAME

Set the name of the database table that is used for the cache.

Use like this:

  CAM::Template::Cache->setTableName($name);

or like this:

  $template->setTableName($name);

=cut

sub setTableName
{
   my $self = shift;
   my $val = shift;

   if (ref $self)
   {
      $self->{dbTablename} = $val;
   }
   else
   {
      $global_dbTablename = $val;
   }
}
#--------------------------

=item setUseLock 0|1

Set the global preference for whether to lock the database table when
doing a save (since save() does both a delete and an insert).  Turning
off lock may lead to a (rare!) race condition where two inserts
happen, leading to a duplicate record.  Turning on locking may lead to
performance bottlenecks.  The default is off.

=cut

sub setUseLock
{
   my $pkg = shift; # unused
   my $val = shift;
   $global_uselock = $val;
}
#--------------------------

=item isFresh

Returns a boolean indicating whether the cache is present and
whether it is up to date.

=cut

sub isFresh
{
   my $self = shift;

   return undef if (!defined $self->{cachekey});

   my $dbh = $self->{dbh};
   my $sth = $dbh->prepare("select *," .
                           "date_add(now(), interval -$$self{expiration} second) as expires " .
                           "from $$self{dbTablename} " .
                           "where $colname_key=? " .
                           "limit 1");
   $sth->execute($self->{cachekey});
   my $row = $sth->fetchrow_hashref();
   $sth->finish();

   return undef if (!$row);

   $row->{$colname_time} =~ s/\D//g;
   $row->{expires} =~ s/\D//g;

   if ($row->{$colname_time} lt $row->{expires})
   {
      $dbh->do("delete from $$self{dbTablename} " .
               "where $colname_key=" . $dbh->quote($self->{cachekey}));
      return undef;
   }

   $self->{lastrow} = $row;
   return $self;
}
#--------------------------

=item clear

=item clear CACHEKEY

Invalidates the existing cached data for this key.  This can be called
as a class method, in which case the cache key argument is required.
As an instance method, the instance's key is used if a key is not
passed as an argument.

=cut

sub clear
{
   my $pkg_or_self = shift;
   my $key = shift;
   
   my $dbh = $global_dbh;
   my $dbtable = $global_dbTablename;
   if (ref($pkg_or_self))
   {
      my $self = $pkg_or_self;
      $key ||= $self->{cachekey};
      $dbh = $self->{dbh};
      $dbtable = $self->{dbTablename};
   }
   return undef unless ($key && $dbh);
   $dbh->do("update $dbtable set $colname_time='0000-00-00'" .
            "where $colname_key=" . $dbh->quote($key));
   return $pkg_or_self;
}
#--------------------------

=item toStringCache

Returns the cached content, or undef on failure.  If isFresh() has
already been called, information is recycled from that inquiry.

=cut

sub toStringCache
{
   my $self = shift;

   if (!$self->{lastrow})
   {
      if (!$self->isFresh())
      {
         return undef;
      }
   }
   return $self->{lastrow}->{$colname_data};
}
#--------------------------

=item printCache

Prints the cached content.  Returns a boolean indicating success or
failure.  If isFresh() has already been called, information is
recycled from that inquiry.

=cut

sub printCache
{
   my $self = shift;

   my $content = $self->toStringCache();
   if (!defined $content)
   {
      return undef;
   }
   else
   {
      print $content;
      return $self;
   }
}
#--------------------------

=item save CONTENT

Record the content in the database.  This is typically only called
from within toString(), but is provided here for the benefit of
subclasses.

=cut

sub save
{
   my $self = shift;
   my $string = shift;

   return undef if (!defined $self->{cachekey});

   my $dbh = $self->{dbh};

   $dbh->do("lock table $$self{dbTablename} write") if ($global_uselock);
   $dbh->do("delete from $$self{dbTablename} " .
            "where $colname_key=" . $dbh->quote($self->{cachekey}));
   my $result = $dbh->do("insert into $$self{dbTablename} set " .
                         "$colname_key=".$dbh->quote($self->{cachekey})."," .
                         "$colname_time=now()," .
                         "$colname_data=" . $dbh->quote($string));
   $dbh->do("unlock table") if ($global_uselock);
   if (!$result)
   {
      &carp("Failed to cache the template string");
      return undef;
   }
   return $self;
}
#--------------------------

=item toString

Same as CAM::Template->toString except that the result is stored in
the database.

=cut

sub toString
{
   my $self = shift;

   my $string = $self->SUPER::toString(@_);
   $self->save($string);
   return $string;
}
#--------------------------

=item print

Same as CAM::Template->print except that the result is stored in
the database.

=cut

sub print
{
   my $self = shift;

   # no work to do.  It's all done in toString.
   return $self->SUPER::print(@_);
}
#--------------------------

=item setup

=item setup DBIHANDLE, TABLENAME

Create a database table for storing cached templates.  This is not
intended to be called often, if ever.  This is a class method.  It
should be used in a separate script like this:

    use DBI;
    use CAM::Template::Cache;
    my $dbh = DBI->connect(...);
    CAM::Template::Cache->setup($dbh, "TemplateCache");

=cut

sub setup
{
   if (!ref($_[0]))
   {
      shift;  # skip package name, if applicable
   }
   my $dbh = shift || $global_dbh;
   my $tablename = shift || $global_dbTablename;

   my $result = $dbh->do("create table if not exists $tablename (" .
                         "$colname_key text not null," .
                         "$colname_time timestamp," .
                         "$colname_data mediumtext," .
                         "KEY $colname_key ($colname_key(255))" .
                         ")");
   return $result;
}
#--------------------------

=item clean

=item clean DBIHANDLE, TABLENAME, SECONDS

Cleans out all records older than the specified number of seconds.
This is a class method.  It should be used in a separate script like
this, likely running as a cron:

    use DBI;
    use CAM::Template::Cache;
    my $dbh = DBI->connect(...);
    CAM::Template::Cache->clean($dbh, "TemplateCache", 2*60*60);

=cut

sub clean
{
   if (!ref($_[0]))
   {
      shift;  # skip package name, if applicable
   }
   my $dbh = shift || $global_dbh;
   my $tablename = shift || $global_dbTablename;
   my $seconds = shift || $global_expiration;

   return 1 if (!$seconds); # no time means no expiration

   return $dbh->do("delete from $tablename " .
                   "where $colname_time < " .
                   "date_add(now(),interval -$seconds second)");
}
#--------------------------

1;
__END__

=back

=head1 AUTHOR

Clotho Advanced Media Inc., I<cpan@clotho.com>

Primary developer: Chris Dolan
