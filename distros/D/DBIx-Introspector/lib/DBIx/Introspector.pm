package DBIx::Introspector;
$DBIx::Introspector::VERSION = '0.001005';
# ABSTRACT: Detect what database you are connected to

use Moo;
use DBIx::Introspector::Driver;

has _drivers => (
   is => 'ro',
   required => 1,
   init_arg => 'drivers',
   coerce => sub {
      return $_[0] if ref $_[0] eq 'ARRAY';
      return [ map DBIx::Introspector::Driver->new($_),
         {
            name => 'DBI',
            connected_determination_strategy => sub { $_[1]->{Driver}{Name} },
            unconnected_determination_strategy => sub {
               my $dsn = $_[1] || $ENV{DBI_DSN} || '';
               my ($driver) = $dsn =~ /dbi:([^:]+):/i;
               $driver ||= $ENV{DBI_DRIVER};
               return $driver
            },
         },
         { name => 'ACCESS',      parents => ['DBI'] },
         { name => 'DB2',         parents => ['DBI'] },
         { name => 'Informix',    parents => ['DBI'] },
         { name => 'InterBase',   parents => ['DBI'] },
         { name => 'MSSQL',       parents => ['DBI'] },
         { name => 'Oracle',      parents => ['DBI'] },
         { name => 'Pg',          parents => ['DBI'] },
         { name => 'SQLAnywhere', parents => ['DBI'] },
         { name => 'SQLite',      parents => ['DBI'] },
         { name => 'Sybase',      parents => ['DBI'] },
         { name => 'mysql',       parents => ['DBI'] },
         { name => 'Firebird::Common',    parents => ['Interbase'] },
         { name => 'Firebird',    parents => ['Interbase'] },
         {
            name => 'ODBC',
            connected_determination_strategy => sub {
               my $v = $_[0]->_get_info_from_dbh($_[1], 'SQL_DBMS_NAME');
               $v =~ s/\W/_/g;
               "ODBC_$v"
            },
            parents => ['DBI'],
         },
         { name => 'ODBC_ACCESS',               parents => ['ACCESS', 'ODBC'] },
         { name => 'ODBC_DB2_400_SQL',          parents => ['DB2', 'ODBC'] },
         { name => 'ODBC_Firebird',             parents => ['Firebird::Common', 'ODBC'] },
         { name => 'ODBC_Microsoft_SQL_Server', parents => ['MSSQL', 'ODBC'] },
         { name => 'ODBC_SQL_Anywhere',         parents => ['SQLAnywhere', 'ODBC'] },
         {
            name => 'ADO',
            connected_determination_strategy => sub {
               my $v = $_[0]->_get_info_from_dbh($_[1], 'SQL_DBMS_NAME');
               $v =~ s/\W/_/g;
               "ADO_$v"
            },
            parents => ['DBI'],
         },
         { name => 'ADO_MS_Jet',               parents => ['ACCESS', 'ADO'] },
         { name => 'ADO_Microsoft_SQL_Server', parents => ['MSSQL', 'ADO'] },
      ] if $_[0] eq '2013-12.01'
   },
);

sub _root_driver { shift->_drivers->[0] }

has _drivers_by_name => (
   is => 'ro',
   builder => sub { +{ map { $_->name => $_ } @{$_[0]->_drivers} } },
   clearer => '_clear_drivers_by_name',
   lazy => 1,
);

sub add_driver {
   my ($self, $driver) = @_;

   $self->_clear_drivers_by_name;
   # check for dupes?
   push @{$self->_drivers}, DBIx::Introspector::Driver->new($driver)
}

sub replace_driver {
   my ($self, $driver) = @_;

   $self->_clear_drivers_by_name;
   @{$self->_drivers} = (
      (grep $_ ne $driver->{name}, @{$self->_drivers}),
      DBIx::Introspector::Driver->new($driver)
   );
}

sub decorate_driver_unconnected {
   my ($self, $name, $key, $value) = @_;

   if (my $d = $self->_drivers_by_name->{$name}) {
      $d->_add_unconnected_option($key => $value)
   } else {
      die "no such driver <$name>"
   }
}

sub decorate_driver_connected {
   my ($self, $name, $key, $value) = @_;

   if (my $d = $self->_drivers_by_name->{$name}) {
      $d->_add_connected_option($key => $value)
   } else {
      die "no such driver <$name>"
   }
}

