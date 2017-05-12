package DBIx::DataSource::Driver;

use strict;
use vars qw($VERSION);
use DBI;

$VERSION = '0.01';

=head1 NAME

DBIx::DataSource::Driver - Driver Writer's Guide and base class

=head1 SYNOPSIS

  perldoc DBIx::DataSource::Driver;

  or

  package DBIx::DataSource::FooBase;
  use DBIx::DataSource::Driver;
  @ISA = qw( DBIx::DataSource::Driver );

=head1 DESCRIPTION

To implement a driver for your database:

1) If you can create a database with an SQL command through DBI/DBD, simply
   provide a parse_dsn class method which returns a list consisting of the
   *actual* data source to use in DBI->connect and the SQL.

       package DBIx::DataSource::NewDatabase;
       use DBIx::DataSource::Driver;
       @ISA = qw( DBIx::DataSource::Driver );

       sub parse_dsn {
         my( $class, $action, $dsn ) = @_;

         # $action is `create' or `drop'
         # for example, if you parse parse $dsn for $database,
         # $sql = "$action $database";

         # you can die on errors - it'll be caught

         ( $new_dsn, $sql );
       }

2) Otherwise, you'll need to write B<create_database> and B<drop_database>
   class methods.

       package DBIx::DataSource::NewDatabase;

       sub create_database {
         my( $class, $dsn, $user, $pass ) = @_;

         # for success, return true
         # for failure, die (it'll be caught)
       }

       sub drop_database {
         my( $class, $dsn, $user, $pass ) = @_;

         # for success, return true
         # for failure, die (it'll be caught)
       }

=cut

sub create_database { shift->_sql('create', @_) };
sub drop_database   { shift->_sql('drop',   @_) };

sub _sql {
  my( $class, $action, $dsn, $user, $pass ) = @_;
  my( $new_dsn, $sql ) = $class->parse_dsn($action, $dsn);
  my $dbh = DBI->connect( $new_dsn, $user, $pass ) or die $DBI::errstr;
#  $dbh->do($sql) or die $dbh->errstr;
# silly DBI.  implicit DESTROY yummy.
  $dbh->do($sql) or do { my $err = $dbh->errstr; $dbh->disconnect; die $err; };
  $dbh->disconnect or die $dbh->errstr;
}

=head1 AUTHOR

Ivan Kohler <ivan-dbix-datasource@420.am>

=head1 COPYRIGHT

Copyright (c) 2000 Ivan Kohler
Copyright (c) 2000 Mail Abuse Prevention System LLC
All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

=head1 SEE ALSO

L<DBIx::DataSource>, L<DBIx::DataSource::mysql>, L<DBIx::DataSource::Pg>, L<DBI>

=cut 

1;
