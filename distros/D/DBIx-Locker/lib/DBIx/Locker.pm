use strict;
use warnings;
use 5.008;

package DBIx::Locker 1.102;
# ABSTRACT: locks for db resources that might not be totally insane

use Carp ();
use DBI;
use Data::GUID ();
use DBIx::Locker::Lock;
use JSON 2 ();
use Sys::Hostname ();

#pod =head1 DESCRIPTION
#pod
#pod ...and a B<warning>.
#pod
#pod DBIx::Locker was written to replace some lousy database resource locking code.
#pod The code would establish a MySQL lock with C<GET_LOCK> to lock arbitrary
#pod resources.  Unfortunately, the code would also silently reconnect in case of
#pod database connection failure, silently losing the connection-based lock.
#pod DBIx::Locker locks by creating a persistent row in a "locks" table.
#pod
#pod Because DBIx::Locker locks are stored in a table, they won't go away.  They
#pod have to be purged regularly.  (A program for doing this, F<dbix_locker_purge>,
#pod is included.)  The locked resource is just a string.  All records in the lock
#pod (or semaphore) table are unique on the lock string.
#pod
#pod This is the I<entire> mechanism.  This is quick and dirty and quite effective,
#pod but it's not highly efficient.  If you need high speed locks with multiple
#pod levels of resolution, or anything other than a quick and brutal solution,
#pod I<keep looking>.
#pod
#pod =head1 STORAGE
#pod
#pod To use this module you'll need to create the lock table, which should have five
#pod columns:
#pod
#pod =over
#pod
#pod =item * C<id> Autoincrementing ID is recommended
#pod
#pod =item * C<lockstring> varchar(128) with a unique constraint
#pod
#pod =item * C<created> datetime
#pod
#pod =item * C<expires> datetime
#pod
#pod =item * C<locked_by> text
#pod
#pod =back
#pod
#pod See the C<sql> directory included in this dist for DDL for your database.
#pod
#pod =method new
#pod
#pod   my $locker = DBIx::Locker->new(\%arg);
#pod
#pod This returns a new locker.
#pod
#pod Valid arguments are:
#pod
#pod   dbh      - a database handle to use for locking
#pod   dbi_args - an arrayref of args to pass to DBI->connect to reconnect to db
#pod   table    - the table for locks
#pod
#pod =cut

sub new {
  my ($class, $arg) = @_;

  my $guts = {
    dbh      => $arg->{dbh},
    dbi_args => ($arg->{dbi_args} || $class->default_dbi_args),
    table    => ($arg->{table}    || $class->default_table),
  };

  Carp::confess("cannot use a dbh without RaiseError")
    if $guts->{dbh} and not $guts->{dbh}{RaiseError};

  my $dbi_attr = $guts->{dbi_args}[3] ||= {};

  Carp::confess("RaiseError cannot be disabled")
    if exists $dbi_attr->{RaiseError} and not $dbi_attr->{RaiseError};

  $dbi_attr->{RaiseError} = 1;

  return bless $guts => $class;
}

#pod =method default_dbi_args
#pod
#pod =method default_table
#pod
#pod These methods may be defined in subclasses to provide defaults to be used when
#pod constructing a new locker.
#pod
#pod =cut

sub default_dbi_args {
  Carp::confess('dbi_args not given and no default defined')
}

sub default_table    {
  Carp::Confess('table not given and no default defined')
}

#pod =method dbh
#pod
#pod This method returns the locker's dbh.
#pod
#pod =cut

sub dbh {
  my ($self) = @_;
  return $self->{dbh} if $self->{dbh} and eval { $self->{dbh}->ping };

  die("couldn't connect to database: $DBI::errstr")
    unless my $dbh = DBI->connect(@{ $self->{dbi_args} });

  return $self->{dbh} = $dbh;
}

#pod =method table
#pod
#pod This method returns the name of the table in the database in which locks are
#pod stored.
#pod
#pod =cut

sub table {
  return $_[0]->{table}
}

#pod =method lock
#pod
#pod   my $lock = $locker->lock($lockstring, \%arg);
#pod
#pod This method attempts to return a new DBIx::Locker::Lock.
#pod
#pod =cut

my $JSON;
BEGIN { $JSON = JSON->new->canonical(1)->space_after(1); }

sub lock {
  my ($self, $lockstring, $arg) = @_;
  $arg ||= {};

  Carp::confess("calling ->lock in void context is not permitted")
    unless defined wantarray;

  Carp::confess("no lockstring provided")
    unless defined $lockstring and length $lockstring;

  my $expires = $arg->{expires} ||= 3600;

  Carp::confess("expires must be a positive integer")
    unless $expires > 0 and $expires == int $expires;

  $expires = time + $expires;

  my $locked_by = {
    host => Sys::Hostname::hostname(),
    guid => Data::GUID->new->as_string,
    pid  => $$,
  };

  my $table = $self->table;
  my $dbh   = $self->dbh;

  local $dbh->{RaiseError} = 0;
  local $dbh->{PrintError} = 0;

  my $rows  = $dbh->do(
    "INSERT INTO $table (lockstring, created, expires, locked_by)
    VALUES (?, ?, ?, ?)",
    undef,
    $lockstring,
    $self->_time_to_string,
    $self->_time_to_string([ localtime($expires) ]),
    $JSON->encode($locked_by),
  );

  die(
    "could not lock resource <$lockstring>" . (
      $dbh->err && $dbh->errstr
        ? (': ' .  $dbh->errstr)
        : ''
    )
  ) unless $rows and $rows == 1;

  my $lock = DBIx::Locker::Lock->new({
    locker    => $self,
    lock_id   => $self->last_insert_id,
    expires   => $expires,
    locked_by => $locked_by,
    lockstring => $lockstring,
  });

  return $lock;
}