sub get {
   my ($self, $dbh, $dsn, $key, $opt) = @_;
   $opt ||= {};

   my @args = (
      drivers_by_name => $self->_drivers_by_name,
      key => $key
   );

   if ($dbh and my $driver = $self->_driver_for((ref $dbh eq 'CODE' ? $dbh->() : $dbh), $dsn)) {
      my $ret = $driver
         ->_get_when_connected({
            dbh => $dbh,
            dsn => $dsn,
            @args,
         });
      return $ret if defined $ret;
      $ret = $driver
         ->_get_when_unconnected({
            dsn => $dsn,
            @args,
         });
      return $ret if defined $ret;
   }

   my $dsn_ret = $self->_driver_for($dbh, $dsn)
      ->_get_when_unconnected({
         dsn => $dsn,
         @args,
      }) if $dsn;
   return $dsn_ret if defined $dsn_ret;

   if (ref $dbh eq 'CODE' && ref $opt->{dbh_fallback_connect} eq 'CODE') {
      $opt->{dbh_fallback_connect}->();
      my $dbh = $dbh->();
      return $self->_driver_for($dbh, $dsn)
         ->_get_when_connected({
            dbh => $dbh,
            dsn => $dsn,
            @args,
         })
   }

   die "missing key: $key"
}

sub _driver_for {
   my ($self, $dbh, $dsn) = @_;

   if ($dbh and my $d = $dbh->{private_dbii_driver}) {
      if (my $found = $self->_drivers_by_name->{$d}) {
         return $found
      } else {
         warn "user requested non-existant driver $d"
      }
   }

   my $driver = $self->_root_driver;
   my $done;

   DETECT:
   do {
      $done = $driver->_determine($dbh, $dsn);
      if (!defined $done) {
         die "cannot figure out wtf this is"
      } elsif ($done ne 1) {
         $driver = $self->_drivers_by_name->{$done}
            or die "no such driver <$done>"
      }
   } while $done ne 1;

   return $driver
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::Introspector - Detect what database you are connected to

=head1 VERSION

version 0.001005

=head1 SYNOPSIS

 my $d = DBIx::Introspector->new(drivers => '2013-12.01');

 # standard dialects
 $d->decorate_driver_unconnected(Pg     => concat_sql => '? || ?');
 $d->decorate_driver_unconnected(SQLite => concat_sql => '? || ?');

 # non-standard
 $d->decorate_driver_unconnected(MSSQL  => concat_sql => '? + ?');
 $d->decorate_driver_unconnected(mysql  => concat_sql => 'CONCAT( ?, ? )');

 my $concat_sql = $d->get($dbh, $dsn, 'concat_sql');

=head1 DESCRIPTION

C<DBIx::Introspector> is a module factored out of the L<DBIx::Class> database
detection code.  Most code that needs to detect which database it is connected
to assumes that there is a one-to-one mapping from database drivers to database
engines.  Unfortunately reality is rarely that simple.  For instance,
L<DBD::ODBC> is typically used to connect to SQL Server, but ODBC can be used to
connect to PostgreSQL, MySQL, and Oracle.  Additionally, while ODBC is the most
common way to connect to SQL Server, it is not the only option, as L<DBD::ADO>
can also be used.

C<DBIx::Introspector> can correctly detect which database you are connected to,
because it was factored out of a complex, working codebase.  On top of
that it has been written to be very extensible.  So if you needed to
detect which version of your given database you are connected to that
would not be difficult.

Furthermore, C<DBIx::Introspector> does its best to try to detect information
based on the dsn you give it if you have not yet connected, so you can possibly
avoid connection or at least defer connection.

=head1 METHODS

=head2 C<add_driver>

 $dbii->add_driver({
   name => 'Pg',
   parents => ['DBI'],
   unconnected_options => {
      concat_sql => '? || ?',
      random_func => 'RANDOM()',
   })

Takes a hashref L<< defining a new driver | DRIVER DEFINITION >>.

=head2 C<replace_driver>

 $dbii->replace_driver({
   name => 'Pg',
   parents => ['DBI'],
   unconnected_options => {
      concat_sql => '? || ?',
      random_func => 'RANDOM()',
   })

Takes a hashref L<< replacing an existing driver | DRIVER DEFINITION >>.
Replaces the driver already defined with the same name.

=head2 C<decorate_driver_connected>

 $dbii->decorate_driver_connected('MSSQL', 'concat_sql', '? + ?')

Takes a C<driver name>, C<key> and a C<value>.  The C<key value> pair will
be inserted into the driver's C<connected_options>.

=head2 C<decorate_driver_unconnected>

 $dbii->decorate_driver_unconnected('SQLite', 'concat_sql', '? || ?')

Takes a C<driver name>, C<key> and a C<value>.  The C<key value> pair will
be inserted into the driver's C<unconnected_options>.

=head2 C<get>

 $dbii->get($dbh, $dsn, 'concat_sql')

Takes a C<dbh>, C<dsn>, C<key>, and optionally a hashref of C<options>.

The C<dbh> can be a coderef returning a C<dbh>.  If you provide the
C<dbh_fallback_connect> option it will be used to connect the C<dbh> if it is
not already connected and then queried, if the C<dsn> was insufficient.

So for example, one might do:

 my $dbh;
 $dbii->get(sub { $dbh }, $dsn, 'concat_sql', {
    dbh_fallback_connect => sub { $dbh = DBI->connect($dsn, $user, $pass) },
 });

Which will only connect if it has to, like if the user is using the C<DBD::ODBC>
driver to connect.

=head1 ATTRIBUTES

=head2 C<drivers>

This has no default and is required, though a sane defaultish value does exist.

Currently there is one predefined set of drivers, named C<2013-12.01>.
If drivers or facts or just the general structure of drivers changes they
will always be as a new named set of drivers.  C<2013-12.01> matches
the 0.08250 release of L<DBIx::Class> and probably many previous and
following releases.

If you need to define it from scratch, you can just pass an arrayref of drivers;
see the L<DRIVER DEFINITION> section on what is required for that.  But
generally it will look something like this (from the tests):

 my $d = DBIx::Introspector->new(
   drivers => [ map DBIx::Introspector::Driver->new($_),
      {
         name => 'DBI',
         connected_determination_strategy => sub { $_[1]->{Driver}{Name} },
         unconnected_determination_strategy => sub {
            my $dsn = $_[1] || $ENV{DBI_DSN} || '';
            my ($driver) = $dsn =~ /dbi:([^:]+):/i;
            $driver ||= $ENV{DBI_DRIVER};
            return $driver
         },
      },
      {
         name => 'SQLite',
         parents => ['DBI'],
         connected_determination_strategy => sub {
            my ($v) = $_[1]->selectrow_array('SELECT "value" FROM "a"');
            return "SQLite$v"
         },
         connected_options => {
            bar => sub { 2 },
         },
         unconnected_options => {
            borg => sub { 'magic ham' },
         },
      },
      { name => 'SQLite1', parents => ['SQLite'] },
      { name => 'SQLite2', parents => ['SQLite'] },
   ]
 );

=head1 DRIVER DEFINITION

Drivers (C<DBIx::Introspector::Driver> objects) have the following six
attributes:

=head2 C<name>

Required.  Must be unique among the drivers contained in the introspector.

=head2 C<parents>

Arrayref of parent drivers.  This allows parent drivers to implement common
options among children.  So for example on might define a driver for each
version of PostgreSQL, and have a parent driver that they all use for common
base info.

=head2 C<connected_determination_strategy>

This is a code reference that is called as a method on the driver with the
C<dbh> as the first argument and an optional C<dsn> as the second argument.
It should return a driver name.

=head2 C<unconnected_determination_strategy>

This is a code reference that is called as a method on the driver with the
C<dsn> as the first argument.  It should return a driver name.

=head2 C<connected_options>

Hashref of C<< key value >> pairs for detecting information based on the
C<dbh>.  A value that is not a code reference is returned directly, though
I suggest non-coderefs all go in the L</unconnected_options> so that they may be
used without connecting if possilbe.

If a code reference is passed it will get called as a method on the driver
with the following list of values:

=over 2

=item C<dbh>

This is the connected C<dbh> that you can use to introspect the database.

=item C<dsn>

This is the C<dsn> passed to L</get>, possibly undefined.

=back

=head2 C<unconnected_options>

Hashref of C<< key value >> pairs for detecting information based on the
C<dsn>.  A value that is not a code reference is returned directly.

If a code reference is passed it will get called as a method on the driver
with the following list value:

=over 2

=item C<dsn>

This is the connected C<dsn> that you can use to introspect the database.

=back

=head1 AUTHOR

Arthur Axel "fREW" Schmidt <frioux+cpan@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Arthur Axel "fREW" Schmidt.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