sub _time_to_string {
  my ($self, $time) = @_;

  $time = [ localtime ] unless $time;
  return sprintf '%04u-%02u-%02u %02u:%02u:%02u',
    $time->[5] + 1900, $time->[4]+1, $time->[3],
    $time->[2], $time->[1], $time->[0];
}

#pod =method purge_expired_locks
#pod
#pod This method deletes expired semaphores.
#pod
#pod =cut

sub purge_expired_locks {
  my ($self) = @_;

  my $dbh = $self->dbh;
  local $dbh->{RaiseError} = 0;
  local $dbh->{PrintError} = 0;

  my $table = $self->table;

  my $rows = $dbh->do(
    "DELETE FROM $table WHERE expires < ?",
    undef,
    $self->_time_to_string,
  );
}

#pod =method last_insert_id
#pod
#pod This method exists so that subclasses can do something else to support their
#pod DBD for getting the id of the created lock.  For example, with DBD::ODBC and
#pod SQL Server it should be:
#pod
#pod  sub last_insert_id { ($_[0]->dbh->selectrow_array('SELECT @@IDENTITY'))[0] }
#pod
#pod =cut

sub last_insert_id {
   $_[0]->dbh->last_insert_id(undef, undef, $_[0]->table, 'id')
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Locker - locks for db resources that might not be totally insane

=head1 VERSION

version 1.102

=head1 DESCRIPTION

...and a B<warning>.

DBIx::Locker was written to replace some lousy database resource locking code.
The code would establish a MySQL lock with C<GET_LOCK> to lock arbitrary
resources.  Unfortunately, the code would also silently reconnect in case of
database connection failure, silently losing the connection-based lock.
DBIx::Locker locks by creating a persistent row in a "locks" table.

Because DBIx::Locker locks are stored in a table, they won't go away.  They
have to be purged regularly.  (A program for doing this, F<dbix_locker_purge>,
is included.)  The locked resource is just a string.  All records in the lock
(or semaphore) table are unique on the lock string.

This is the I<entire> mechanism.  This is quick and dirty and quite effective,
but it's not highly efficient.  If you need high speed locks with multiple
levels of resolution, or anything other than a quick and brutal solution,
I<keep looking>.

=head1 PERL VERSION

This library should run on perls released even a long time ago.  It should work
on any version of perl released in the last five years.

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to lower
the minimum required perl.

=head1 METHODS

=head2 new

  my $locker = DBIx::Locker->new(\%arg);

This returns a new locker.

Valid arguments are:

  dbh      - a database handle to use for locking
  dbi_args - an arrayref of args to pass to DBI->connect to reconnect to db
  table    - the table for locks

=head2 default_dbi_args

=head2 default_table

These methods may be defined in subclasses to provide defaults to be used when
constructing a new locker.

=head2 dbh

This method returns the locker's dbh.

=head2 table

This method returns the name of the table in the database in which locks are
stored.

=head2 lock

  my $lock = $locker->lock($lockstring, \%arg);

This method attempts to return a new DBIx::Locker::Lock.

=head2 purge_expired_locks

This method deletes expired semaphores.

=head2 last_insert_id

This method exists so that subclasses can do something else to support their
DBD for getting the id of the created lock.  For example, with DBD::ODBC and
SQL Server it should be:

 sub last_insert_id { ($_[0]->dbh->selectrow_array('SELECT @@IDENTITY'))[0] }

=head1 STORAGE

To use this module you'll need to create the lock table, which should have five
columns:

=over

=item * C<id> Autoincrementing ID is recommended

=item * C<lockstring> varchar(128) with a unique constraint

=item * C<created> datetime

=item * C<expires> datetime

=item * C<locked_by> text

=back

See the C<sql> directory included in this dist for DDL for your database.

=head1 AUTHOR

Ricardo SIGNES <rjbs@semiotic.systems>

=head1 CONTRIBUTORS

=for stopwords Arthur Axel 'fREW' Schmidt Chris Nehren Hans Dieter Pearcey Matthew Horsfall Rob N ★ Sergiy Borodych

=over 4

=item *

Arthur Axel 'fREW' Schmidt <frioux@gmail.com>

=item *

Chris Nehren <apeiron@cpan.org>

=item *

Hans Dieter Pearcey <hdp@cpan.org>

=item *

Matthew Horsfall <wolfsage@gmail.com>

=item *

Rob N ★ <robn@robn.io>

=item *

Sergiy Borodych <sergiy.borodych@gmail.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
